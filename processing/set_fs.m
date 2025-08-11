function [signal_resampled,actual_fs, t_resampled] = set_fs(signal,current_fs, desired_fs, accuracy)
%SET_FS resample of the signal to get desired sample frequency
% accuracy - maximum allowable relative error between actual_fs and desired_fs

% example
% signal = [1 2 3 4 5 6 7 8 9 10];
% current_fs = 10;
% desired_fs = 20;


if(~exist("accuracy", "var") || isempty(accuracy))
    accuracy = 0.01;
end

resample_factor = desired_fs/current_fs;


% keeping the lowest coefficient at least round(1/accuracy)
if(resample_factor > 1) % increasing fs
    Q = round(1/accuracy);
    P = round(Q * resample_factor);
else % decresaing fs
    P = round(1/accuracy);
    Q = round(P / resample_factor);
end

signal_resampled = resample(signal, P,Q);
actual_fs = current_fs * P/Q;

t_resampled = 0:1/actual_fs:(length(signal_resampled) / actual_fs);
t_resampled = t_resampled(1:length(signal_resampled));
end

