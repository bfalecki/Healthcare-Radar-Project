% this script can load signal recorded by record_signal.m
% and display its RT/RD maps, and also TF representation
% and slow-time phase

load("phaser_rec_19-Mar-2025_10-07-35_machanie_reka2.mat")

% breath2s.mat - 2s-nagranie oddechu - ok. 1 m od nadajnika/odbiornika

data = data1; % data1 / data2

c = physconst("LightSpeed");

% addpath(genpath("C:\Users\bfalecki\Documents\radarprfdetection\scripts"))
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

%% wydobycie jednowymiarowego przebiegu
range_cell = 8;

signal_extracted = RT(range_cell,:);

% signal_extracted_flt = highpass(signal_extracted, 0.02, "ImpulseResponse","fir");

% figure(450)
% plotxZ(signal_extracted)

win_len = 200;
win = gausswin(win_len,5);
figure(500)
[sp,F,T] = stft(signal_extracted,prf,"Window",win,"OverlapLength",round(win_len*0.9));
velocity = c*F/fc/2;
imagesc(T,velocity,db(sp))
ax = gca;
ax.YDir = "normal";
xlabel("Time [s]")
ylabel("Doppler vel. [m/s]")
%% demodulacja
phase = unwrap(angle(signal_extracted));
phase_diff = diff(phase);
figure(310)
plot(phase_diff)
