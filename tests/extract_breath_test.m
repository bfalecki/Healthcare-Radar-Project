% Breath signal interpolation
% Inspired by processing_RN.m by Rafał Najda


filename = "phaser_rec_07-Aug-2025_12-20-54_1.5s_40cm_R_spoczynek.mat";
% filename = "phaser_rec_07-Aug-2025_13-03-54_1.5s__200cm_R_spoczynek.mat";
folder = "rec" + filesep;
rec_file = load(folder+filename);

% range compression & range cell choice
RT = fft(rec_file.data1);
[radar_signal_raw, RT_row] = choose_RT_row(RT);

% filling gaps in the signal
[signal_filled, time_lags_filled, segment_duration, start_samples, end_samples] = ...
    fill_signal_gaps(radar_signal_raw, rec_file.times_post_tx, rec_file.prf);

%% phase demodulation
phase = unwrap(angle(signal_filled));

xlims = [time_lags_filled(1) time_lags_filled(end)];
figure(21)
plot(time_lags_filled, phase)
xlabel("Time [s]")
ylabel("Unwrapped phase [rad]")
xlim(xlims)

%% differentiation
fdoppler = phase2fdoppler(phase, rec_file.fs);

% outstanding vals filtering
figure(9)
fdoppler = filter_noise_peaks(fdoppler, "Display",1,"NeighborSize",2,...
    "SegmentsBounds",[start_samples;end_samples],"ThresholdMultiplier",3,"ThresholdQuantille",0.9);


% place NaNs in breaks
[fdoppler, max_gap] = placeNans_RN(fdoppler,start_samples, end_samples);

% interpolate breaks
fdoppler = fillmissing(fdoppler, 'linear', 'MaxGap',max_gap*2);

% Restore zeroes in NaN samples
fdoppler(isnan(fdoppler)) = 0;

% Plot 


figure(4511)
plot(time_lags_filled, fdoppler)
xlabel("Time [s]")
ylabel("Doppler frequency [Hz]")
xlim(xlims)
title("Interpolated fdoppler (using fillmissing)")

% cumsum
displacement = cumsum(fdoppler);
displacement = displacement - mean(displacement);
cutoff_freq_low = 0.05;
displacement = highpass(displacement, cutoff_freq_low/rec_file.prf);
figure(4)
plot(time_lags_filled,displacement)
title("Cumulated fdoppler (phase)")

%% instantaneous respiratory rate using synchrosqueezing
[synchrosqueezed,f_ax_fsst,t_ax_fsst] = synchrosqueezing_general(displacement,rec_file.prf,...
    "FrequencyResolution",1/60,"MaximumVisibleFrequency",1.5, "WindowWidth",20);

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


%% respiratory rate - FFT spectrum

figure(2111)
displacement_spectrum = fft(displacement, 4*length(displacement));
f_ax = linspace(0, prf, length(displacement_spectrum));
plot(f_ax, abs(displacement_spectrum))
xlim([0 1])
title("Displacement FFT")
xlabel("Frequency [Hz]")
ylabel("Amplitude")

