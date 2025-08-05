function [fd] = phase2fdoppler(phase, fs)
%PHASE2FDOPPLER Summary of this function goes here
fd = 1/(2*pi)*diff(phase)*fs;
fd(end+1) = fd(end); % just to have the same size
end

