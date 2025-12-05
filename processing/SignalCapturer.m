classdef SignalCapturer < handle
    %SIGNALCAPTURER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        save_path
        SeparateChannels
        save_raw
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

        % rx
        tx
        amp

        txWaveform
        % bf
        num_steps
        BW
        bf_TDD % what is this ????
        tStartRamp
        tStartCollection

        size_data_dim2
        size_data_dim1
        raw_data_len
        raw_data
        data
        data1
        data2
        time
        times_pre_tx
        times_post_tx
        times_post_burse
        times_post_rx
        % calweights % removed to avoid errors
        calibrationweights % all callibration weights
        analogweights % analog weights with applied callibration, and possibly beam steering, and tapering
        digitalweights % digital weights with applied callibration, and possibly beam steering

        fc_hb100
        ai % antenna interactor
        file_suffix
        % elementLocation % constant positions of elements - not necessary

        SteerAngle
        Tapering
        SidelobeLevel
        nConstSidelobes

    end
    
    methods

        function obj = SignalCapturer(opts)
            arguments
                opts.SavePath = "rec" + filesep
                opts.MaxRange = 10
                opts.RangeResolution = 1/3 % min. 1/3
                opts.MaxSpeed = 1 % 1 m/s determinates PRF of 133.4256 Hz
                opts.SpeedResolution = 1/100
                opts.FrameLength = 1.5 % max 1.87 s
                opts.TotalRecLength = 20 % total recording (including breaks) [s]
                opts.SeparateChannels = 0 % 1 If we want to also save both channels as separate signals
                opts.SaveRaw = 0 % 1 If we want to save raw data without reshape
            end

            warning('off','MATLAB:system:ObsoleteSystemObjectMixin')
            
            % load callibration data
            calibrationweights = loadCalibrationWeights();
            load('HB100_Fc.mat','fc_hb100'); % probably not necessary
            obj.calibrationweights = calibrationweights;
            obj.fc_hb100 = fc_hb100;

            % Put some requirements on the system


            
            obj.save_path = opts.SavePath;
            obj.SeparateChannels = opts.SeparateChannels;
            obj.TotalRecLength = opts.TotalRecLength;
            obj.save_raw = opts.SaveRaw;
            

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
            %%%% ???
            % obj.nPulses = ceil(obj.frame_len/1.5  *  2*obj.maxSpeed/obj.speedResolution); % Number of pulses set to for desired speed resolution
            %             % (in about 1.5s recording)
            obj.nPulses = floor(obj.frame_len*obj.prf); % skip speed resolution
            obj.tpulse = ceil((1/obj.prf)*1e3)*1e-3; % Pulse time, round up to the nearest ms
            obj.tsweep = getFMCWSweepTime(obj.tpulse,obj.tpulse); % Sweep across as much of the pulse as possible
            obj.sweepslope = obj.rampbandwidth / obj.tsweep; % Slope of the FMCW sweep
            obj.fmaxbeat = obj.sweepslope * range2time(obj.maxRange); % Max beat frequency in this case we only consider the f offset due to range delay. With faster targets, you need to consider doppler
            obj.fs = max(ceil(2*obj.fmaxbeat),520834); % Set sample rate based on the maximum beat frequency or the minimum rate of the pluto.
            obj.nSamples = ceil(obj.tpulse * obj.nPulses * obj.fs); % Get the total number of samples in a PRP
            
            break_length = 0.6171 * obj.frame_len +  0.1027;
            obj.nCaptures = round(obj.TotalRecLength/(obj.frame_len+break_length))+1; % number of frames, in this configuration, 1 frame = 1.5s recording + 1s break
            obj.nCaptures(obj.nCaptures == 0) = 1;

            obj.data = []; % connected channels
            obj.data1 = []; % channel1
            obj.data2 = []; % channel2
            obj.raw_data = []; % raw parts

            if(obj.nSamples > 2^20)
                error("Too much nPulses per frame (nSamples > 2^20)")
            end

            %%% this is done in AntennaInteractor in a different way
            % lambda = freq2wavelen(10.7e9);
            % spacing = lambda/2;
            % array = phased.ULA(NumElements=8,ElementSpacing=spacing);
            % obj.elementLocation = array.getElementPosition();

            % set default values of weights
            obj.analogweights = obj.calibrationweights.AnalogWeights;
            obj.digitalweights = obj.calibrationweights.DigitalWeights;

            obj.SteerAngle = [];
            obj.Tapering = [];
            obj.SidelobeLevel = [];
            obj.nConstSidelobes = [];

        end

        function steerBeam(obj,SteerAngle, opts)

            arguments
                obj 
                SteerAngle = 0 % steer beam to the desired angle -90...90, [] -> disabled
                opts.Tapering = 1 % 1 - enable patterin tapering, 0 disable pattern tapering - when opts.SteerAngle = [] -> disabled
                opts.SidelobeLevel = -30 % for tapering: sidelobe level using Taylor window
                opts.nConstSidelobes = 2 % for tapering:  number of nearly constant-level sidelobes adjacent to the mainlobe
            end

            obj.SteerAngle = SteerAngle;
            obj.Tapering = opts.Tapering;
            obj.SidelobeLevel = opts.SidelobeLevel;
            obj.nConstSidelobes = opts.nConstSidelobes;

            if(~isempty(obj.SteerAngle)) % Antenna_Pattern_Lab.mlx
                % Get the steering vector that directs the beam in the desired
                % direction

                if(opts.Tapering) % Pattern_Tapering_Lab.mlx
                    % First we generate the Taylor window for the desired number of sidelobes at the desired sidelobe level.
                    nElements = 8;
                    normalizeResults = 1;
                    taper = taylorwin(nElements,opts.nConstSidelobes,opts.SidelobeLevel);
                    % Next we normalize the taper amplitude and reshape it so into the correct shape for the subarrays on the Phaser.
                    taper = taper / max(taper);
                    taper = [taper(1:4) taper(5:8)];
                    % Finally, we adjust the taper using the calibration 
                    % weights and set the new weights on the AntennaInteractor. 
                    % These new weights will be used to generate the beam pattern 
                    % instead of the default calibration weights. 
                    % We normalize the tapering for each subarray before updating the weights.
                    taper = analogWeightsCalAdjustment(taper,obj.calibrationweights.AnalogWeights);
                    if normalizeResults == 1
                        taper = taper ./ max(abs(taper));
                    end
                    obj.ai.updateAnalogWeights(taper);
                end

                % now we must to do this step from AntennaInteractor::capturePattern
                    % [analogweights,digitalweights] = this.getAllWeights(steerangles(ii));
                defaultAnalogWeights = obj.ai.AnalogWeights; % already tapered if enabled
                defaultDigitalWeights = obj.ai.DigitalWeights; % already tapered if enabled
                % get steering weights
                uncalanalogweights = obj.ai.SubSteer(obj.ai.Fc,obj.SteerAngle);
                uncaldigitalweights = obj.ai.ArraySteer(obj.ai.Fc,obj.SteerAngle);
                % Apply calibration weights
                obj.analogweights = analogWeightsCalAdjustment(uncalanalogweights,defaultAnalogWeights);
                obj.digitalweights = digitalWeightsCalAdjustment(uncaldigitalweights,defaultDigitalWeights);


                % THIS SOLUTION ALSO CAN BE FINE I THINK, but where are digitalwights???
                % steerweights = steervec(obj.elementLocation/freq2wavelen(obj.fc),[opts.SteerAngle;0]);
                % 
                % % Set the analog beamforming weights on the Phaser board to steer the beam,
                % % adjusting for calibration. First we have to rearrange them into two
                % % columns - one for each subarray.
                % analogsteer = analogWeightsCalAdjustment([steerweights(1:4) steerweights(5:8)],obj.ai.AnalogWeights); % already updated if tapering enabled
                % elementEnable = ones(size(analogsteer)); % enable all elements
                
                % then apply digital weights
                setAnalogBfWeights(obj.ai.ArrayControl, obj.analogweights);
                %%%% the next step is: rx(), and then: data = rx()
                    % patternData(:,ii) = rxdata * conj(digitalweights);
            end

        end

        function configure(obj)
            %configure 



            % Configure rx and bf at once:
            [~,obj.tx] = setupPluto(); % just to get the tx handle - this function is performed again in the following constructor
            obj.ai = AntennaInteractor(obj.fc,obj.calibrationweights);

            % Setup pluto sampling
            obj.ai.PlutoControl.SamplesPerFrame = obj.nSamples;
            obj.ai.PlutoControl.SamplingRate = obj.fs;

            % Setup transmitter
            obj.tx.SamplingRate = obj.fs;
            obj.tx.EnabledChannels = [1,2];
            obj.tx.CenterFrequency = obj.ai.PlutoControl.CenterFrequency;
            obj.tx.AttenuationChannel0 = -80;
            obj.tx.AttenuationChannel1 = -3;
            obj.tx.EnableCyclicBuffers = true;
            obj.tx.DataSource = "DMA";

            % This is where you could create some modulation scheme, we just use a
            % constant amplitude baseband signal.                % The same
            obj.amp = 0.9 * 2^15;
            obj.txWaveform = obj.amp*ones(obj.nSamples,2);

            % Setup ADF4159
            obj.ai.ArrayControl.Frequency = (obj.fc+obj.ai.PlutoControl.CenterFrequency)/4;
            obj.BW = obj.rampbandwidth / 4; 
            obj.num_steps = 2^9;
            obj.ai.ArrayControl.FrequencyDeviationRange = obj.BW;
            obj.ai.ArrayControl.FrequencyDeviationStep = ((obj.BW) / obj.num_steps);
            obj.ai.ArrayControl.FrequencyDeviationTime = obj.tsweep*1e6; % convert to us
            obj.ai.ArrayControl.RampMode = "single_sawtooth_burst"; % use a single sawtooth, other waveforms are available
            obj.ai.ArrayControl.TriggerEnable = true;  % start a ramp with TXdata
            obj.ai.ArrayControl.EnablePLL = true;
            obj.ai.ArrayControl.EnableTxPLL = true;
            obj.ai.ArrayControl.EnableOut1 = false; % send transmit out of SMA2

            % BEAM STEERING
            % First, set default analog weights
            obj.ai.updateAnalogWeights(obj.calibrationweights.AnalogWeights);

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

            obj.ai.PlutoControl(); % buffer clean


            %%%%%%%%% Old unwrapped solution

            % % Setup pluto
            % 
            % % Setup the pluto
            % [obj.rx,obj.tx] = setupPluto(); % was in  AntennaInteractor
            % 
            % % Setup pluto sampling
            % obj.rx.SamplesPerFrame = obj.nSamples; % rewritten
            % obj.rx.SamplingRate = obj.fs;  % rewritten
            % 
            % % Setup transmitter                % The same
            % obj.tx.SamplingRate = obj.fs;
            % obj.tx.EnabledChannels = [1,2];
            % obj.tx.CenterFrequency = obj.rx.CenterFrequency;
            % obj.tx.AttenuationChannel0 = -80;
            % obj.tx.AttenuationChannel1 = -3;
            % obj.tx.EnableCyclicBuffers = true;
            % obj.tx.DataSource = "DMA";
            % 
            % % This is where you could create some modulation scheme, we just use a
            % % constant amplitude baseband signal.                % The same
            % obj.amp = 0.9 * 2^15;
            % obj.txWaveform = obj.amp*ones(obj.nSamples,2);
            % 
            % 
            % % Setup the Phaser
            % 
            % 
            % % Setup beamformers all to max gain with no phase shifts
            % obj.bf = setupPhaser(obj.rx,obj.fc);      % was in  AntennaInteractor
            % obj.bf.RxPowerDown(:) = 0;
            % obj.bf.RxGain(:) = 127;
            % 
            % % Setup ADF4159                   %% rewritted
            % obj.bf.Frequency = (obj.fc+obj.rx.CenterFrequency)/4;
            % obj.BW = obj.rampbandwidth / 4; 
            % obj.num_steps = 2^9;
            % obj.bf.FrequencyDeviationRange = obj.BW;
            % obj.bf.FrequencyDeviationStep = ((obj.BW) / obj.num_steps);
            % obj.bf.FrequencyDeviationTime = obj.tsweep*1e6; % convert to us
            % obj.bf.RampMode = "single_sawtooth_burst"; % use a single sawtooth, other waveforms are available
            % obj.bf.TriggerEnable = true;  % start a ramp with TXdata
            % obj.bf.EnablePLL = true;
            % obj.bf.EnableTxPLL = true;
            % obj.bf.EnableOut1 = false; % send transmit out of SMA2
            % 
            % 
            % % Setup the TDD engine - No changes
            % 
            % obj.bf_TDD = setupTddEngine();
            % obj.tStartRamp = 0;
            % obj.tStartCollection = 0;
            % obj.bf_TDD.PhaserEnable = 1; % enable triggered mode
            % obj.bf_TDD.Enable = 0;   % TDD must be disabled before changing properties
            % obj.bf_TDD.EnSyncExternal = 1;
            % obj.bf_TDD.StartupDelay = 0;
            % obj.bf_TDD.SyncReset = 0;
            % obj.bf_TDD.FrameLength = obj.tpulse*1e3;  %frame length in ms
            % obj.bf_TDD.BurstCount = obj.nPulses; % Number of pulses in a CPI
            % obj.bf_TDD.Ch0Enable = 1;
            % obj.bf_TDD.Ch0Polarity = 0;
            % obj.bf_TDD.Ch0On = obj.tStartRamp; % Time to start PLL sweep in a frame
            % obj.bf_TDD.Ch0Off = obj.tStartRamp+0.1;
            % obj.bf_TDD.Ch1Enable = 1;
            % obj.bf_TDD.Ch1Polarity = 0;
            % obj.bf_TDD.Ch1On = obj.tStartCollection; % Time to start data collection in a frame
            % obj.bf_TDD.Ch1Off = obj.tStartCollection+0.1;
            % obj.bf_TDD.Ch2Enable = 1;
            % obj.bf_TDD.Ch2Polarity = 0;
            % obj.bf_TDD.Ch2On = 0;
            % obj.bf_TDD.Ch2Off = 0.1;
            % obj.bf_TDD.Enable = 1;
            % 
            % obj.rx(); % buffer clean % rewritten

        end

        function [path, raw_data, data, data1,data2] = saveData(obj)
            data = obj.data;
            data1 = obj.data1;
            data2 = obj.data2;
            raw_data = obj.raw_data;

            

            rawDataLen = obj.raw_data_len;
            fc = obj.fc;
            fs = obj.fs;
            prf = obj.prf;
            tpulse = obj.tpulse;
            rampbandwidth = obj.rampbandwidth;
            rx = obj.ai.PlutoControl;
            bf = obj.ai.ArrayControl;
            bf_TDD = obj.bf_TDD;
            sweepslope = obj.sweepslope;
            maxSpeed = obj.maxSpeed;
            maxRange = obj.maxRange;
            times_pre_tx = obj.times_pre_tx;
            times_post_tx = obj.times_post_tx;
            times_post_burse = obj.times_post_burse;
            times_post_rx = obj.times_post_rx;
            % calweights = obj.calweights;
            calibrationweights = obj.calibrationweights;
            analogweights = obj.analogweights;
            digitalweights = obj.digitalweights; % the most important - to apply on our data
            
            SteerAngle =  obj.SteerAngle ;
            Tapering = obj.Tapering ;
            SidelobeLevel = obj.SidelobeLevel ;
            nConstSidelobes = obj.nConstSidelobes ;

            tStartCollection = obj.tStartCollection;
            nPulsesPerFrame = obj.nPulses;
            nCaptures = obj.nCaptures;
            tsweep = obj.tsweep;
            path = obj.save_path + "phaser_rec_"+  obj.file_suffix + ".mat";
            % path_info = obj.save_path + "phaser_rec_"+  obj.file_suffix + "_info.mat";
            save(path, "raw_data", "data","data1","data2",...
                "fc", "fs", "prf","tpulse","rampbandwidth", ...
                "rx", "bf", "bf_TDD","sweepslope","maxSpeed","maxRange",...
                "times_pre_tx", "times_post_tx", "times_post_burse", "times_post_rx", "rawDataLen",...
                "tsweep", "tStartCollection","nPulsesPerFrame", "nCaptures",...
                "calibrationweights", "analogweights", "digitalweights",...
                "SteerAngle", "Tapering", "SidelobeLevel", "nConstSidelobes",'-v7.3');
        end
        
        function record(obj)
            %record signal


            obj.size_data_dim2 = obj.nPulses;
            obj.size_data_dim1 = ceil(obj.fs*obj.tsweep);
            obj.raw_data_len = ceil(obj.fs*obj.tpulse*obj.nPulses);
            
            % allocation
            if(obj.save_raw == 1)
                obj.raw_data = zeros(obj.raw_data_len*obj.nCaptures, 2);
            else
                obj.data = zeros(obj.size_data_dim1, obj.size_data_dim2*obj.nCaptures);
                if(obj.SeparateChannels)
                    obj.data1 = zeros(obj.size_data_dim1, obj.size_data_dim2*obj.nCaptures);
                    obj.data2 = zeros(obj.size_data_dim1, obj.size_data_dim2*obj.nCaptures);
                end
            end
            obj.time = zeros(1, obj.nCaptures);
            tic
            obj.times_pre_tx = zeros(1, obj.nCaptures);
            obj.times_post_tx = zeros(1, obj.nCaptures);
            obj.times_post_burse = zeros(1, obj.nCaptures);
            obj.times_post_rx = zeros(1, obj.nCaptures);
            % obj.calweights = loadCalibrationWeights().DigitalWeights; % save callibration weights


            for i = 1:obj.nCaptures
                idx_start = obj.size_data_dim2*(i-1)+1;
                idx_end = idx_start +obj.size_data_dim2-1;
                % capture data
                [raw_data_part, times_struct] = captureTransmitWf_timeStamps(obj.ai.PlutoControl,obj.tx,obj.ai.ArrayControl,obj.txWaveform);
            
                % time signatures
                obj.time(i) = toc;
                obj.times_pre_tx(i) = times_struct.time_pre_tx;
                obj.times_post_tx(i) = times_struct.time_post_tx;
                obj.times_post_burse(i) = times_struct.time_post_burse;
                obj.times_post_rx(i) = times_struct.time_post_rx;
            
                if(obj.save_raw == 1)
                    assert(obj.raw_data_len == length(raw_data_part));
                    idx_start_raw = (i - 1)*obj.raw_data_len + 1;
                    idx_end_raw = i*obj.raw_data_len;
                    obj.raw_data(idx_start_raw:idx_end_raw, :) = raw_data_part;
                else

                    % % Remove excess data, rearrange into nSamples x nPulses
                    obj.data(:,idx_start:idx_end) = arrangePulseData_fix(raw_data_part,...
                        obj.ai.PlutoControl,obj.ai.ArrayControl,obj.bf_TDD, "digitalweights",obj.digitalweights);
                    if(obj.SeparateChannels)
                        obj.data1(:,idx_start:idx_end) = arrangePulseData_fix(raw_data_part(:,1),obj.ai.PlutoControl,obj.ai.ArrayControl,obj.bf_TDD);
                        obj.data2(:,idx_start:idx_end) = arrangePulseData_fix(raw_data_part(:,2),obj.ai.PlutoControl,obj.ai.ArrayControl,obj.bf_TDD);
                    end
                end

            end
            obj.file_suffix = string(datetime("now")); % file suffix containing time signature
            obj.file_suffix = strrep(obj.file_suffix, ":", "-");
            obj.file_suffix = strrep(obj.file_suffix, " ", "_");
        end
    end
end

