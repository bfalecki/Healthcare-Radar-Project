

% actual measurement
% processing;
% signal = velocity;


% simulation
PRF = 133;
fc = 10e9;
VSSim = VitalSignsSimulator("SNR", 30, "PRF", PRF, 'CarrierFrequency', fc);
[radar_signal_raw, t] = VSSim.simulate();

radar_signal_raw = fftfilt([1 -2 1], radar_signal_raw);

signal = diff(unwrap(angle(radar_signal_raw)));

[imf,~, info] = vmd(signal, "NumIMFs",11);
disp(info.CentralFrequencies * PRF)

xlims = [1500 2400];
fig_size = [0 0.5 1, 0.3];

idxes_to_plt = info.CentralFrequencies * PRF < 20; % We want to see the components with freq. less than 20 Hz

close all


for k = find(idxes_to_plt).'
    figure(k)
    plot(imf(:, k))
    setFigSize(fig_size)
    % xlim(xlims)
end


figure(50)
plot(signal)
setFigSize(fig_size)
% xlim(xlims)
% ylim([-0.015 0.015])