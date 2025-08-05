% estimation of the offset distance between data frames in the displacement graph

% simulation
PRF = 133;
fc = 10e9;
VSSim = VitalSignsSimulator("SNR", 40, "PRF", PRF, 'CarrierFrequency', fc, ...
    "SimulationTime", 20);
[radar_signal_raw, t] = VSSim.simulate();


% actual achievable radar parameters
frame_duration = 1.5; % duration of frame [s]
break_duration = 1; % duration of break [s]

[signal, frame_start_idxes, frame_end_idxes] = place_breaks(radar_signal_raw, frame_duration, break_duration, PRF);

% figure(1)
% plot(t,real(signal))

% phase extraction
phase = unwrap(angle(signal));
[phase] = reset_accumulated_phase(phase,frame_start_idxes,frame_end_idxes);
figure(211)
displacement = phase2displ(phase, fc);
plot(t, displacement*1e3)
xlabel("Time [s]")
ylabel("Displacement [mm]")
xlim(xlims)


% offset reconstruction




function [signal_framed, frame_start_idxes, frame_end_idxes] = place_breaks(signal, frame_duration, break_duration, fs)
    
    signal_framed = signal;
    frame_samples = round(frame_duration* fs);
    segment_samples = round((frame_duration+break_duration)*fs);
    Nsegments = ceil(length(signal)/segment_samples);
    frame_start_idxes = segment_samples * (0:Nsegments-1) + 1;
    frame_end_idxes = frame_start_idxes + frame_samples - 1;
    frame_end_idxes(frame_end_idxes > length(signal)) = length(signal);
    for nr = 1:length(frame_start_idxes)
        idxes_to_clear = frame_start_idxes(nr) + frame_samples : frame_start_idxes(nr) + segment_samples - 1;
        idxes_to_clear = idxes_to_clear(idxes_to_clear <= length(signal));
        signal_framed(idxes_to_clear) = 0;
    end

end
