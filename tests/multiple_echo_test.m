% Simulation of clutter/multiple echoes in the signal

vsSim = VitalSignsSimulator();
vsSim.simulate();

phase_original = vsSim.phase_signal;
radar_signal_original = vsSim.radar_signal_raw; % no clutter

A_signal = 0.1;
A_clutter = 1;

% we do not know exactly how radar's hardware/software performs highpass
% filtering to remove clutter.

% radar_signal_cluttered = radar_signal_original + 
