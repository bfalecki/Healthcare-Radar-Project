sc = SignalCapturer("TotalRecLength",10,"FrameLength",1.5, "DoSave",0);
sc.configure();


while 1
    sc.record()

    RT = fft(sc.data);
    [radar_signal, RT_row] = choose_RT_row(RT);

    extract_breath(radar_signal,sc.prf,sc.fc,sc.times_post_tx);
    extract_heartbeat(radar_signal,sc.prf,sc.times_post_tx);
end