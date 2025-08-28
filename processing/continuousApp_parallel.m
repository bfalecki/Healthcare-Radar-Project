sc = SignalCapturer("TotalRecLength",10,"FrameLength",1.5, "DoSave",0);
sc.configure();

futures = parallel.FevalFuture.empty; % przechowywanie zadań asynchronicznych

while true
    sc.record();             % akwizycja 1 ramki
    
    RT = fft(sc.data);
    [radar_signal, RT_row] = choose_RT_row(RT);

    % analiza w tle
    f1 = parfeval(backgroundPool, @extract_breath, 0, radar_signal, sc.prf, sc.fc, sc.times_post_tx);
    f2 = parfeval(backgroundPool, @extract_heartbeat, 0, radar_signal, sc.prf, sc.times_post_tx);

    futures = [futures f1 f2];  % kolekcja futures (opcjonalnie można sprzątać)
end