classdef SignalCapturerSimulator < handle
    %SIGNALCAPTURERSIMULATOR 
    % This class acts as a helper for testing realtime-application scripts
    % withous using physical hardware
    
    properties
        prf
        data
        fc
        times_post_tx
        fmaxdop
        rampbandwidth
        lambda
        maxSpeed
        rangeResolution
        speedResolution
        maxRange
        TotalRecLength

        RecFilePath
    end
    
    methods
        function obj = SignalCapturerSimulator(opts)
            arguments
                opts.TotalRecLength = 20 % total recording of pure signal (excluding breaks) [s]
                opts.RecFilePath = "rec" + filesep + "phaser_rec_11-Jun-2025_14-08-17_max1mps.mat" % File path of the pre-recorded data
            end

            obj.fc = 10e9; % rf carrier frequency is ~10 GHz
            obj.TotalRecLength = opts.TotalRecLength;
            obj.RecFilePath = opts.RecFilePath;
        end

        function configure(obj)
            % just to keep compatibility
            disp("Configured!")
        end
        
        function record(obj)
            %
            file = load(obj.RecFilePath);
            obj.times_post_tx = file.times_post_tx;
            if(isfield(file, "data"))
                data_full = file.data;
            else
                data_full = file.data1;
            end
            Ncaptures = find(file.times_post_tx < obj.TotalRecLength, 1, "last");

            segment_duration = size(data_full,2) / (length(file.times_post_tx) * file.fs);
            samples_per_segment = round(segment_duration * file.fs);
            
            idx_end = Ncaptures * samples_per_segment;
            obj.data = data_full(:, 1:idx_end);
            obj.prf = file.prf;
            obj.times_post_tx = file.times_post_tx(1:Ncaptures);
            
            pause(file.times_post_rx(Ncaptures))
        end
    end
end

