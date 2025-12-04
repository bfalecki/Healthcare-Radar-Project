
filepath = "rec" + filesep + "phaser_rec_28-Nov-2025_11-09-39_behavior.mat";
% filepath = "rec" + filesep + "phaser_rec_18-Nov-2025_16-51-59_behavior1.mat";
% filepath = "rec" + filesep +  "phaser_rec_19-Nov-2025_12-04-39.mat";
% filepath = "rec" + filesep +  "phaser_rec_19-Nov-2025_11-55-39.mat";
sig_length = 1000; % signal length, including breaks [s]
offset = 0; % start time, including breaks [s] 


sc = SignalCapturerSimulator("RecFilePath",filepath,"TotalRecLength",sig_length, "TimeOffset", offset, "GeneratePause",0);
sc.record();

%% processing

% range compression
RT = fft(sc.data);
% slow time signal choice
% [radar_signal, RT_row] = choose_RT_row(RT);
 RT_row = 5; radar_signal = RT(RT_row,:);
% filling gaps in the signal
[signal_filled, timeLags, segmentDuration, start_samples, end_samples] = ...
    fill_signal_gaps(radar_signal, sc.times_post_tx, sc.prf, "cut_first_samples",1);

% signal_filled = compensateDcParts(signal_filled,start_samples, end_samples);

% % linear interpolation - a little bit better
% % place NaNs in breaks
% [signal_interp, max_gap] = placeNans_RN(signal_filled,start_samples, end_samples);
% 
% % interpolate breaks
% signal_interp = fillmissing(signal_interp, 'nearest', 'MaxGap',max_gap*2);
% 
% % Restore zeroes in NaN samples
% signal_interp(isnan(signal_interp)) = 0;

% % Autoregressive prediction
% binary idxes are necessary
segments_idxes = get_segments_idxes(start_samples,end_samples, length(signal_filled));

signal_pred = fill_gaps_ar_wrapped(signal_filled,...
    sc.prf, segments_idxes,segmentDuration,"PartConsidered",1, "bidirectional",1, "edge_ignore_length",0);


segmentsBounds = [start_samples;end_samples];

dt_end = extract_datetime_of_filepath(filepath);
dt_start = dt_end - seconds(sc.times_post_rx(end));

win_width = 0.05;
clim_low  = -85;
% [sp,f_ax,t_ax] = stft_general(radar_signal, sc.prf,...
%     "WindowWidth",win_width, "FrequencyResolution",1/win_width/3, "DesiredTimeRes",win_width/3);
% figure(1)
% plot_surf(sp, t_ax, fdoppler2vel(f_ax,sc.fc))
% clims = clim;
% clim([(clims(2)+clim_low) clims(2)] )
% [sp,f_ax,t_ax] = stft_general(signal_filled, sc.prf, "WindowWidth",0.4);
% figure(2)
% plot_surf(sp, t_ax, f_ax)
% [sp,f_ax,t_ax] = stft_general(signal_interp, sc.prf,...
%     "WindowWidth",win_width, "FrequencyResolution",1/win_width/3, "DesiredTimeRes",win_width/3);
% figure(3)
% plot_surf(sp, t_ax, f_ax)
[sp,f_ax,t_ax] = stft_general(signal_pred, sc.prf,...
    "WindowWidth",win_width, "FrequencyResolution",1/win_width/3, "DesiredTimeRes",win_width/3);
figure(4)
sp_norm = db(sp);
noise_lvl = median(sp_norm, "all");
sp_norm = sp_norm - noise_lvl;
plot_surf(sp_norm,dt_start + seconds(t_ax), fdoppler2vel(f_ax,sc.fc), 0,"", 'jet')
clims = clim;
clim([(clims(2) +clim_low) clims(2)] )
ylabel('Radial Velocity [m/s]')
hc = colorbar;
set(hc.Label, "String", 'Energy [dB]')