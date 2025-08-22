function [placed, max_gap] = placeNans_RN(signal,start_samples, end_samples)
%PLACENANS_RN

% Place NaN values instead of values in breaks (for the interpolation purposes)
% Interior of the function by Rafał Najda

% signal - signal to place NaNs
% start_samples - vector with starts of the segments (in sample idx)
% end_samples - vector with ends of the segments (in sample idx)

% max_gap - maximum gap that can be filled

% Wyypelnienie przerw NaN do interpolacji
placed = signal;
num_segments = length(start_samples);
max_gap = 0;
for i = 1:num_segments-1
    gap_start = end_samples(i) + 1;
    gap_end = start_samples(i+1) - 1;
    if gap_start <= gap_end
        max_gap = max(max_gap, gap_end-gap_start);
        % #### - RN gap_end+1 ze wzgledu na to ze pierwsza probka często
        % jest zawyzona/zanizona i wporwadza bledy w interpolacji
        placed(gap_start:(gap_end+1)) = NaN;  % Complex NaN
    end
end
end

