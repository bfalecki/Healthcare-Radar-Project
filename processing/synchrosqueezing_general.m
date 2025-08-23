function [synchrosqueezed,f_ax,t_ax] = synchrosqueezing_general(signal,SamplingFrequency,opts)
%SYNCHROSQUEEZING_GENERAL 
% synchrosqueezing short time fourier transform calculation with frequency resolution
% control

arguments
    signal % signal for analysis
    SamplingFrequency % Sampling frequency of the signal [Hz]
    opts.MaximumVisibleFrequency = SamplingFrequency/2 % Maximum visible
            % frequency on the distribution [Hz]
    opts.FrequencyResolution = SamplingFrequency/200 % Desired frequency resoultion [Hz]
    opts.WindowWidth = 0.1*length(signal)/SamplingFrequency % FWHM of the gaussian window function [s]
end

original_signal_length = length(signal);
[signal, new_fs] = set_fs(signal, SamplingFrequency, opts.MaximumVisibleFrequency*2);

window = get_gauss_win_stft(opts.WindowWidth,new_fs, opts.FrequencyResolution);
        
if(length(signal) < length(window)) % preventing fsst error
    signal = signal(:);
    signal = padarray(signal, length(window) - length(signal), "post");
end

% synchrosqueezing calculation
[synchrosqueezed, f_ax,t_ax] = fsst(signal,new_fs, window);
% we must to cut the unused part of the distribution (in most cases it is relatively large)
time_idxes = t_ax <= original_signal_length/SamplingFrequency;
t_ax = t_ax(time_idxes);
synchrosqueezed = synchrosqueezed(:,time_idxes);

end

