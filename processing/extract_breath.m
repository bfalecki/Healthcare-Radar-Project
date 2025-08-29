function [ridge_bpm,t_ax_fsst,displacement] = extract_breath(radar_signal,prf, fc,frameStartTimes)
%EXTRACT_BREATH 

arguments
    radar_signal % signal for analysis [IQ]
    prf % pulse repetition frequnecy [Hz]
    fc % carrier freq. [Hz]
    frameStartTimes % time starts of segments [s], vector

end

% disp(" ---------------- Started extract_breath ----------------")

[phaseRaw,phaseDiffRaw,segmentsBounds, timeLags,segmentDuration,phase,phaseDiff] ...
    = prepare_phase( ...
    radar_signal,prf, ...
    "FixEdgesDepth",0.1,...
    "FNP_NeighborSize",3,...
    "FNP_ThresholdMultiplier",3,...
    "FNP_ThresholdQuantile",0.9,...
    "FrameStartTimes",frameStartTimes,...
    "FilterNoisePeaks",1);

start_samples = segmentsBounds(1, :);
end_samples = segmentsBounds(2, :);
xlims = [timeLags(1) timeLags(end)];



displacement = phase2displ(phase,fc);
% offset cancellation
displacement = displacement - mean(displacement);

cutoff_freq_low = 0.05; % we do not expect breath rate below 0.05 Hz
displacement = highpass(displacement, cutoff_freq_low/prf);

% for break visualization
displacement_unfilled = placeNans_RN(displacement,start_samples,end_samples);


% figure(20)
% plot(timeLags, phaseDiff)
% xlabel("Time [s]")
% xlim(xlims)
% title("Differentiated Phase")
% drawnow


% figure(21)
% plot(timeLags,displacement * 1e3)
% hold on
% plot(timeLags,displacement_unfilled * 1e3, LineWidth=2)
% hold off
% title("Displacement [mm]")
% drawnow

%% instantaneous respiratory rate using synchrosqueezing
[synchrosqueezed,f_ax_fsst,t_ax_fsst] = synchrosqueezing_general(displacement,prf,...
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

% figure(22)
% imagesc(t_ax_fsst,f_ax_bpm,db(synchrosqueezed))
% clim_max = max(db(synchrosqueezed),[], "all");
% clim([clim_max-30 clim_max]) % we can see  up tu 30 dB smaller than maximum
% cmap = colormap("gray");
% colormap(flip(cmap))
% colorbar
% ax = gca;
% ax.YDir = "normal";
% hold on
% plot(t_ax_fsst, ridge_bpm, "LineWidth",1.5, "Color","r")
% hold off
% ylabel("Breath Rate [BPM]")
% xlabel("Time [s]")
% title("Synchrosqueezed STFT with detected time-frequency ridge")
% drawnow
end

