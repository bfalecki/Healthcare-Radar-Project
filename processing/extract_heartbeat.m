function [ridge_bpm,t_ax_fsst,heart_cycles_detected] = extract_heartbeat(radar_signal_raw,prf, frameStartTimes)
%EXTRACT_HEARTBEAT


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

% this fragment fills gaps in the signal by replicating the nearest value
% (to lower high frequency noise in the STFT)
signal_filt = fill_gaps_interp(signal_filt,segments_idxes, "nearest");


% % we need then high-pass filter to cancel clutter and breath movement in spectrogram
phase_cutoff_freq_low = 5; % Hz
signal_filt = highpass(signal_filt, phase_cutoff_freq_low / prf);


figure(11)
plot(t_resampled(1:length(signal_filt)),signal_filt/prf)
xlim([0 t_resampled(length(signal_filt))])
xlabel("Time [s]")
title("Filtered Phase Differentiation [rad/s]")


%% STFT calculation

[sp,f_ax,t_ax,fs_stft,overlap_len] = stft_general(signal_filt,prf,...
    "DesiredTimeRes",1/40, "FrequencyResolution",1,...
    "WindowWidth",0.25, "MaximumVisibleFrequency",40);

% extract heart cycles signal
heart_oscillation_freq_range = [10 20]; % Hz - fast oscillations of heartbeat
heart_cycles_detected = extract_env_sp(sp,f_ax,"FreqRange",heart_oscillation_freq_range);

% we need to determine segments start/end idxes on stft
[start_samples_stft,end_samples_stft] = convert_segments_sp(...
    start_samples,end_samples, prf, fs_stft, overlap_len);
% also binary idxes are necessary
segments_idxes_stft = get_segments_idxes(start_samples_stft,end_samples_stft, length(heart_cycles_detected));

figure(2)
sp(:,~segments_idxes_stft) = 0;
plot_surf(sp, t_ax, f_ax)
colormap("jet")
clim([-50 -20])
ylim([0 max(f_ax)])
title("Short Time Fourier Transform")
xlabel("Time [s]")
ylabel("Frequnecy [Hz]")

% we do not expect heart rate below 0.5 Hz, so better to get rid of it
% before prediction (experimentally)
cutoff_freq_low = 0.5;
heart_cycles_detected = highpass(heart_cycles_detected,cutoff_freq_low / fs_stft);


%% now we must perform signal prediction in breaks
heart_cycles_detected = fill_gaps_ar_wrapped(heart_cycles_detected,...
    fs_stft, segments_idxes_stft,segment_duration,"PartConsidered",1);


figure(3)
plot(t_ax, heart_cycles_detected)
hold on
heart_cycles_detected_segments_only = heart_cycles_detected;
heart_cycles_detected_segments_only(~segments_idxes_stft) = nan;
plot(t_ax, heart_cycles_detected_segments_only, LineWidth=2)
hold off
title("Signal Extracted from STFT")
legend("Predicted", "Available")
xlabel("Time [s]")


%% synchrosqueezing
[synchrosqueezed,f_ax_fsst,t_ax_fsst] = synchrosqueezing_general(heart_cycles_detected,fs_stft,...
    "FrequencyResolution",1/60,"MaximumVisibleFrequency",3, "WindowWidth",4);

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

figure(21)
imagesc(t_ax_fsst,f_ax_bpm,db(synchrosqueezed))
clim_max = max(db(synchrosqueezed),[], "all");
clim([clim_max-30 clim_max]) % we can see  up tu 30 dB smaller than maximum
cmap = colormap("gray");
colormap(flip(cmap))
colorbar
ax = gca;
ax.YDir = "normal";
hold on
plot(t_ax_fsst, ridge_bpm, "LineWidth",1.5, "Color","r", "LineStyle","--")
hold off
ylabel("Heart Rate [BPM]")
xlabel("Time [s]")
title("Synchrosqueezed STFT with detected time-frequency ridge")
end

