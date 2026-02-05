function [signal,p] = fill_gaps_ar_wrapped(signal,fs, segments_idxes,segment_duration, opts)
%FILL_GAPS_AR_WRAPPED 
% performs fill_gaps_ar on the signal based on the known segments idxes 
% signal - signal to analyze
% segments_idxes - known segments idxes (logical)
% fs - sampling frequency [Hz]
% segment_duration - signle segment duration [s]
% PartConsidered - fraction of the part considered for the
%       prediction 0 ... 1

% output:
% signal - predicted
% p - assumed history size

arguments
    signal
    fs
    segments_idxes
    segment_duration
    opts.PartConsidered = 1
    opts.bidirectional = 0
    opts.edge_ignore_length = 0; % discard N samples form prediction on ends and begginings of segments
end

% discard edge samples
segments_idxes = side_by_side_vector_erose(segments_idxes, opts.edge_ignore_length);

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
if(opts.bidirectional)
    signal = fill_gaps_ar_bidirectional(signal, p);
else
    signal = fill_gaps_ar(signal, p);
end


% restore first break
signal = [zeros( after_break_idx-1,1); signal];


end

