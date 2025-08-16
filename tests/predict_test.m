rec_file = load("rec"+filesep+"phaser_rec_11-Jun-2025_14-08-17_max1mps.mat");
RT = fft(rec_file.data1);
actual_fs = rec_file.prf;
[radar_signal_raw, RT_row] = choose_RT_row(RT);


desired_fs = actual_fs; % We want to have a sampling frequency not to high to filter out high-frequency noise,
% but not too low in order to capture heart oscilations
% desired_fs should be 2x greater than typical heart oscillation frequency (about 8 Hz)

% downsampling
[radar_signal_raw, actual_fs, t_resampled] = set_fs(radar_signal_raw, PRF, desired_fs);


% phase difference extraction\
phase = unwrap(angle(radar_signal_raw));
signal = gradient(phase);

% measured signal needs to be filled with breaks
[signal, t_resampled, segment_duration, start_samples, end_samples,segments_idxes] = ...
fill_signal_gaps(signal, rec_file.times_post_burse, actual_fs);

% measured signal needs to be filtered...


signal_filt = filter_noise_peaks(signal, ...
    "SegmentsBounds", [start_samples;end_samples], ...
    "Display", 0, ...
    'ThresholdQuantille', 0.9);

% Prediction
% First, we need to put nan instead of 0
signal_filt(~segments_idxes) = nan;
p = segment_duration * actual_fs * 1; % part of segment
p = round(p);

% then cut first break
after_break_idx = find(~isnan(signal_filt), 1,"first");
signal_filled = signal_filt(after_break_idx:end);

%  AR model fit
signal_filled = fill_gaps_ar_bidirectional(signal_filled, p);

% restore first break
signal_filled = [zeros( after_break_idx-1,1); signal_filled];

figure(1)
plot(t_resampled, signal_filled, "LineWidth", 2)
hold on
plot(t_resampled, signal_filt.')
hold off