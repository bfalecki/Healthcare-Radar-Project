% this script is used for the determination of detectability of the micro-Doppler signatures
% based on the radar parameters

% VITAL SIGNS
%
% Breath modeled as a sinusoid
f_breath = 0.3; % breath frequnecy [Hz]
displ_max_breath = 10e-3; % maximum breath-related displacements [m]
v_max_breath = displ_max_breath*2*pi*f_breath; % maximum breath-related velocity [m/s]
%
% Heartbeat modeles as a sinusoid with cyclically varying envelope
f_heart = 1.2; % heart cycles frequency [Hz] 
f_heart_osc = 8; % heartbeat-related oscillation frequency within heart cycle [Hz]
displ_max_heart = 0.1e-3; % maximum heartbeat-related displacements [m]
v_max_heart = displ_max_heart * 2*pi * f_heart_osc; % maximum heartbeat-related velocity [m/s]

% RADAR parameters
c = physconst("LightSpeed");
fc = 10e9; % carrier frequency [Hz]
lambda = c/fc; % wavelength [m]
<<<<<<< HEAD
PRF = 2000; % pulse repetition frequency [Hz]
SNR = 40; % signal-to-noise ratio [dB]
=======
PRF = 10000; % pulse repetition frequency [Hz]
SNR = 10; % signal-to-noise ratio [dB]
>>>>>>> ed1d475cbaf51a25fe97a40435b673fd80c4ea43
max_fd = PRF/2; % max unambiguous Doppler frequency [Hz]
max_vd = max_fd/fc * c/2; % max unambiguous Doppler velocity [m/s]

% signal simulation
t_max = 10; % simulation time
t = 0:1/PRF:t_max;

breath_signal_displ = displ_max_breath*sin(2*pi*f_breath*t); % displacement signal of breath separated
breath_signal_vel = v_max_breath*cos(2*pi*f_breath*t); % velocity signal of breath

heartbeat_envelope = displ_max_heart*sin(2*pi*f_heart*t);
heartbeat_envelope = heartbeat_envelope.*(heartbeat_envelope > 0); % regarding only positive envelope values
% displacement signal of heartbeat
heartbeat_signal_displ = sin(2*pi*f_heart_osc*t) .* heartbeat_envelope;
% velocity signal of heartbeat
heartbeat_signal_vel = cos(2*pi*f_heart_osc*t) .* heartbeat_envelope/displ_max_heart*v_max_heart;

% connected signals
vital_signs_signal_vel = heartbeat_signal_vel + breath_signal_vel;
vital_signs_signal_displ = heartbeat_signal_displ + breath_signal_displ;

fd_signal = -2*vital_signs_signal_vel/c * fc; % Doppler frequency signal [Hz]
phase_signal = -4*pi*vital_signs_signal_displ/lambda; % phase of the signal [rad]
% radar complex signal in baseband (single range cell)
radar_signal_raw = awgn(exp(1j*phase_signal), SNR);

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
set(gca,'YDir','normal')


%% extraction of the signal
phase_extr = unwrap(angle(radar_signal_raw));
fd_extr = phase2fdoppler(phase_extr, PRF);
vd_extr = fdoppler2vel(fd_extr,fc);

decim_rank = floor(PRF/500);
vd_extr_decim = resample(vd_extr, 1,decim_rank);

% reducing bandwidth to gain SNR
<<<<<<< HEAD
lowpass_freq = 50; % Hz
highpass_freq = 5; % Hz
=======
lowpass_freq = 15; % Hz
% highpass_freq = 5; % Hz
>>>>>>> ed1d475cbaf51a25fe97a40435b673fd80c4ea43
vd_extr_filt = lowpass(vd_extr_decim, lowpass_freq/PRF*decim_rank, "ImpulseResponse","iir");
% vd_extr_filt = highpass(vd_extr_filt, highpass_freq/PRF*decim_rank, "ImpulseResponse","iir");


% extracted vs input
figure(2)
plot(t, [vital_signs_signal_vel; [resample(vd_extr_filt, decim_rank, 1) 0]])
legend("Input", "Extracted")



