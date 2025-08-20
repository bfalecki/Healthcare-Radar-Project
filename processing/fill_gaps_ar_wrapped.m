function signal = fill_gaps_ar_wrapped(signal,fs, segments_idxes,segment_duration, opts)
%FILL_GAPS_AR_WRAPPED 
% performs fill_gaps_ar on the signal based on the known segments idxes 
% signal - signal to analyze
% segments_idxes - known segments idxes (logical)
% fs - sampling frequency [Hz]
% segment_duration - signle segment duration [s]
% PartConsidered - fraction of the part considered for the
%       prediction 0 ... 1

arguments
    signal
    fs
    segments_idxes
    segment_duration
    opts.PartConsidered = 1
end


% First, we need to put nan instead of breaks
signal(~segments_idxes) = nan;

% then cut first break
after_break_idx = find(~isnan(signal), 1,"first");
signal = signal(after_break_idx:end);


%  AR model fit
p = segment_duration * fs * opts.PartConsidered; % part of segment
p = round(p);
p_max_possible = find(isnan(signal), 1,"first") - 1;
p(p > p_max_possible) = p_max_possible;
signal = fill_gaps_ar(signal, p);

% restore first break
signal = [zeros( after_break_idx-1,1); signal];


end

