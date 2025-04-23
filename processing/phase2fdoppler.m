function [fd] = phase2fdoppler(phase, fs)
%PHASE2FDOPPLER Summary of this function goes here
fd = 1/(2*pi)*diff(phase)*fs;
end

