%% Prepare signal

rec_file = load("rec"+filesep+"phaser_rec_11-Jun-2025_14-08-17_max1mps.mat");
% rec_file = load("rec"+filesep+"phaser_rec_07-Aug-2025_12-20-54_1.5s_40cm_R_spoczynek.mat");
% rec_file = load("rec"+filesep+"phaser_rec_07-Aug-2025_12-45-57_1s__40cm_R_spoczynek");

RT = fft(rec_file.data1);
actual_fs = rec_file.prf;
[radar_signal_raw, RT_row] = choose_RT_row(RT);

% phase difference extraction\
phase = unwrap(angle(radar_signal_raw));
signal = compl_diff(diff(phase));

% measured signal needs to be filled with breaks
[signal, t_resampled, segment_duration, start_samples, end_samples,segments_idxes] = ...
fill_signal_gaps(signal, rec_file.times_post_burse, actual_fs);


% measured signal needs to be filtered regarding outstanding peaks...
signal_filt = filter_noise_peaks(signal, ...
    "SegmentsBounds", [start_samples;end_samples], ...
    "Display", 0, ...
    'ThresholdQuantille', 0.9, ...
    'ThresholdMultiplier',3);

% this fragment fills gaps in the signal by replicating the nearest value
% (to lower high frequency noise in the STFT)
signal_filt = fill_gaps_interp(signal_filt,segments_idxes, "nearest");


% % we need then high-pass filter to cancel clutter and breath movement
phase_cutoff_freq_low = 5; % Hz
signal_filt = highpass(signal_filt, phase_cutoff_freq_low / actual_fs);


figure(11)
plot(t_resampled(1:length(signal_filt)),signal_filt)



%% STFT calculation

[sp,f_ax,t_ax,fs_stft,overlap_len] = stft_general(signal_filt,actual_fs,...
    "DesiredTimeRes",1/40, "FrequencyResolution",1,...
    "WindowWidth",0.25, "MaximumVisibleFrequency",40);

% extract heart cycles signal
heart_oscillation_freq_range = [10 20]; % Hz - fast oscillations of heartbeat
heart_cycles_detected = extract_env_sp(sp,f_ax,"FreqRange",heart_oscillation_freq_range);

% we need to determine segments start/end idxes on stft
[start_samples_stft,end_samples_stft] = convert_segments_sp(...
    start_samples,end_samples, actual_fs, fs_stft, overlap_len);
% also binary idxes are necessary
segments_idxes_stft = get_segments_idxes(start_samples_stft,end_samples_stft, length(heart_cycles_detected));

figure(2)
sp(:,~segments_idxes_stft) = 0;
plot_surf(sp, t_ax, f_ax)
colormap("jet")
clim([-50 -20])

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
title("Signal extracted from STFT")
legend("Predicted", "Available")


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
plot(t_ax_fsst, ridge_bpm, "LineWidth",1.5, "Color","r")
hold off
title("Heart Rate [BPM]")


% % VMD - DOESN'T WORK WELL
% N_componenets = 3;
% [heart_cycles_detected_imf, ~, info] = vmd(heart_cycles_detected, "NumIMFs",N_componenets);
% 
% disp(info.CentralFrequencies * fs_stft)
% 
% possible_heartrate_idxes = (info.CentralFrequencies * fs_stft) < 3 & (info.CentralFrequencies * fs_stft) > 0.5; % We want to see the component of the heart rate: 0.5 ... 3 Hz
% heart_cycles_detected_possible = heart_cycles_detected_imf(:, possible_heartrate_idxes);
% 
% % choose the most prominent imf component
% [~,possible_heartrate_idxes] = max(rms(heart_cycles_detected_possible));
% heart_cycles_detected = heart_cycles_detected_possible(:, possible_heartrate_idxes);
% 
% figure(4)
% plot(t_ax, heart_cycles_detected, LineWidth=2, Color='b')
% hold on
% plot(t_ax, heart_cycles_detected_possible(:, 1:size(heart_cycles_detected_possible,2) ~= 3))
% hold off
% title("Vmd extracted")
% legend("Most probably heartbeat")



% % fft - synchrosqueezing is much better
% heartrate_function = fft(heart_cycles_detected - mean(heart_cycles_detected));
% freq_ax = 0:fs_stft/length(heartrate_function):fs_stft - fs_stft/length(heartrate_function);
% figure(5)
% plot(freq_ax,abs(heartrate_function))
% xlim([0 5])

