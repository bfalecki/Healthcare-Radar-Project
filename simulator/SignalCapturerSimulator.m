classdef SignalCapturerSimulator < handle
    %SIGNALCAPTURERSIMULATOR 
    % This class acts as a helper for testing realtime-application scripts
    % withous using physical hardware
    
    properties
        prf
        data
        data1
        data2
        fc
        times_post_tx
        times_post_rx
        fmaxdop
        rampbandwidth
        lambda
        maxSpeed
        rangeResolution
        speedResolution
        maxRange
        TotalRecLength
        TimeOffset
        digitalweights

        RecFilePath
        GeneratePause
        nPulsesPerFrame
        nCaptures
    end
    
    methods
        function obj = SignalCapturerSimulator(opts)
            arguments
                opts.TotalRecLength = 20 % total recording of signal [s]
                opts.TimeOffset = 0 % Time offset from start of the file [s]
                opts.RecFilePath = "rec" + filesep + "phaser_rec_11-Jun-2025_14-08-17_max1mps.mat" % File path of the pre-recorded data
                opts.GeneratePause = 1; % if we want to wait for the result
            end

            obj.fc = 10e9; % rf carrier frequency is ~10 GHz
            obj.TotalRecLength = opts.TotalRecLength;
            obj.RecFilePath = opts.RecFilePath;
            obj.GeneratePause =  opts.GeneratePause;
            obj.TimeOffset = opts.TimeOffset;
            obj.data1 = [];
            obj.data2 = [];
        end

        function configure(obj)
            % just to keep compatibility
            disp("Configured!")
        end
        
        function record(obj)
            %
            file = load(obj.RecFilePath);
            if(isfield(file, "calweights")) % compatibility with old measurements
                obj.digitalweights = file.calweights;
            end
            if(isfield(file, "digitalweights"))
                obj.digitalweights = file.digitalweights;
            end

            obj.times_post_tx = file.times_post_tx;
            obj.times_post_rx = file.times_post_rx;
            if(isfield(file, "data") && ~isempty(file.data))
                data_full = file.data;
            elseif(~isempty(file.data1) && (~isfield(file, "data2")  && isempty(file.data2))) % ??? only data1
                data_full = file.data1;
                warning("We do not have second channel: this is only half performance probably!")
            elseif(isfield(file, "data2") && ~isempty(file.data2)) % we have both channels to combine
                data_full = file.data1 * conj(obj.digitalweights(1)) + file.data2 * conj(obj.digitalweights(2));
            elseif(isfield(file, "raw_data") && ~isempty(file.raw_data))
                

                slow_time_len = file.nCaptures*file.nPulsesPerFrame;
                fast_time_len = ceil(file.tsweep * file.fs); % just like in the function
                data_full = zeros(fast_time_len,slow_time_len);
                for k = 1:file.nCaptures
                    global_idxes_of_frame = (k-1) * file.rawDataLen + 1 : k * file.rawDataLen;
                    slow_time_idxes_of_frame = (k-1) * file.nPulsesPerFrame + 1 : k * file.nPulsesPerFrame;
                    data_full(:, slow_time_idxes_of_frame) = arrangePulseData_fix(file.raw_data(global_idxes_of_frame, :),file.rx,file.bf,file.bf_TDD, ...
                        "fs",file.fs,"nPulses",file.nPulsesPerFrame,...
                        "tpulse",file.tpulse, "tstartsweep",file.tStartCollection,"tsweep",file.tsweep,...
                        "digitalweights",obj.digitalweights);
                end
                % data_full = arrangePulseData_fix(file.raw_data,file.rx,file.bf,file.bf_TDD, ...
                %     "fs",file.fs,"nPulses",file.nCaptures*file.nPulsesPerFrame,...
                %     "tpulse",file.tpulse, "tstartsweep",file.tStartCollection,"tsweep",file.tsweep);
            end

            Capture_first_idx = find(file.times_post_tx > obj.TimeOffset, 1, "first");
            Capture_last_idx = find(file.times_post_rx < obj.TimeOffset + obj.TotalRecLength, 1, "last");
            Ncaptures = Capture_last_idx - Capture_first_idx + 1;

            segment_duration = size(data_full,2) / (length(file.times_post_tx) * file.fs);
            samples_per_segment = round(segment_duration * file.fs);
            
            idx_end = Capture_last_idx * samples_per_segment;
            start_idx = (Capture_first_idx - 1) * samples_per_segment + 1;
            obj.data = data_full(:, start_idx:idx_end);
            if(isfield(file, "data1")) % if we have also separated channels
                if(~isempty(file.data1))
                    obj.data1 = file.data1(:, start_idx:idx_end);
                else
                    obj.data1 = [];
                end
            end
            if(isfield(file, "data2"))
                if(~isempty(file.data2))
                    obj.data2 = file.data2(:, start_idx:idx_end);
                else
                    obj.data2 = [];
                end
            end


            obj.prf = file.prf;
            obj.times_post_tx = file.times_post_tx(Capture_first_idx:Capture_last_idx);
            obj.times_post_tx = obj.times_post_tx - file.times_pre_tx(Capture_first_idx);
            obj.nPulsesPerFrame = file.nPulsesPerFrame;
            obj.nCaptures = file.nCaptures;
            
            if(obj.GeneratePause)
                pause(file.times_post_rx(Capture_last_idx) - file.times_pre_tx(Capture_first_idx))
            end
        end
    end
end

