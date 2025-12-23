% this script can load signal recorded by record_signal.m
% and display its RT/RD maps, and also TF representation
% and slow-time phase
clear data data1 data2
load("rec"+filesep+"phaser_rec_11-Jun-2025_14-08-17_max1mps.mat")

% breath2s.mat - 2s-nagranie oddechu - ok. 1 m od nadajnika/odbiornika

if(~exist("data", "var"))
    data = data1; % data1 / data2
end

% w = [0.8; exp(1j*2*pi * 0.5)];
% w = [0 1];
% w = loadCalibrationWeights().DigitalWeights;
% data = data1*conj(w(1)) + data2*conj(w(2));



c = physconst("LightSpeed");

% addpath(genpath("Phaser-Control-with-MATLAB")) % <-- path to https://github.com/mathworks/Phaser-Control-with-MATLAB/tree/main



%% Create a range doppler plot
rd = phased.RangeDopplerResponse(DopplerOutput="Speed",...
    OperatingFrequency=fc,SampleRate=fs,RangeMethod="FFT",...
    SweepSlope=sweepslope,PRFSource="Property",PRF=prf);
[RDresp_matr,rnggrid,dopgrid] = rd(data);
axes(figure)
rd_out = rd.plotResponse(data);
ax = gca;
xlim(ax,[-maxSpeed,maxSpeed]); ylim(ax,[0,maxRange]);

%% wybór wiersza mapy RT

RT = fft(data);
RD = fftshift(fft(RT,[], 2),2);
% figure(23)
% imagesc(db(RD(1:20,:)))
% ax = gca;
% ax.YDir = "normal";

rnggrid_fixed = ifftshift(rnggrid);
figure(24)
limit_rng = 20;
imagesc(dopgrid, rnggrid_fixed(1:limit_rng),db(RD(1:limit_rng,:)))
ax = gca;
ax.YDir = "normal";
colorbar

figure(22)
imagesc(db(RT(1:20,:)))
ax = gca;
ax.YDir = "normal";
colorbar




%% wydobycie jednowymiarowego przebiegu I/Q
range_cell = 11;

signal_extracted = RT(range_cell,:);


figure(450)
[signal_filled, time_lags_filled, segment_duration, start_samples, end_samples] = ...
    fill_signal_gaps(signal_extracted, times_post_tx, prf);
plot(time_lags_filled, [real(signal_filled).' imag(signal_filled).'])
xlims = [time_lags_filled(1) time_lags_filled(end)];
xlabel("Time [s]")
ylabel("Signal amplitude [-]")
legend("Real part", "Imag. part")
xlim(xlims)
title("Raw I/Q signal")

%% demodulacja fazy
phase = unwrap(angle(signal_filled));

[phase] = reset_accumulated_phase(phase,start_samples,end_samples);
% phase(phase==0) = nan;

figure(21)
plot(time_lags_filled, phase)
xlabel("Time [s]")
ylabel("Unwrapped phase [rad]")
xlim(xlims)


%% Dodatkowo zmiana na przemieszczenie i prędkość
figure(211)
displacement = phase2displ(phase, fc);
plot(time_lags_filled, displacement*1e3)
xlabel("Time [s]")
ylabel("Displacement [mm]")
xlim(xlims)

ylim_vel = [-20 20]; % mm/s

figure(212)
fdoppler = phase2fdoppler(phase, prf);
velocity = fdoppler2vel(fdoppler,fc);
plot(time_lags_filled, velocity*1e3)
xlabel("Time [s]")
ylabel("Velocity [mm/s]")
title("Raw velocity")
xlim(xlims)
ylim(ylim_vel)

%% filtering

velocity_filt = medfilt1(velocity,3);
velocity_filt = lowpass(velocity_filt, 0.2);
figure(2121)
plot(time_lags_filled, velocity_filt*1e3)
xlabel("Time [s]")
ylabel("Velocity [mm/s]")
title("Filtered velocity")
xlim(xlims)
ylim(ylim_vel)

%% heartbeat high-pass filtering
velocity_filt_hb = highpass(velocity_filt, 0.08);
figure(21211)
plot(time_lags_filled, velocity_filt_hb*1e3)
xlabel("Time [s]")
ylabel("Velocity [mm/s]")
title("Heartbeat velocity")
xlim(xlims)
ylim([-10 10])


%% heartbeat envelope
hb_envelope = envelope(velocity_filt_hb, round(0.2*prf),"rms");
figure(21211)
hold on
plot(time_lags_filled, hb_envelope*1e3, LineWidth=2)
hold off
legend("Heartbeat velocity", "RMS envelope")
%% Heartrate - FFT spectrum
figure(212111)
% pspectrum(hb_envelope, prf, "power", "FrequencyLimits",[0 5]);

hb_envelope_fixed = hb_envelope - mean(hb_envelope);

hb_env_spectrum = fft(hb_envelope_fixed, 4*length(hb_envelope_fixed));
f_ax = linspace(0, prf, length(hb_env_spectrum));
plot(f_ax, abs(hb_env_spectrum))
xlim([0 5])
title("Heartbeat envelope FFT")
xlabel("Frequency [Hz]")
ylabel("Amplitude")

%% respiratory rate - FFT spectrum

figure(2111)
displacement_fixed = displacement - mean(displacement);
displacement_spectrum = fft(displacement_fixed, 4*length(displacement_fixed));
f_ax = linspace(0, prf, length(displacement_spectrum));
plot(f_ax, abs(displacement_spectrum))
xlim([0 1])
title("Displacement FFT")
xlabel("Frequency [Hz]")
ylabel("Amplitude")


% phase_flt = lowpass(phase,0.03,"ImpulseResponse","fir");
% phase_diff = diff(phase_flt);

% [signal_filled, time_lags_filled] = expand_breaks(signal_extracted,prf,times_post_tx, times_post_rx);

% figure(991)
% plotZ(time_lags_filled, signal_filled)

% lowpass_freq=4;
% velocity = extract_heartbeat(signal_extracted,prf, fc, lowpass_freq);
% 
% [velocity_filled, time_lags_filled] = fill_signal_gaps(velocity, times_post_tx, prf);
% % 
% figure(310)
% plot(time_lags_filled, velocity_filled)
% xlabel("Time [s]")
% ylabel("Velocity [m/s]")

% figure(311)
% plot(phase_diff)

%%


% freq_start = 0.03;
% freq_end = 0.03;
% 
% signal_extracted_flt = lowpass(signal_extracted, freq_end, "ImpulseResponse","auto");
% signal_extracted_flt = highpass(signal_extracted_flt, freq_start, "ImpulseResponse","auto");


% win_len = 10;
% win = kaiser(win_len,20);
% figure(500)
% [sp,F,T] = stft(signal_extracted,prf, "FFTLength",800,"Window",win,"OverlapLength",round(win_len*0.90));
% velocity = c*F/fc/2;
% imagesc(T,velocity,db(sp))
% colorbar
% ax = gca;
% ax.YDir = "normal";
% xlabel("Time [s]")
% ylabel("Doppler vel. [m/s]")

% %% synchrosqueezing
% [sst,f_sst,t_sst] = fsst(padarray(signal_extracted.', 1000), prf, padarray(win, 1000), "yaxis");
% velocity_sst = -c*f_sst/fc/2;
% figure(111)
% imagesc(t_sst,velocity_sst,abs(sst))

