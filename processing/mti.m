function [filtered] = mti(signal)
%MTI - Moving Target Indication Filtering
h = [1 -2 1];
filtered = fftfilt(h, signal);
end

