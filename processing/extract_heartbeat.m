function velocity = extract_heartbeat(range_time_row,PRF, fc, lowpass_freq)
%EXTRACT_HEARTBEAT Summary of this function goes here
%   Detailed explanation goes here
phase_extr = unwrap(angle(range_time_row));
fd_extr = phase2fdoppler(phase_extr, PRF);
vd_extr = fdoppler2vel(fd_extr,fc);

decim_rank = floor(PRF/500);
decim_rank(decim_rank == 0) = 1;
vd_extr_decim = resample(vd_extr, 1,decim_rank);

% reducing bandwidth to gain SNR
% lowpass_freq = 20; % Hz
% highpass_freq = 5; % Hz
% velocity = lowpass(vd_extr_decim, lowpass_freq/PRF*decim_rank, "ImpulseResponse","iir");
% vd_extr_filt = highpass(vd_extr_filt, highpass_freq/PRF*decim_rank, "ImpulseResponse","iir");

velocity = vd_extr_decim;
end

