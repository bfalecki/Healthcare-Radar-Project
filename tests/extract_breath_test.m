% Breath signal interpolation
% Inspired by processing_RN.m by Rafał Najda

% 
filename = "phaser_rec_07-Aug-2025_12-20-54_1.5s_40cm_R_spoczynek.mat";
% filename = "phaser_rec_07-Aug-2025_13-03-54_1.5s__200cm_R_spoczynek.mat";
% filename = "phaser_rec_07-Aug-2025_12-45-57_1s__40cm_R_spoczynek.mat";
% filename = "phaser_rec_07-Aug-2025_12-54-22_1.5s__100cm_R_spoczynek.mat";
% filename = "phaser_rec_07-Aug-2025_13-08-10_0.2s__200cm_R_spoczynek.mat";
% filename = "phaser_rec_07-Aug-2025_12-58-56_0.2s_100cm_R_spoczynek.mat";
folder = "rec" + filesep;
rec_file = load(folder+filename);

% range compression & range cell choice
RT = fft(rec_file.data1);
[radar_signal_raw, RT_row] = choose_RT_row(RT);


% filling gaps in the signal
[signal_filled, time_lags_filled, segment_duration, start_samples, end_samples] = ...
    fill_signal_gaps(radar_signal_raw, rec_file.times_post_tx, rec_file.prf);
xlims = [time_lags_filled(1) time_lags_filled(end)];

%% phase anaylsis

phase = unwrap(angle(signal_filled));

% get rid of big first difference sample
phase = reset_accumulated_phase(phase, start_samples,end_samples);

% differentiation
phase_diff = compl_diff(diff(phase));

% outstanding vals filtering
phase_diff = filter_noise_peaks(phase_diff, "Display",0,"NeighborSize",3,...
    "SegmentsBounds",[start_samples;end_samples],...
    "ThresholdMultiplier",3,"ThresholdQuantille",0.9);

% fix segment edge noise (put mean values to every edge)
depht_samples = round(0.1 * rec_file.prf);
phase_diff = fix_edges(phase_diff, start_samples,end_samples, depht_samples);



% place NaNs in breaks
[phase_diff, max_gap] = placeNans_RN(phase_diff,start_samples, end_samples); % -1 is experimental fix

% interpolate breaks
phase_diff = fillmissing(phase_diff, 'linear', 'MaxGap',max_gap*2);

% Restore zeroes in NaN samples
phase_diff(isnan(phase_diff)) = 0;



% cumsum - integration
displacement = cumsum(phase_diff);
% displacement = phase2displ(displacement,rec_file.fc);
displacement = displacement - mean(displacement);

figure(4511)
plot(time_lags_filled, phase_diff)
xlabel("Time [s]")
xlim(xlims)
title("Interpolated fdoppler (using fillmissing)")

cutoff_freq_low = 0.05; % we do not expect breath rate below 0.05 Hz
displacement = highpass(displacement, cutoff_freq_low/rec_file.prf);
% for break visualization
displacement_unfilled = placeNans_RN(displacement,start_samples,end_samples);
figure(4)
plot(time_lags_filled,displacement)
hold on
plot(time_lags_filled,displacement_unfilled, LineWidth=2)
plot(time_lags_filled,reset_accumulated_phase(phase, start_samples,end_samples))
hold off
title("Cumulated fdoppler (phase)")

%% instantaneous respiratory rate using synchrosqueezing
[synchrosqueezed,f_ax_fsst,t_ax_fsst] = synchrosqueezing_general(displacement,rec_file.prf,...
    "FrequencyResolution",1/60/4,"MaximumVisibleFrequency",1.5, "WindowWidth",20);

% then find tfridge
f_low_breath_expected = 0.05; % minimum breath rate expected
f_high_breath_expexcted = 1.5; % maximum breath rate expected
[ridge, synchrosqueezed, f_ax_fsst] = find_tfridge(synchrosqueezed, f_ax_fsst,...
    "JumpPenalty",0.02, "NuberOfRidges",1,...
    "PossibleHighFrequency",f_high_breath_expexcted,...
    "PossibleLowFrequency",f_low_breath_expected);

% plot Result
f_ax_bpm = f_ax_fsst*60;
ridge_bpm = ridge*60;

figure(211)
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
ylabel("Breath Rate [BPM]")
xlabel("Time [s]")
title("Synchrosqueezed STFT with detected time-frequency ridge")

