function overlap_len = getSTFTOverlapLen(time_res,win_len,fs)
%GETSTFTOVERLAPLEN Summary of this function goes here
%   Detailed explanation goes here
% time_res [s]; resolution of the STFT distribution 
% win_len ; length(window) - in samples
% fs ; sampling frequnecy

% window_duration = win_len/fs; % duration of the window [s]
step_samples = floor(time_res * fs); % step samples
step_samples(step_samples == 0) = 1;

% final overlap
overlap_len = win_len - step_samples;
overlap_len(overlap_len < 1) = 1;
end

