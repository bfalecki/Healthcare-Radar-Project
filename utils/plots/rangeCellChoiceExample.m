% This script presents how range cell choice works

close all
filepath = "rec" + filesep + "phaser_rec_11-Jun-2025_14-08-17_max1mps.mat";

length = 4; % signal length, including breaks [s]
offset = 0; % start time, including breaks [s]


sc = SignalCapturerSimulator("RecFilePath",filepath,"TotalRecLength",length, "TimeOffset", offset, "GeneratePause",0);
sc.record();

% range compression
RT = fft(sc.data);
% slow time signal choice
[slow_time_signal,range_cell, RT_processed, choice_fun] = choose_RT_row(RT);

figure(1)
plot_surf(RT(1:20,:).')
setFigSize([0.2 0.2 0.5 0.5])
xlabel("Range Cell nr")
ylabel("Pulse nr")
title("Range Time Map")

figure(2)
plot_surf(RT_processed(1:20,:).')
setFigSize([0.2 0.2 0.5 0.5])
xlabel("Range Cell nr")
ylabel("Pulse nr")
title("Range Time Map (After MTI)")

figure(3)
plot(choice_fun, ".")
hold on
plot(range_cell, choice_fun(range_cell), "*", MarkerSize=10)
hold off
grid on
setFigSize([0.2 0.2 0.45 0.3])
xlim([1 20])
title("Range Cell Choice")
