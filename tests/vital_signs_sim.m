% this script is used for the determination of detectability of the micro-Doppler signatures
% based on the radar parameters

PRF = 100;
fc = 10e9;
c = physconst('lightspeed');
VSSim = VitalSignsSimulator("SNR", 10, "PRF", PRF, 'CarrierFrequency', fc);
[radar_signal_raw, t] = VSSim.simulate();


%% plot simulated signal
% figure(1)
% plot(t, [real(radar_signal_raw); imag(radar_signal_raw)])
% legend("Re","Im")
% title("Raw baseband signal")
% xlabel("time [s]")

% spectrogram
win_width = 0.2; % window FWHM [s]
win_margin = 4; % x times FWHM each side
window = get_gauss_win(win_width, PRF, win_margin);
overlap_factor = 0.99;
[raw_stft,F_ax,T_ax] = stft(radar_signal_raw, PRF,"Window",window,"OverlapLength",round(overlap_factor*length(window)));
figure(20)
V_ax = -F_ax/2*c/fc;
imagesc(T_ax,V_ax,db(raw_stft));
hc = colorbar;
set(gca,'YDir','normal')



%% extraction of the signal
phase_extr = unwrap(angle(radar_signal_raw));
fd_extr = phase2fdoppler(phase_extr, PRF);
vd_extr = fdoppler2vel(fd_extr,fc);

decim_rank = floor(PRF/500);
decim_rank(decim_rank==0) = 1;
vd_extr_decim = resample(vd_extr, 1,decim_rank);

% reducing bandwidth to gain SNR
lowpass_freq = 50; % Hz
highpass_freq = 5; % Hz

vd_extr_filt = lowpass(vd_extr_decim, lowpass_freq/PRF*decim_rank, "ImpulseResponse","iir");
vd_extr_filt = highpass(vd_extr_filt, highpass_freq/PRF*decim_rank, "ImpulseResponse","iir");

vd_extr_filt_adj = resample(vd_extr_filt, decim_rank, 1);
if(length(vd_extr_filt_adj)>length(t))
    vd_extr_filt_adj = vd_extr_filt_adj(1:length(t));
else
    vd_extr_filt_adj = [vd_extr_filt_adj zeros(1, length(t) - length(vd_extr_filt_adj))];
end


% extracted vs input
figure(2)
% plot(t, vital_signs_signal_vel)
% hold on
plot(t, vd_extr_filt_adj)
% hold off
% legend("Input", "Extracted")
xlabel("Time [s]")
ylabel("Velocity [m/s]")


%% synchrosqueezing

figure(4)
% synchrosqueezed = fsst(decimate(radar_signal_raw, 20),PRF/20, get_gauss_win(win_width, PRF/20, win_margin));
% imagesc(db(synchrosqueezed))

rzad  = 1;
sigma = 4;
gamma_K = 1e-4;
NFFT = 2024;
method = 'FFT';
x.fs = PRF/5;              % szybkosc probkowania
x.signal =decimate(radar_signal_raw, 5);
x.N = length(x.signal);   % dlugosc sygnalu
x.T = x.N/x.fs;                % czas trwania sygnalu

S = Gab_STFT(x, NFFT, sigma, gamma_K, 0, method);
IFreq = Gab_Get_IFreq_Est(rzad,x, NFFT, sigma,  gamma_K, 0, method);
SE = Gab_TF_V_Synchrosqueezing(S, IFreq,  'FFT');
% Plot_Energy(SE, threshold, 0, t_scale, f_scale, fontsize, img_max_size); % wyswietlamy spektrogram
% title("synchrosqueezing wertykalny 2. rzedu")
imagesc(db(SE))
setFigSize("half A4")
xlabel("Time [s]")
ylabel("Doppler freq. [Hz]")

ridge = tfridge(SE, 1:size(SE,1), 1);
% hold on
figure(5)
plot( 1:size(SE,2), -ridge)
