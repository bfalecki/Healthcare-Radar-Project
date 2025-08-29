% Breath signal interpolation
% Inspired by processing_RN.m by Rafał Najda

% 
filename = "phaser_rec_29-Aug-2025_16-47-08.mat";
% filename = "phaser_rec_07-Aug-2025_12-20-54_1.5s_40cm_R_spoczynek.mat";
% filename = "phaser_rec_07-Aug-2025_13-03-54_1.5s__200cm_R_spoczynek.mat";
% filename = "phaser_rec_07-Aug-2025_12-45-57_1s__40cm_R_spoczynek.mat";
% filename = "phaser_rec_07-Aug-2025_12-54-22_1.5s__100cm_R_spoczynek.mat";
% filename = "phaser_rec_07-Aug-2025_13-08-10_0.2s__200cm_R_spoczynek.mat";
% filename = "phaser_rec_07-Aug-2025_12-58-56_0.2s_100cm_R_spoczynek.mat";
folder = "rec" + filesep;
rec_file = load(folder+filename);

% range compression & range cell choice
RT = fft(rec_file.data);
[radar_signal_raw, RT_row] = choose_RT_row(RT);


% % % % % % what do we need for processing:
% % % % % % rec_file.times_post_tx (FrameStartTimes)
% % % % % % rec_file.prf (PRF)
% % % % % % radar_signal_raw (RadarSignal)
% % % % % 
% % % % % % optional

[phaseRaw,phaseDiffRaw,segmentsBounds, timeLags,segmentDuration,phase,phaseDiff] ...
    = prepare_phase( ...
    radar_signal_raw,rec_file.prf, ...
    "FixEdgesDepth",0.1,...
    "FNP_NeighborSize",3,...
    "FNP_ThresholdMultiplier",3,...
    "FNP_ThresholdQuantile",0.9,...
    "FrameStartTimes",rec_file.times_post_tx,...
    "FilterNoisePeaks",1);

start_samples = segmentsBounds(1, :);
end_samples = segmentsBounds(2, :);
xlims = [timeLags(1) timeLags(end)];



displacement = phase2displ(phase,rec_file.fc);
% offset cancellation
displacement = displacement - mean(displacement);

cutoff_freq_low = 0.05; % we do not expect breath rate below 0.05 Hz
displacement = highpass(displacement, cutoff_freq_low/rec_file.prf);

% for break visualization
displacement_unfilled = placeNans_RN(displacement,start_samples,end_samples);


figure(4511)
plot(timeLags, phaseDiff)
xlabel("Time [s]")
xlim(xlims)
title("Differentiated Phase")


figure(4)
plot(timeLags,displacement * 1e3)
hold on
plot(timeLags,displacement_unfilled * 1e3, LineWidth=2)
hold off
title("Displacement [mm]")

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

