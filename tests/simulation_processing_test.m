prf= 133;
vss = VitalSignsSimulator('SNR', 60,'PRF', prf);
[radar_signal_raw, t] = vss.simulate();
signal_filt = compl_diff(diff(unwrap(angle(radar_signal_raw))));
figure(1)
plot(t, signal_filt)

%%%% PROCESSING - HEART RATE EXTRACTION
% % we need then high-pass filter to cancel clutter and breath movement in spectrogram
phase_cutoff_freq_low = 5; % Hz
signal_filt = highpass(signal_filt, phase_cutoff_freq_low / prf);

% STFT calculation

[sp,f_ax,t_ax,fs_stft,overlap_len] = stft_general(signal_filt,prf,...
    "DesiredTimeRes",1/40, "FrequencyResolution",1,...
    "WindowWidth",0.25, "MaximumVisibleFrequency",40);

% extract heart cycles signal
heart_oscillation_freq_range = [0 30]; % Hz - fast oscillations of heartbeat
heart_cycles_detected = extract_env_sp(sp,f_ax,"FreqRange",heart_oscillation_freq_range);

% we do not expect heart rate below 0.5 Hz, so better to get rid of it
% before prediction (experimentally)
cutoff_freq_low = 0.5;
heart_cycles_detected = highpass(heart_cycles_detected,cutoff_freq_low / fs_stft);

%% synchrosqueezing
[synchrosqueezed,f_ax_fsst,t_ax_fsst] = synchrosqueezing_general(heart_cycles_detected,fs_stft,...
    "FrequencyResolution",1/60,"MaximumVisibleFrequency",3, "WindowWidth",5);

% then find tfridge
f_low_hb_expected = 30/60; % minimum heart rate expected is 50
f_high_hb_expexcted = 200/60; % maximum heart rate expected is 100
[ridges, synchrosqueezed, f_ax_fsst] = find_tfridge(synchrosqueezed, f_ax_fsst,...
    "JumpPenalty",0.1, "NuberOfRidges",2,...
    "PossibleHighFrequency",f_high_hb_expexcted,...
    "PossibleLowFrequency",f_low_hb_expected);

[~,lower_ridge_nr] = min(mean(ridges));
ridge = ridges(:,lower_ridge_nr);

% ridge = ridges(:,1);

% plot Result
f_ax_bpm = f_ax_fsst*60;
ridge_bpm = ridge*60;

% 1. Filtered Phase Differentiation
results.filteredPhase.time = t(1:length(signal_filt));
results.filteredPhase.data = signal_filt / prf;

% 2. STFT
results.stft.spectrogram = sp;
results.stft.t = t_ax;
results.stft.f = f_ax;
results.stft.cdata_stft = prep_cdata(sp, "QuantileVal",0.2);

% 3. Extracted signal from STFT
results.extractedSignal.t = t_ax;
results.extractedSignal.predicted = nan(1, numel(heart_cycles_detected));
results.extractedSignal.available = heart_cycles_detected;

% 4. Synchrosqueezed STFT
results.sstft.t = t_ax_fsst;
results.sstft.f = f_ax_bpm;
results.sstft.spectrogram = synchrosqueezed;
results.sstft.ridge = ridge_bpm;
results.sstft.cdata_sstft = prep_cdata(synchrosqueezed, "QuantileVal",0.2);


handles = initHeartbeatPlots();
plotHeartbeatResults(results,handles);