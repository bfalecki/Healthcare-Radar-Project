close all
filepath = "rec" + filesep + "phaser_rec_11-Jun-2025_14-08-17_max1mps.mat";

sig_length = 30; % signal length, including breaks [s]
offset = 0; % start time, including breaks [s]


sc = SignalCapturerSimulator("RecFilePath",filepath,"TotalRecLength",sig_length, "TimeOffset", offset, "GeneratePause",0);
sc.record();

%% processing

% range compression
RT = fft(sc.data);
% slow time signal choice
[radar_signal, RT_row] = choose_RT_row(RT);

% breath extraction
results_breath = extract_breath(radar_signal, sc.prf, sc.fc,sc.times_post_tx);
handles_breath = initBreathPlots();
plotBreathResults(results_breath, handles_breath, "RTrows",RT_row);

% additional fig
figure(29)
plot(results_breath.phase.time, results_breath.phase.data);
setFigSize([0.0 0.3 0.6 0.35])
title("Differentiated Phase Interpolation")
xlabel("Time [s]")
ylabel("Diff. Phase [rad/sample]")

% heartbeat extraction
results_heartbeat = extract_heartbeat(radar_signal,sc.prf,sc.times_post_tx, PlotFig=1);

