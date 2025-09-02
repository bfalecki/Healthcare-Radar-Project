function results = extract_heartbeat(radar_signal_raw,prf, frameStartTimes,opts)
%EXTRACT_HEARTBEAT

arguments
    radar_signal_raw
    prf
    frameStartTimes
    opts.PlotFig = 0  % 1 if we want to plot figures
end

% phase difference extraction\
phase = unwrap(angle(radar_signal_raw));
signal = compl_diff(diff(phase));

% measured signal needs to be filled with breaks
[signal, t_resampled, segment_duration, start_samples, end_samples,segments_idxes] = ...
fill_signal_gaps(signal, frameStartTimes, prf);


% measured signal needs to be filtered regarding outstanding peaks...
signal_filt = filter_noise_peaks(signal, ...
    "SegmentsBounds", [start_samples;end_samples], ...
    "Display", 0, ...
    'ThresholdQuantile', 0.9, ...
    'ThresholdMultiplier',3);

% fix segment edge noise (put mean values to every edge) - helpful for
% further interpolation
FixEdgesDepth = 0.1;
depth_samples = round(FixEdgesDepth * prf);
signal_filt = fix_edges(signal_filt, start_samples,end_samples, depth_samples);
    

% this fragment fills gaps in the signal by replicating the nearest value
% (to lower high frequency noise in the STFT)
signal_filt = fill_gaps_interp(signal_filt,segments_idxes, "nearest");


% % we need then high-pass filter to cancel clutter and breath movement in spectrogram
phase_cutoff_freq_low = 5; % Hz
signal_filt = highpass(signal_filt, phase_cutoff_freq_low / prf);



%% STFT calculation

[sp,f_ax,t_ax,fs_stft,overlap_len] = stft_general(signal_filt,prf,...
    "DesiredTimeRes",1/40, "FrequencyResolution",1,...
    "WindowWidth",0.25, "MaximumVisibleFrequency",40);

% extract heart cycles signal
heart_oscillation_freq_range = [0 20]; % Hz - fast oscillations of heartbeat
heart_cycles_detected = extract_env_sp(sp,f_ax,"FreqRange",heart_oscillation_freq_range);

% we need to determine segments start/end idxes on stft
[start_samples_stft,end_samples_stft] = convert_segments_sp(...
    start_samples,end_samples, prf, fs_stft, overlap_len);
% also binary idxes are necessary
segments_idxes_stft = get_segments_idxes(start_samples_stft,end_samples_stft, length(heart_cycles_detected));



% we do not expect heart rate below 0.5 Hz, so better to get rid of it
% before prediction (experimentally)
cutoff_freq_low = 0.5;
heart_cycles_detected = highpass(heart_cycles_detected,cutoff_freq_low / fs_stft);


%% now we must perform signal prediction in breaks
heart_cycles_detected = fill_gaps_ar_wrapped(heart_cycles_detected,...
    fs_stft, segments_idxes_stft,segment_duration,"PartConsidered",1);



%% synchrosqueezing
[synchrosqueezed,f_ax_fsst,t_ax_fsst] = synchrosqueezing_general(heart_cycles_detected,fs_stft,...
    "FrequencyResolution",1/60,"MaximumVisibleFrequency",3, "WindowWidth",5);

% then find tfridge
f_low_hb_expected = 0.6; % minimum heart rate expected
f_high_hb_expexcted = 3; % maximum heart rate expected
[ridge, synchrosqueezed, f_ax_fsst] = find_tfridge(synchrosqueezed, f_ax_fsst,...
    "JumpPenalty",0.02, "NuberOfRidges",1,...
    "PossibleHighFrequency",f_high_hb_expexcted,...
    "PossibleLowFrequency",f_low_hb_expected);

% plot Result
f_ax_bpm = f_ax_fsst*60;
ridge_bpm = ridge*60;


% 1. Filtered Phase Differentiation
results.filteredPhase.time = t_resampled(1:length(signal_filt));
results.filteredPhase.data = signal_filt / prf;

% 2. STFT
sp(:,~segments_idxes_stft) = 0; % zero-out segments
results.stft.spectrogram = sp;
results.stft.t = t_ax;
results.stft.f = f_ax;
results.stft.cdata_stft = prep_cdata(sp, "QuantileVal",0.2);

% 3. Extracted signal from STFT
results.extractedSignal.t = t_ax;
results.extractedSignal.predicted = heart_cycles_detected;
tmp = heart_cycles_detected;
tmp(~segments_idxes_stft) = nan;
results.extractedSignal.available = tmp;

% 4. Synchrosqueezed STFT
results.sstft.t = t_ax_fsst;
results.sstft.f = f_ax_bpm;
results.sstft.spectrogram = synchrosqueezed;
results.sstft.ridge = ridge_bpm;
results.sstft.cdata_sstft = prep_cdata(synchrosqueezed, "QuantileVal",0.2);

if(opts.PlotFig)
    handles = initHeartbeatPlots();
    plotHeartbeatResults(results,handles);
    % figure(11)
    % plot(t_resampled(1:length(signal_filt)),signal_filt/prf)
    % xlim([0 t_resampled(length(signal_filt))])
    % xlabel("Time [s]")
    % title("Filtered Phase Differentiation [rad/s]")
    % drawnow
    % 
    % figure(12)
    % sp(:,~segments_idxes_stft) = 0;
    % plot_surf(sp, t_ax, f_ax)
    % colormap("jet")
    % clim([-50 -20])
    % ylim([0 max(f_ax)])
    % title("Short Time Fourier Transform")
    % xlabel("Time [s]")
    % ylabel("Frequnecy [Hz]")
    % drawnow
    % 
    % figure(13)
    % plot(t_ax, heart_cycles_detected)
    % hold on
    % heart_cycles_detected_segments_only = heart_cycles_detected;
    % heart_cycles_detected_segments_only(~segments_idxes_stft) = nan;
    % plot(t_ax, heart_cycles_detected_segments_only, LineWidth=2)
    % hold off
    % title("Signal Extracted from STFT")
    % legend("Predicted", "Available")
    % xlabel("Time [s]")
    % drawnow
    % 
    % figure(14)
    % imagesc(t_ax_fsst,f_ax_bpm,db(synchrosqueezed))
    % clim_max = max(db(synchrosqueezed),[], "all");
    % clim([clim_max-30 clim_max]) % we can see  up tu 30 dB smaller than maximum
    % cmap = colormap("gray");
    % colormap(flip(cmap))
    % colorbar
    % ax = gca;
    % ax.YDir = "normal";
    % hold on
    % plot(t_ax_fsst, ridge_bpm, "LineWidth",1.5, "Color","r", "LineStyle","--")
    % hold off
    % ylabel("Heart Rate [BPM]")
    % xlabel("Time [s]")
    % title("Synchrosqueezed STFT with detected time-frequency ridge")
    % drawnow
end
end

