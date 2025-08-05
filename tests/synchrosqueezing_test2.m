% % simulation
% PRF = 133;
% fc = 10e9;
% VSSim = VitalSignsSimulator("SNR", 40, "PRF", PRF, 'CarrierFrequency', fc);
% [radar_signal_raw, t] = VSSim.simulate();

% real measurement
file = load("rec"+filesep+"phaser_rec_11-Jun-2025_14-08-17_max1mps.mat");
fc = file.fc;
PRF = file.prf;

range_cell = 5;
RT = fft(file.data1);
radar_signal_parts = RT(range_cell,:);
[radar_signal_raw, time_lags_filled] = fill_signal_gaps(radar_signal_parts, file.times_post_tx, PRF);


SVis = SynchrosqueezingVisualizer('PRF', PRF,'CarrierFrequency', fc, ...
    'MaximumVelocityExpected', 0.03, 'MinAllowablePRF', 60, 'WindowWidth', 0.03, ...
    'VelocityPerSample', 0.0005);

[synchrosqueezed, vel_ax,t_ax] = SVis.processSignal(radar_signal_raw);
figure(4)
SVis.plotResult(synchrosqueezed,vel_ax,t_ax)
clim([110 140])
xlabel("Time [s]")
ylabel("Velocity [m/s]")

% The results show that in the time-frequency plane, a waveform similar 
% to the unfiltered velocity obtained by phase demodulation can be obtained. 
% The advantage is that there are no strongly rebounding samples like in the phase-based
% velocity waveform.