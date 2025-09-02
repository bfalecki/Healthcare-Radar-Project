close all
results_path = "results" + filesep + "meas2" + filesep + "*21*.mat";

files = dir(results_path);

handles_breath = initBreathPlots();
handles_heartbeat = initHeartbeatPlots();

breath_rate_cell = {};
breath_rate_time_ax_cell = {};
heart_rate_cell = {};
heart_rate_time_ax_cell = {};

for k = 1:length(files)

    file = load([files(k).folder filesep files(k).name]);

    breath_rate = file.results_breath.sstft.ridge;
    breath_rate_time_ax = seconds(file.results_breath.sstft.t) + file.fragment_date_start;
    heart_rate = file.results_heartbeat.sstft.ridge;
    heart_rate_time_ax = seconds(file.results_heartbeat.sstft.t) + file.fragment_date_start;

    breath_rate_cell{end+1} = breath_rate;
    breath_rate_time_ax_cell{end+1} = breath_rate_time_ax;
    heart_rate_cell{end+1} = heart_rate;
    heart_rate_time_ax_cell{end+1} = heart_rate_time_ax;

    plotBreathResults(file.results_breath, handles_breath, "RTrows", file.RTrow_vect);
    plotHeartbeatResults(file.results_heartbeat, handles_heartbeat);

    % pause(1);
end
