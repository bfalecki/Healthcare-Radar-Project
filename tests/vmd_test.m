

signal_source = "simulation"; % "measurement" / "simulation"

% actual measurement
if(signal_source == "measurement")
    rec_file = load("rec"+filesep+"phaser_rec_11-Jun-2025_14-08-17_max1mps.mat");
    RT = fft(rec_file.data1);
    PRF = rec_file.prf;
    [radar_signal_raw, RT_row] = choose_RT_row(RT);
end



% simulation
if(signal_source == "simulation")
    PRF = 133;
    fc = 10e9;
    VSSim = VitalSignsSimulator("SNR", 30, "PRF", PRF, 'CarrierFrequency', fc);
    [radar_signal_raw, t] = VSSim.simulate();
    % when SNR is 22 dB, we can mostly estimate heart rate with this method
    % when SNR is -5 dB, we can estimate breath rate quite good with this method
end

%% preprocessing - decimation
desired_fs = 30; % We want to have a sampling frequency not to high to filter out high-frequency noise,
% but not too low in order to capture heart oscilations
% desired_fs should be 2x greater than typical heart oscillation frequency (about 8 Hz)

%% currently works only in simulation
[radar_signal, actual_fs, t_resampled] = set_fs(radar_signal_raw, PRF, desired_fs);

% phase difference extraction
signal = compl_diff(diff(unwrap(angle(radar_signal))));

% % signal = signal_filled;
% [signal, actual_fs, t_resampled] = set_fs(signal, PRF, desired_fs);


[imf,~, info] = vmd(signal, "NumIMFs",2); % only two components: breath and heartbeat
disp(info.CentralFrequencies * actual_fs)

xlims = [1500 2400];
fig_size = [0 0.5 1, 0.3];

idxes_to_plt = info.CentralFrequencies * actual_fs < 10; % We want to see the components with freq. less than 20 Hz

close all

% 
% for k = find(idxes_to_plt).'
%     figure(k)
%     plot(imf(:, k))
%     setFigSize(fig_size)
%     % xlim(xlims)
% end


figure(50)
plot(t_resampled, signal)
setFigSize(fig_size)
% xlim(xlims)
% ylim([-0.015 0.015])

%% heartbeat envelope
% we assume, that the first component is heartbeat, and the second is
% breath

[~,hb_idx] = min(abs(info.CentralFrequencies * actual_fs - 8));
heartbeat_signal = imf(:, hb_idx);


env_window_width = 0.1; % seconds
env_window_length = round(env_window_width * actual_fs);
hb_envelope = envelope(heartbeat_signal, env_window_length,"rms");

figure(1)
plot(t_resampled, heartbeat_signal)
hold on
plot(t_resampled, hb_envelope, LineWidth=2)
hold off
setFigSize(fig_size)

%% envelope analysis

% decimation
hb_env_des_fs = 5; % more than 2x possible heart rate
[hb_envelope_dec, hb_env_fs] = set_fs(hb_envelope, actual_fs, hb_env_des_fs);

hp_freq = 0.6; % less than 0.5 Hz is removed
hb_envelope_no_offset = highpass(hb_envelope_dec, hp_freq/hb_env_fs);



% %% stft approach (faster)
% 
% env_spectr_win_width = 2; % seconds
% env_spectr_win = get_gauss_win(env_spectr_win_width, hb_env_fs, 1);
% t_step = 1; % s
% win_duration = length(env_spectr_win) / hb_env_fs;
% overlap_ratio = (win_duration - t_step) / win_duration;
% overlap_length = round(win_duration * overlap_ratio);
% [env_stft, f_ax, t_ax] = stft(hb_envelope_no_offset, hb_env_fs, "Window",env_spectr_win, "OverlapLength",overlap_length);
% figure(2)
% imagesc(t_ax, f_ax, db(env_stft))
% set(gca, 'YDir', 'normal')


%% fsst approach (more precise)

