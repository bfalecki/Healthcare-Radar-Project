function filtered = filter_segments(signal,segment_idxes_starts,...
    segment_idxes_ends,cutoff_freq, filter_type)
%FILTER_SEGMENTS 
% filter each segment of the signal separately

% signal - analyzed signal
% segment_idxes_starts - starts of segmnets in samples
% segment_idxes_ends - ends of segments in samples
% cutoff_freq - cut-off frequnecy (normalized to 0 ... 1)
% filter_type - "highPass" / "LowPass"

filtered = zeros(size(signal));

for k = 1:length(segment_idxes_starts)
    idxes = segment_idxes_starts(k):segment_idxes_ends(k);
    idxes = idxes(idxes <= length(signal));
    if(filter_type == "HighPass")
        fragment_filt = highpass(signal(idxes),cutoff_freq);
    elseif(filter_type == "LowPass")
        fragment_filt = lowpass(signal(idxes),cutoff_freq);
    else
        error("Unsupported filter_type: " + filter_type)
    end
    filtered(idxes) = fragment_filt;
end

end

