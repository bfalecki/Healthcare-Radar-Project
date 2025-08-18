%% Prepare signal

% rec_file = load("rec"+filesep+"phaser_rec_11-Jun-2025_14-08-17_max1mps.mat");
rec_file = load("rec"+filesep+"phaser_rec_07-Aug-2025_12-20-54_1.5s_40cm_R_spoczynek.mat");

RT = fft(rec_file.data1);
actual_fs = rec_file.prf;
[radar_signal_raw, RT_row] = choose_RT_row(RT);


desired_fs = actual_fs; % We want to have a sampling frequency not to high to filter out high-frequency noise,
% but not too low in order to capture heart oscilations
% desired_fs should be 2x greater than typical heart oscillation frequency (about 8 Hz)

% downsampling
[radar_signal_raw, actual_fs, t_resampled] = set_fs(radar_signal_raw, actual_fs, desired_fs);


% phase difference extraction\
phase = unwrap(angle(radar_signal_raw));
signal = compl_diff(diff(phase));

% measured signal needs to be filled with breaks
[signal, t_resampled, segment_duration, start_samples, end_samples,segments_idxes] = ...
fill_signal_gaps(signal, rec_file.times_post_burse, actual_fs);


% measured signal needs to be filtered...

figure(1)
signal_filt = filter_noise_peaks(signal, ...
    "SegmentsBounds", [start_samples;end_samples], ...
    "Display", 0, ...
    'ThresholdQuantille', 0.9, ...
    'ThresholdMultiplier',2);

% this fragment fills gaps in the signal by replicating the nearest value
% (to lower high frequency noise in the STFT)
signal_filt = interp1(find(segments_idxes), signal_filt(segments_idxes), 1:length(signal_filt), "nearest");
signal_filt(isnan(signal_filt)) = signal_filt(find(~isnan(signal_filt), 1, "first"));


% % we need then high-pass filter to cancel clutter and breath movement
phase_cutoff_freq_low = 5; % Hz
signal_filt = highpass(signal_filt, phase_cutoff_freq_low / actual_fs);



% signal_filt = signal_filt(1:round(end/3));
figure(11)
plot(t_resampled(1:length(signal_filt)),signal_filt)

%% STFT test

window_width = 0.2; % s
time_res_desired = 1/20; % s
window = get_gauss_win(window_width, actual_fs, 2);
overlap_len = getSTFTOverlapLen(time_res_desired,length(window),actual_fs);
[sp, f_ax, t_ax] = stft(signal_filt, actual_fs, "Window",window,"OverlapLength",overlap_len);

fs_stft = 1/(t_ax(2) - t_ax(1)); % time step of the STFT

% we need to determine:
out_margin_s = window_width * 0.1; % do not use segment-bounds-samples
out_margin_samples = ceil(out_margin_s*fs_stft);
% overlap_len/2 is experimental
start_samples_stft = ceil(start_samples / actual_fs * fs_stft) + out_margin_samples - overlap_len/2 / actual_fs * fs_stft;
end_samples_stft = floor(end_samples / actual_fs * fs_stft) - out_margin_samples - overlap_len/2 / actual_fs * fs_stft;
segments_idxes_stft = get_segments_idxes(start_samples_stft,end_samples_stft, length(heart_cycles_detected));

sp(:,~segments_idxes_stft) = 0;

figure(2)
plot_surf(sp, t_ax, f_ax)
colormap("jet")
clim([-50 -20])

heart_oscillation_freq_range = [8 20]; % Hz - fast oscillations of heartbeat

[~,freq_row_idx_low] = min(abs(f_ax - heart_oscillation_freq_range(1) ));
[~,freq_row_idx_high] = min(abs(f_ax - heart_oscillation_freq_range(2) ));
heart_cycles_detected = sum(abs(sp(freq_row_idx_low:freq_row_idx_high, :)));

% we do not expect heart rate below 0.5 Hz and 3 Hz, so better to get rid of it
% before prediction
cutoff_freq_low = 0.5;
heart_cycles_detected = highpass(heart_cycles_detected, cutoff_freq_low / fs_stft);
% heart_cycles_detected = lowpass(heart_cycles_detected, cutoff_freq_high / heart_rate_fun_fs);



% now we must perform signal prediction
% First, we need to put nan instead of 0


heart_cycles_detected(~segments_idxes_stft) = nan;
p = segment_duration * fs_stft * 1 - 2*out_margin_samples; % part of segment
p = floor(p);

% then cut first break
after_break_idx = find(~isnan(heart_cycles_detected), 1,"first");
heart_cycles_detected = heart_cycles_detected(after_break_idx:end);

%  AR model fit
heart_cycles_detected = fill_gaps_ar(heart_cycles_detected, p);

% % high-pass filtering
% cutoff_freq = 0.5;
% heart_cycles_detected = highpass(heart_cycles_detected, )


% restore first break
heart_cycles_detected = [zeros( after_break_idx-1,1); heart_cycles_detected];

figure(3)
plot(heart_cycles_detected)

heartrate_function = fft(heart_cycles_detected - mean(heart_cycles_detected));
freq_ax = 0:fs_stft/length(heartrate_function):fs_stft - fs_stft/length(heartrate_function);
figure(4)
plot(freq_ax,abs(heartrate_function))
xlim([0 5])