function data = captureTransmitWf_timeStamps(rx,tx,bf,txWaveform)
% Capture the transmitted waveform, the system has to be set up for
% transmit in this case. If no waveform is specified, use a constant
% amplitude rectangle.
arguments
    rx
    tx
    bf
    txWaveform = []
end

% If no transmit waveform is specified, use a constaint amplitude
% rectangle.
if isempty(txWaveform)
    amp = 0.9 * 2^15;
    txWaveform = amp*ones(rx.SamplesPerFrame,2);
elseif size(txWaveform,2) == 1
    txWaveform = [txWaveform txWaveform];
end

capture_time = 1;

if(capture_time)
    time = toc;
    evalin("base","times_pre_tx(end+1) = " + time +";")
    disp("Tx start:" + time);
end
% % Set transmit waveform
tx(txWaveform);
if(capture_time)
    time = toc;
    evalin("base","times_post_tx(end+1) = " + time +";")
    disp("tx performed after:" + time);
end

% % Trigger burst pulse
bf.Burst=false;bf.Burst=true;bf.Burst=false;
if(capture_time)
    time = toc;
    evalin("base","times_post_burse(end+1) = " + time +";")
    disp("Trigger burst pulse performed after:" + time);
end

% % Capture pulse period
data = rx();
if(capture_time)
    time = toc;
    evalin("base","times_post_rx(end+1) = " + time +";")
    disp("Capture pulse period performed after:" + time);
end
end
