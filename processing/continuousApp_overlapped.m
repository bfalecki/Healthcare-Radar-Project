sc = SignalCapturer("TotalRecLength",10,"FrameLength",1.5, "DoSave",0);
sc.configure();

windowSize = 5;       % number of frames in analysis window
hopSize = 2;          % step size in frames
sigBuffer = {};       % FIFO buffer for radar signals
timeBuffer = {};      % FIFO buffer for raw sc.times_post_tx
startTimes = [];      % system timestamps (one per frame)
counter = 0;          % frame counter

tic; % global reference for system time measurement

while true
    % --- system timestamp BEFORE recording ---
    frameStartSys = toc;   % time in seconds relative to loop start

    % --- acquisition step ---
    sc.record();
    RT = fft(sc.data);
    [radar_signal, RT_row] = choose_RT_row(RT);

    % --- store signal and frame start time ---
    sigBuffer{end+1}  = radar_signal;
    timeBuffer{end+1} = sc.times_post_tx;  % raw local times
    startTimes(end+1) = frameStartSys;     % absolute system start

    % keep only the last windowSize frames
    if numel(sigBuffer) > windowSize
        sigBuffer  = sigBuffer(end-windowSize+1:end);
        timeBuffer = timeBuffer(end-windowSize+1:end);
        startTimes = startTimes(end-windowSize+1:end);
    end

    % --- frame counter ---
    counter = counter + 1;

    % --- trigger analysis every hopSize frames ---
    if counter >= hopSize && numel(sigBuffer) == windowSize
        % normalize startTimes so that the first frame in window starts at 0
        baseTime = min(startTimes);

        adjustedTimes = {};
        for k = 1:numel(timeBuffer)
            adjustedTimes{end+1} = timeBuffer{k} + (startTimes(k) - baseTime);
        end

        % concatenate buffered frames into one longer signal and time axis
        long_signal = cat(2, sigBuffer{:});
        long_time   = cat(2, adjustedTimes{:});

        % run analysis asynchronously (non-blocking)
        parfeval(backgroundPool, @extract_breath, 0, long_signal, sc.prf, sc.fc, long_time);
        parfeval(backgroundPool, @extract_heartbeat, 0, long_signal, sc.prf, long_time);

        % reset frame counter -> offsets will be recomputed fresh for next window
        counter = 0;
    end
end
