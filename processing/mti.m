function [filtered] = mti(signal)
%MTI Summary of this function goes here
%   Detailed explanation goes here
h = [1 -2 1];
filtered = fftfilt(h, signal);
end