env_spectr_win_width = 4; % seconds of window applied to envelope signal
freq_per_sample = 0.01; % how precise the distribution needs to be
win_length = round(hb_env_fs/freq_per_sample);
win_duration = win_length/hb_env_fs; % duration of entire window [s]
width_factor = env_spectr_win_width/win_duration; % part of window belonging to FWHM
fsst_window = gausswin(win_length,2.354/2/width_factor);

        
if(length(hb_envelope_no_offset) < length(fsst_window)) % preventing fsst error
    hb_envelope_no_offset = padarray(hb_envelope_no_offset, length(fsst_window) - length(hb_envelope_no_offset), "post");
end

[synchrosqueezed_hb_env, f_ax,t_ax] = fsst(hb_envelope_no_offset,hb_env_fs, fsst_window);
time_idxes = t_ax <= length(radar_signal_raw)/PRF;
t_ax = t_ax(time_idxes);
synchrosqueezed_hb_env = synchrosqueezed_hb_env(:,time_idxes);


% find tfridge
f_low_hb_exp = 0.5; % minimum heart rate expected
f_high_hb_exp = 2.5; % maximum heart rate expected
f_ax_idxes = f_ax <= f_high_hb_exp & f_ax >= f_low_hb_exp;
f_ax = f_ax(f_ax_idxes);
synchrosqueezed_hb_env = synchrosqueezed_hb_env(f_ax_idxes,:);
ridge = tfridge(synchrosqueezed_hb_env,f_ax, 1, "NumRidges",1);

% plotResult
figure(21)
imagesc(t_ax,f_ax,abs(synchrosqueezed_hb_env))
colorbar
ax = gca;
ax.YDir = "normal";
hold on
plot(t_ax, ridge, "LineWidth",2, "Color","r")
hold off
title("Heart Rate [Hz]")

%% breath rate extraction
breath_signal = imf(:, end);
figure(3)
plot(t_resampled, breath_signal)

% decimation
breath_des_fs = 3; % more than 2x possible breath rate (2x ~ 1.5 Hz = 3 Hz)
[breath_dec, breath_env_fs] = set_fs(breath_signal, actual_fs, breath_des_fs);

hp_freq_breath = 0.1; % less than 0.1 Hz is removed
breath_no_offset = highpass(breath_dec, hp_freq_breath/breath_env_fs);

breath_spectr_win_width = 4; % seconds of window applied to envelope signal
breath_freq_per_sample = 0.02; % how precise the distribution needs to be
breath_win_length = round(breath_env_fs/breath_freq_per_sample);
breath_win_duration = breath_win_length/breath_env_fs; % duration of entire window [s]
breath_width_factor = breath_spectr_win_width/breath_win_duration; % part of window belonging to FWHM
breath_fsst_window = gausswin(breath_win_length,2.354/2/breath_width_factor);

        
if(length(breath_no_offset) < length(breath_fsst_window)) % preventing fsst error
    breath_no_offset = padarray(breath_no_offset, length(breath_fsst_window) - length(breath_no_offset), "post");
end

[synchrosqueezed_breath, breath_f_ax,breath_t_ax] = fsst(breath_no_offset,breath_env_fs, breath_fsst_window);
breath_time_idxes = breath_t_ax <= length(radar_signal_raw)/PRF;
breath_t_ax = breath_t_ax(breath_time_idxes);
synchrosqueezed_breath = synchrosqueezed_breath(:,breath_time_idxes);


% find tfridge
f_low_breath = 0.1; % minimum breath rate expected
f_high_breath = 1.5; % maximum breath rate expected
f_ax_idxes_breath = breath_f_ax <= f_high_breath & breath_f_ax >= f_low_breath;
breath_f_ax = breath_f_ax(f_ax_idxes_breath);
synchrosqueezed_breath = synchrosqueezed_breath(f_ax_idxes_breath,:);
breath_ridge = tfridge(synchrosqueezed_breath,breath_f_ax, 1, "NumRidges",1);

% plotResult
figure(22)
imagesc(breath_t_ax,breath_f_ax,db(synchrosqueezed_breath))
colorbar
ax = gca;
ax.YDir = "normal";
hold on
plot(breath_t_ax, breath_ridge, "LineWidth",2, "Color","r")
hold off
title("Breath Rate [Hz]")