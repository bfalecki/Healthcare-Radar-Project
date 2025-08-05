% this script can load signal recorded by record_signal.m
% and display its RT/RD maps, and also TF representation
% and slow-time phase

load("phaser_rec_11-Jun-2025_14-08-17_max1mps.mat")

% breath2s.mat - 2s-nagranie oddechu - ok. 1 m od nadajnika/odbiornika

data = data1; % data1 / data2

c = physconst("LightSpeed");

addpath(genpath("C:\Users\bfalecki\Documents\radarprfdetection\scripts"))
addpath(genpath("Phaser-Control-with-MATLAB")) % <-- path to https://github.com/mathworks/Phaser-Control-with-MATLAB/tree/main



%% Create a range doppler plot
rd = phased.RangeDopplerResponse(DopplerOutput="Speed",...
    OperatingFrequency=fc,SampleRate=fs,RangeMethod="FFT",...
    SweepSlope=sweepslope,PRFSource="Property",PRF=prf);
axes(figure)
rd.plotResponse(data1);
ax = gca;
xlim(ax,[-maxSpeed,maxSpeed]); ylim(ax,[0,maxRange]);

%% wybór wiersza mapy RT

RT = fft(data1);
RD = fftshift(fft(RT,[], 2),2);
% figure(23)
% imagesc(db(RD(1:20,:)))
% ax = gca;
% ax.YDir = "normal";

figure(24)
imagesc(db(RD(1:20,:)))
ax = gca;
ax.YDir = "normal";
colorbar

figure(22)
imagesc(db(RT(1:20,:)))
ax = gca;
ax.YDir = "normal";
colorbar




%% wydobycie jednowymiarowego przebiegu
range_cell = 5;

signal_extracted = RT(range_cell,:);

% freq_start = 0.03;
% freq_end = 0.03;
% 
% signal_extracted_flt = lowpass(signal_extracted, freq_end, "ImpulseResponse","auto");
% signal_extracted_flt = highpass(signal_extracted_flt, freq_start, "ImpulseResponse","auto");




figure(450)
plot(real(signal_extracted))


win_len = 800;
win = kaiser(win_len,20);
figure(500)
[sp,F,T] = stft(signal_extracted,prf, "FFTLength",800,"Window",win,"OverlapLength",round(win_len*0.99));
velocity = c*F/fc/2;
imagesc(T,velocity,db(sp))
colorbar
ax = gca;
ax.YDir = "normal";
xlabel("Time [s]")
ylabel("Doppler vel. [m/s]")
%% demodulacja
% phase = unwrap(angle(signal_extracted));
% phase_flt = lowpass(phase,0.03,"ImpulseResponse","fir");
% phase_diff = diff(phase_flt);

% [signal_filled, time_lags_filled] = fill_signal_gaps(signal_extracted, times_post_tx, times_post_rx, prf);
% [signal_filled, time_lags_filled] = expand_breaks(signal_extracted,prf,times_post_tx, times_post_rx);

% figure(991)
% plotZ(time_lags_filled, signal_filled)

lowpass_freq=500;
velocity = extract_heartbeat(signal_extracted,prf, fc, lowpass_freq);


[velocity_filled, time_lags_filled] = fill_signal_gaps(velocity, times_post_tx, prf);


figure(310)
plot(time_lags_filled, velocity_filled)
xlabel("Time [s]")
ylabel("Velocity [m/s]")

% figure(311)
% plot(phase_diff)