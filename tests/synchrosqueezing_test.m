% test of the synchrosqueezing-based vital signs visualization


% simulation
PRF = 133;
fc = 10e9;
VSSim = VitalSignsSimulator("SNR", 25, "PRF", PRF, 'CarrierFrequency', fc);
[radar_signal_raw, t] = VSSim.simulate();

% with SNR=25 dB and PRF = 133,
% and processing parameters:
    % min_allowable_PRF = 25;
    % win_width = 0.08;
    % velocity_per_sample = 0.0002;
% simluated heart oscillations were still somehow visible against the noise


max_vel = -fdoppler2vel(PRF/2,fc);
max_vel_expected = 0.05; % to set ylim on plot
decim_rank = floor(max_vel/max_vel_expected);
decim_rank(decim_rank == 0) = 1;
min_allowable_PRF = 25; % [Hz], heartbeat oscillations have about 8 Hz, so decimation cannot be very high
                        % Smaller MinAllowablePRF value -> method seems to
                        % be more robust to noise, but too small can
                        % produce artifacts on heartbeat waveform
decim_rank_max = floor(PRF/min_allowable_PRF);
decim_rank_max(decim_rank_max == 0) = 1;
decim_rank(decim_rank > decim_rank_max) = decim_rank_max;


PRF_decim = PRF/decim_rank;
% PRF_decim = PRF;

win_width = 0.08; % window FWHM [s], ideally, it should be less than half of period of 8 Hz fast heartbeat oscillations, i.e. 0.05 s,
                % but in low-SNR, a bit longer window width can help
velocity_per_sample = 0.0002; % velocity per sample on spectrogram [m/s]. Typically, heartbeat velocity is of amplitude of 0.005 m/s, 
                            % so the velocity resolution must be smaller
freq_per_sample = -vel2fdoppler(velocity_per_sample, fc);
win_length = round(PRF_decim/freq_per_sample);
win_duration = win_length/PRF_decim; % duration of entire window [s]
width_factor = win_width/win_duration; % part of window belonging to FWHM
window = gausswin(win_length,2.354/2/width_factor);


radar_signal_processed = decimate(radar_signal_raw, decim_rank);
if(length(radar_signal_processed) < length(window)) % preventing fsst error
    radar_signal_processed = padarray(radar_signal_processed.', length(window) - length(radar_signal_processed), "post").';
end

figure(4)
[synchrosqueezed, f_ax,t_ax] = fsst(radar_signal_processed,PRF_decim, window);
vel_ax = fdoppler2vel(f_ax, fc);
time_idxes = t_ax <= length(radar_signal_raw)/PRF;
t_ax_cut = t_ax(time_idxes);
imagesc(t_ax_cut,vel_ax,db(synchrosqueezed(:,time_idxes)))
ylim([-max_vel_expected max_vel_expected])