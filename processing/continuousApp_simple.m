clear; close all;
warning('off','MATLAB:system:ObsoleteSystemObjectMixin')

% actual measurment using hardware
sc = SignalCapturer("TotalRecLength",20,"FrameLength",1.87, "DoSave",0);

% % % simulation of recording
% sc = SignalCapturerSimulator("TotalRecLength",10, "RecFilePath","rec" +filesep + "phaser_rec_01-Sep-2025_13-41-39.mat");


sc.configure();


while 1
    sc.record()

    RT = fft(sc.data);
    [radar_signal, RT_row] = choose_RT_row(RT);

    extract_breath(radar_signal,sc.prf,sc.fc,sc.times_post_tx,"PlotFig",1);
    extract_heartbeat(radar_signal,sc.prf,sc.times_post_tx,"PlotFig",1);
end