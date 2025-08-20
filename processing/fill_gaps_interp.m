function signal = fill_gaps_interp(signal,segments_idxes, method)
%FILL_GAPS_INTERP fills gaps in the signal by interpolation

% signal - signal to fill
% segments_idxes - binary segment idxes
% method - interpolation method (see interp1 documentation)

% calculate samples
signal_gaps_interp = interp1(find(segments_idxes), signal(segments_idxes), find(~segments_idxes), method);
% place interpolated samples
signal(~segments_idxes) = signal_gaps_interp;
% get rid of nan
signal(isnan(signal)) = signal(find(~isnan(signal), 1, "first"));

