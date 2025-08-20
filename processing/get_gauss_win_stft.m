function window = get_gauss_win_stft(width,fs, freq_res)
%GET_GAUSS_WIN_STFT 
% computes gaussian window for stft or fsst

% width - FWHM of the window [s]
% fs - sampling frequency of the window [Hz]
% freq_res - frequency cell size on the TF distribution [Hz]

win_length = round(fs/freq_res);
win_duration = win_length / fs;  % duration of entire window [s]
width_factor = width/win_duration; % part of window belonging to FWHM
window = gausswin(win_length,2.354/2/width_factor); % calculated window
end

