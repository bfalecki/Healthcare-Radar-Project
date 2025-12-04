close all
% filepath = "rec" + filesep + "phaser_rec_01-Oct-2025_14-37-21_strong34Hz.mat"; % range cell 10
% filepath = "rec" + filesep + "phaser_rec_01-Oct-2025_15-19-46_strong19Hz.mat"; % range cell 11
% filepath = "rec" + filesep + "phaser_rec_01-Oct-2025_15-35-13_strong54Hz.mat"; % range cell 11
% filepath = "rec" + filesep + "phaser_rec_02-Oct-2025_13-18-31_5min.mat";
filepath = "rec" + filesep + "phaser_rec_04-Dec-2025_14-53-06_-45.mat";
sig_length = 1000; % signal length, including breaks [s]
offset = 0; % start time, including breaks [s] 


sc = SignalCapturerSimulator("RecFilePath",filepath,"TotalRecLength",sig_length, "TimeOffset", offset, "GeneratePause",0);
sc.record();

%% processing

% range compression
RT = fft(sc.data);
% slow time signal choice
[radar_signal, RT_row] = choose_RT_row(RT);
% RT_row = 11; radar_signal = RT(RT_row, :); % Hard fix

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

%% optional - compare heart rate with reference

compare_with_reference = 1;
if(compare_with_reference)
    % load reference measurement (from decathloncoach)
    % ref_path = "reference\kalenji\eu2dfde107c18a00b528_2025-10-02_fitness.fit";
    ref_path = "reference\kalenji\eu2231dc9cce5eb99169_2025-11-18_fitness.fit"; % phaser_rec_18-Nov-2025_15-01-06_vital-signs1.mat
    [heart_rate_ref, time_ref] = parse_fit(ref_path);
    time_ref = time_ref + hours(1); % UTC fix - or hours(2)

    % adjust radar measurement
    radar_t_relative = results_heartbeat.sstft.t;
    radar_heart_rate = results_heartbeat.sstft.ridge;
    % get filename
    dt_end = extract_datetime_of_filepath(filepath);
    dt_start = dt_end - seconds(sc.times_post_rx(end));
    radar_time = dt_start + seconds(radar_t_relative);

    figure(123)
    plot(radar_time, radar_heart_rate)
    hold on
    plot(time_ref, heart_rate_ref)
    hold off
    xlabel("Time")
    ylabel("Heart rate [BPM]")
    legend("Radar", "Kalenji Reference")
    grid on
    ylim([50 100])

end