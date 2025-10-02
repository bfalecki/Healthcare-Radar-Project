function [HR_envelope] = generate_HR_envelope(heart_f,cycle_width, len, fs)
%GENERATE_ENVELOPE Generate envelope for heart S1 cycles

% cycle_width = 0.2; % FWHM [s]
% heart_f = 1.1; % S1-S1 interval
% fs = 133; % sampling freq [Hz]
% len = fs*8; % number of samples

% first, we need to generate cycle positions
base = zeros(1, len);
interval = 1/heart_f;

full_len_s = len / fs;
positions_s = 0:interval:full_len_s;
positions_samples =  round(positions_s * fs);
positions_samples(positions_samples > len) = len;
positions_samples(positions_samples == 0) = 1;
base(positions_samples) = 1;

% now we need to generate gaussian window
window = get_gauss_win(cycle_width, fs);

% and distribute it in the signal
HR_envelope = fftfilt(window, base);

end

