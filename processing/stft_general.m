function [sp,f_ax,t_ax,fs_stft,overlap_len_original_fs] = stft_general(signal,SamplingFrequency,opts)
%STFT_GENERAL 
% Calculate short time Fourier transform of the signal

arguments
    signal % signal for analysis
    SamplingFrequency % Sampling frequency of the signal [Hz]
    opts.MaximumVisibleFrequency = SamplingFrequency/2; % Maximum visible
            % frequency on the distribution [Hz]
    opts.FrequencyResolution = SamplingFrequency/200; % Desired frequency resoultion [Hz]
    opts.WindowWidth = 0.1*length(signal)/SamplingFrequency; % FWHM of the gaussian window function [s]
    opts.DesiredTimeRes = 1/SamplingFrequency % desired time cell size [s]
end

% original_signal_length = length(signal);
[signal, new_fs] = set_fs(signal, SamplingFrequency, opts.MaximumVisibleFrequency*2);


% window calculation
window = get_gauss_win_stft(opts.WindowWidth,new_fs, opts.FrequencyResolution);

% overlap length calculation
overlap_len = getSTFTOverlapLen(opts.DesiredTimeRes,length(window),new_fs);

% helpful in exact bounds determination
overlap_len_original_fs = overlap_len / new_fs * SamplingFrequency;

% padd signal in the end
signal = padarray(signal(:), round(length(window)/2), "post");

% stft calculation
[sp, f_ax, t_ax] = stft(signal, new_fs, "Window",window,"OverlapLength",overlap_len);

fs_stft = 1/(t_ax(2) - t_ax(1)); % time step of the STFT

end

