classdef SignalCapturer < handle
    %SIGNALCAPTURER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        save_path
        do_save
        maxRange
        rangeResolution
        maxSpeed
        speedResolution
        fc
        lambda
        rampbandwidth
        fmaxdop
        prf
        frame_len
        nPulses
        tpulse
        tsweep
        sweepslope
        fmaxbeat
        fs
        nSamples
        nCaptures
        TotalRecLength

        rx
        tx
        amp

        txWaveform
        bf
        num_steps
        BW
        bf_TDD
        tStartRamp
        tStartCollection

        size_data_dim2
        size_data_dim1
        data
        time
        times_pre_tx
        times_post_tx
        times_post_burse
        times_post_rx

    end
    
    methods

        function obj = SignalCapturer(opts)
            arguments
                opts.SavePath = "rec" + filesep
                opts.DoSave = 1
                opts.MaxRange = 10
                opts.RangeResolution = 1/3
                opts.MaxSpeed = 1
                opts.SpeedResolution = 1/100
                opts.FrameLength = 1.5
                opts.TotalRecLength = 20 % total recording of pure signal (excluding breaks) [s]
            end

            warning('off','MATLAB:system:ObsoleteSystemObjectMixin')
            
            % Put some requirements on the system
            
            
            obj.save_path = opts.SavePath;
            obj.do_save = opts.DoSave;
            obj.TotalRecLength = opts.TotalRecLength;
            

            % Put some requirements on the system
            
            obj.maxRange = opts.MaxRange; % 100 m max range, use the system in a room
            obj.rangeResolution = opts.RangeResolution; % Range resolution of 1/3 m
            obj.maxSpeed = opts.MaxSpeed; % Max speed we expect is 5 m/s, somebody moving towards the radar (1 2 3 5 10)
            obj.speedResolution = opts.SpeedResolution; % Speed resolution of 1/2 m/s
            
            % Determine some parameter values based on system requirements, based on the
            % following example - https://www.mathworks.com/help/radar/ug/automotive-adaptive-cruise-control-using-fmcw-technology.html
            
            obj.fc = 10e9; % rf carrier frequency is ~10 GHz
            obj.lambda = physconst("LightSpeed") / obj.fc;
            obj.rampbandwidth = ceil(rangeres2bw(obj.rangeResolution)/1e6)*1e6; % get ramp bandwidth for required range resolution, conviniently this brings us close to the maximum for the Phaser
            obj.fmaxdop = speed2dop(2*obj.maxSpeed,obj.lambda); % Maximum doppler shift depends on max speed we want to resolve, multiply by 2 for 2 way propagation
            obj.prf = 2*obj.fmaxdop; % PRF needs to be set to unambiguously resolve max speed
            
            obj.frame_len = opts.FrameLength;
            obj.nPulses = ceil(obj.frame_len/1.5  *  2*obj.maxSpeed/obj.speedResolution); % Number of pulses set to for desired speed resolution
                        % (in about 1.5s recording)
            obj.tpulse = ceil((1/obj.prf)*1e3)*1e-3; % Pulse time, round up to the nearest ms
            obj.tsweep = getFMCWSweepTime(obj.tpulse,obj.tpulse); % Sweep across as much of the pulse as possible
            obj.sweepslope = obj.rampbandwidth / obj.tsweep; % Slope of the FMCW sweep
            obj.fmaxbeat = obj.sweepslope * range2time(obj.maxRange); % Max beat frequency in this case we only consider the f offset due to range delay. With faster targets, you need to consider doppler
            obj.fs = max(ceil(2*obj.fmaxbeat),520834); % Set sample rate based on the maximum beat frequency or the minimum rate of the pluto.
            obj.nSamples = ceil(obj.tpulse * obj.nPulses * obj.fs); % Get the total number of samples in a PRP
            

            obj.nCaptures = round(obj.TotalRecLength/(obj.frame_len)); % number of frames, in this configuration, 1 frame = 1.5s recording + 1s break
            obj.nCaptures(obj.nCaptures == 0) = 1;

            if(obj.nSamples > 2^20)
                error("Too much nPulses per frame (nSamples > 2^20)")
            end
        end
        function configure(obj)
            %configure 

            % Setup pluto
            
            % Setup the pluto
            [obj.rx,obj.tx] = setupPluto();
            
            % Setup pluto sampling
            obj.rx.SamplesPerFrame = obj.nSamples;
            obj.rx.SamplingRate = obj.fs;
            
            % Setup transmitter
            obj.tx.SamplingRate = obj.fs;
            obj.tx.EnabledChannels = [1,2];
            obj.tx.CenterFrequency = obj.rx.CenterFrequency;
            obj.tx.AttenuationChannel0 = -80;
            obj.tx.AttenuationChannel1 = -3;
            obj.tx.EnableCyclicBuffers = true;
            obj.tx.DataSource = "DMA";
            
            % This is where you could create some modulation scheme, we just use a
            % constant amplitude baseband signal.
            obj.amp = 0.9 * 2^15;
            obj.txWaveform = obj.amp*ones(obj.nSamples,2);
            
            % Setup the Phaser
            
            % Setup beamformers all to max gain with no phase shifts
            obj.bf = setupPhaser(obj.rx,obj.fc);
            obj.bf.RxPowerDown(:) = 0;
            obj.bf.RxGain(:) = 127;
            
            % Setup ADF4159
            obj.bf.Frequency = (obj.fc+obj.rx.CenterFrequency)/4;
            obj.BW = obj.rampbandwidth / 4; 
            obj.num_steps = 2^9;
            obj.bf.FrequencyDeviationRange = obj.BW;
            obj.bf.FrequencyDeviationStep = ((obj.BW) / obj.num_steps);
            obj.bf.FrequencyDeviationTime = obj.tsweep*1e6; % convert to us
            obj.bf.RampMode = "single_sawtooth_burst"; % use a single sawtooth, other waveforms are available
            obj.bf.TriggerEnable = true;  % start a ramp with TXdata
            obj.bf.EnablePLL = true;
            obj.bf.EnableTxPLL = true;
            obj.bf.EnableOut1 = false; % send transmit out of SMA2
            
            % Setup the TDD engine
            
            obj.bf_TDD = setupTddEngine();
            obj.tStartRamp = 0;
            obj.tStartCollection = 0;
            obj.bf_TDD.PhaserEnable = 1; % enable triggered mode
            obj.bf_TDD.Enable = 0;   % TDD must be disabled before changing properties
            obj.bf_TDD.EnSyncExternal = 1;
            obj.bf_TDD.StartupDelay = 0;
            obj.bf_TDD.SyncReset = 0;
            obj.bf_TDD.FrameLength = obj.tpulse*1e3;  %frame length in ms
            obj.bf_TDD.BurstCount = obj.nPulses; % Number of pulses in a CPI
            obj.bf_TDD.Ch0Enable = 1;
            obj.bf_TDD.Ch0Polarity = 0;
            obj.bf_TDD.Ch0On = obj.tStartRamp; % Time to start PLL sweep in a frame
            obj.bf_TDD.Ch0Off = obj.tStartRamp+0.1;
            obj.bf_TDD.Ch1Enable = 1;
            obj.bf_TDD.Ch1Polarity = 0;
            obj.bf_TDD.Ch1On = obj.tStartCollection; % Time to start data collection in a frame
            obj.bf_TDD.Ch1Off = obj.tStartCollection+0.1;
            obj.bf_TDD.Ch2Enable = 1;
            obj.bf_TDD.Ch2Polarity = 0;
            obj.bf_TDD.Ch2On = 0;
            obj.bf_TDD.Ch2Off = 0.1;
            obj.bf_TDD.Enable = 1;
            
            obj.rx(); % buffer clean

        end
        
        function record(obj)
            %record signal


            obj.size_data_dim2 = obj.nPulses;
            obj.size_data_dim1 = ceil(obj.fs*obj.tsweep);
            
            % alokacja
            obj.data = zeros(obj.size_data_dim1, obj.size_data_dim2*obj.nCaptures);
            obj.time = zeros(1, obj.nCaptures);
            tic
            obj.times_pre_tx = zeros(1, obj.nCaptures);
            obj.times_post_tx = zeros(1, obj.nCaptures);
            obj.times_post_burse = zeros(1, obj.nCaptures);
            obj.times_post_rx = zeros(1, obj.nCaptures);
            for i = 1:obj.nCaptures
                idx_start = obj.size_data_dim2*(i-1)+1;
                idx_end = idx_start +obj.size_data_dim2-1;
                % capture data
                [raw_data, times_struct] = captureTransmitWf_timeStamps(obj.rx,obj.tx,obj.bf,obj.txWaveform);
            
                % time signatures
                obj.time(i) = toc;
                obj.times_pre_tx(i) = times_struct.time_pre_tx;
                obj.times_post_tx(i) = times_struct.time_post_tx;
                obj.times_post_burse(i) = times_struct.time_post_burse;
                obj.times_post_rx(i) = times_struct.time_post_rx;
            
                % % Remove excess data, rearrange into nSamples x nPulses
                obj.data(:,idx_start:idx_end) = arrangePulseData_fix(raw_data,obj.rx,obj.bf,obj.bf_TDD);

                % if(obj.do_save)
                %     file_suffix = string(datetime("now"));
                %     file_suffix = strrep(file_suffix, ":", "-");
                %     file_suffix = strrep(file_suffix, " ", "_");
                %     data = obj.data;
                %     fc = obj.fc;
                %     fs = obj.fc;
                %     prf = obj.prf;
                %     tpulse = obj.tpulse;
                %     rampbandwidth = obj.rampbandwidth;
                %     rx = obj.rx;
                %     bf = obj.bf;
                %     bf_TDD = obj.bf_TDD;
                %     sweepslope = obj.sweepslope;
                %     maxSpeed = obj.maxSpeed;
                %     maxRange = obj.maxRange;
                %     times_pre_tx = obj.times_pre_tx;
                %     times_post_tx = obj.times_post_tx;
                %     times_post_burse = obj.times_post_burse;
                %     times_post_rx = obj.times_post_rx;
                %         save(obj.save_path + "phaser_rec_App_"+  file_suffix + ".mat", "data","fc", "fs", "prf","tpulse","rampbandwidth", "rx", "bf", "bf_TDD","sweepslope","maxSpeed","maxRange",...
                %             "times_pre_tx", "times_post_tx", "times_post_burse", "times_post_rx")
                % end
            end


        end
    end
end

