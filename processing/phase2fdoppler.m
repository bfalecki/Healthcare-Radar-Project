function [fd] = phase2fdoppler(phase, fs)
%PHASE2FDOPPLER Summary of this function goes here
fd = 1/(2*pi)*compl_diff(diff(phase))*fs;  % compl_diff just to have the same size
end

