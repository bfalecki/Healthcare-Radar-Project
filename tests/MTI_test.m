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

% MTI
radar_signal_raw = fftfilt([1 -2 1], radar_signal_raw);


SVis = SynchrosqueezingVisualizer('PRF', PRF,'CarrierFrequency', fc, ...
    'MaximumVelocityExpected', 0.03, 'MinAllowablePRF', 40, 'WindowWidth', 0.08, ...
    'VelocityPerSample', 0.0005);

% SVis = SynchrosqueezingVisualizer('PRF', PRF,'CarrierFrequency', fc);

[synchrosqueezed, vel_ax,t_ax] = SVis.processSignal(radar_signal_raw);
figure(4)
SVis.plotResult(synchrosqueezed,vel_ax,t_ax)
% clim([110 140])
ylim([-0.4 0.4])
xlabel("Time [s]")
ylabel("Velocity [m/s]")

% MTI usually distorts the vital signs signal.

% However, I think MTI can be useful for selecting which RT map row to analyze.
% MTI filtering is good at picking up fast-changing components of vital signs and is
% likely good at distinguishing them from clutter.

% See below section:

%% Test of range cell detection with help of MTI

RT_filt = fftfilt([1 -2 1], RT.').';
figure(1)
imagesc(db(RT_filt))
ylim([1 10])
colorbar
figure(2)
imagesc(db(RT))
ylim([1 10])
colorbar

% figure(3)
% plot(std(RT_filt(1:10,:),[],2))
% figure(4)
% plot(std(RT(1:10,:),[],2))
% 
% figure(33)
% plot(mean(abs(RT_filt(1:10,:)),2))
% figure(44)
% plot(mean(abs(RT(1:10,:)),2))
