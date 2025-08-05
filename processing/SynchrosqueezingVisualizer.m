classdef SynchrosqueezingVisualizer
    %SYNCHROSQUEEZINGVISUALIZER 
    % synchrosqueezing-based vital signs visualizer
    
    properties (Access = private)
        PRF
        fc
        max_vel_expected
        min_allowable_PRF
        win_width
        velocity_per_sample
        decim_rank
        PRF_decim
        window
    end
    
    methods
        function obj = SynchrosqueezingVisualizer(varargin)
            %SYNCHROSQUEEZINGVISUALIZER Construct an instance of this class
            p = inputParser;

            addParameter(p, 'PRF', 100); % Pulse Repetition Frequency of the radar [Hz]
            addParameter(p, 'CarrierFrequency', 10e9); % Carrier frequency of the radar [Hz]
            addParameter(p, 'MaximumVelocityExpected', 0.05); % Maximum velocity visiblie on the TF plane [m/s]
            addParameter(p, 'MinAllowablePRF', 60);  % [Hz], heartbeat oscillations have about 8 Hz, so decimation cannot be very high
                        % Smaller MinAllowablePRF value -> method seems to
                        % be more robust to noise, but too small can
                        % produce artifacts on heartbeat waveform
            addParameter(p, 'WindowWidth', 0.025); % Gaussian window FWHM [s], ideally, it should be less than half of period of 8 Hz fast heartbeat oscillations, i.e. 0.05 s,
                % but in low-SNR, a bit longer window width can help
            addParameter(p, 'VelocityPerSample', 0.001); % velocity per sample on spectrogram [m/s]. Typically, heartbeat velocity has amplitude of 0.005 m/s, 
                            % so the velocity resolution must be smaller
                        

            parse(p, varargin{:});

            obj.PRF = p.Results.PRF;
            obj.fc = p.Results.CarrierFrequency;
            obj.max_vel_expected = p.Results.MaximumVelocityExpected;
            obj.min_allowable_PRF = p.Results.MinAllowablePRF;
            obj.win_width = p.Results.WindowWidth;
            obj.velocity_per_sample = p.Results.VelocityPerSample;



            max_vel = -fdoppler2vel(obj.PRF/2,obj.fc);

            obj.decim_rank = floor(max_vel/obj.max_vel_expected);
            obj.decim_rank(obj.decim_rank == 0) = 1;

            decim_rank_max = floor(obj.PRF/obj.min_allowable_PRF);
            decim_rank_max(decim_rank_max == 0) = 1;
            obj.decim_rank(obj.decim_rank > decim_rank_max) = decim_rank_max;
            
            
            obj.PRF_decim = obj.PRF/obj.decim_rank;

            
            freq_per_sample = -vel2fdoppler(obj.velocity_per_sample, obj.fc);
            win_length = round(obj.PRF_decim/freq_per_sample);
            win_duration = win_length/obj.PRF_decim; % duration of entire window [s]
            width_factor = obj.win_width/win_duration; % part of window belonging to FWHM
            obj.window = gausswin(win_length,2.354/2/width_factor);

        end
        
        function [synchrosqueezed, vel_ax,t_ax] = processSignal(obj,radar_signal_raw)
            %Process radar data - calculate synchrosqueezed plane

            radar_signal_processed = decimate(radar_signal_raw, obj.decim_rank);
            if(length(radar_signal_processed) < length(obj.window)) % preventing fsst error
                radar_signal_processed = padarray(radar_signal_processed.', length(obj.window) - length(radar_signal_processed), "post").';
            end

            [synchrosqueezed, f_ax,t_ax] = fsst(radar_signal_processed,obj.PRF_decim, obj.window);
            vel_ax = fdoppler2vel(f_ax, obj.fc);
            time_idxes = t_ax <= length(radar_signal_raw)/obj.PRF;
            t_ax = t_ax(time_idxes);
            synchrosqueezed = synchrosqueezed(:,time_idxes);
        end

        function plotResult(obj, synchrosqueezed,vel_ax,t_ax)
            imagesc(t_ax,vel_ax,db(synchrosqueezed))
            ylim([-obj.max_vel_expected obj.max_vel_expected])
            colorbar
            ax = gca;
            ax.YDir = "normal";
        end
    end
end

