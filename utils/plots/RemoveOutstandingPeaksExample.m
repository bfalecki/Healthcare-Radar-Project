close all
filepath = "rec" + filesep + "phaser_rec_11-Jun-2025_14-08-17_max1mps.mat";

length = 6; % signal length, including breaks [s]
offset = 0; % start time, including breaks [s]


sc = SignalCapturerSimulator("RecFilePath",filepath,"TotalRecLength",length, "TimeOffset", offset, "GeneratePause",0);
sc.record();

% range compression
RT = fft(sc.data);
% slow time signal choice
[radar_signal_raw,range_cell] = choose_RT_row(RT);

% phase difference extraction\
phase = unwrap(angle(radar_signal_raw));
signal = compl_diff(diff(phase));

% measured signal needs to be filled with breaks
[signal, t_resampled, segment_duration, start_samples, end_samples,segments_idxes] = ...
fill_signal_gaps(signal, sc.times_post_tx, sc.prf);

figure(1);
% measured signal needs to be filtered regarding outstanding peaks...
signal_filt = filter_noise_peaks(signal, ...
    "SegmentsBounds", [start_samples;end_samples], ...
    "Display", 1, ...
    'ThresholdQuantile', 0.9, ...
    'ThresholdMultiplier',3);
xlim([500 720])
ylim([-0.16 0.16])
title("Differentiated Phase - Removing Outstanding Values")
setFigSize([0.2 0.2 0.35 0.4])