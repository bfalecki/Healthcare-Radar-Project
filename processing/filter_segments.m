function [filtered, new_segment_idxes_starts,new_segment_idxes_ends] = filter_segments(signal,segment_idxes_starts,...
    segment_idxes_ends,cutoff_freq, filter_type, cut_samples)
%FILTER_SEGMENTS 
% filter each segment of the signal separately

% signal - analyzed signal
% segment_idxes_starts - starts of segmnets in samples
% segment_idxes_ends - ends of segments in samples
% cutoff_freq - cut-off frequnecy (normalized to 0 ... 1)
% filter_type - "highPass" / "LowPass"
% cut_samples cut filter edge-effects samples

if(~exist("cut_samples", "var") || isempty(cut_samples))
    cut_samples = 0;
end

filtered = zeros(size(signal));
new_segment_idxes_starts = segment_idxes_starts + cut_samples;
new_segment_idxes_ends = segment_idxes_ends - cut_samples;

for k = 1:length(segment_idxes_starts)
    idxes = segment_idxes_starts(k):segment_idxes_ends(k);
    idxes = idxes(idxes <= length(signal));
    % anly this part is placed
    idxes_cut = new_segment_idxes_starts(k):new_segment_idxes_ends(k);
    idxes_cut = idxes_cut(idxes_cut <= length(signal));
    idxes_cut_local = idxes_cut - idxes(1) + 1;
    if(filter_type == "HighPass")
        fragment_filt = highpass(signal(idxes),cutoff_freq);
    elseif(filter_type == "LowPass")
        fragment_filt = lowpass(signal(idxes),cutoff_freq);
    elseif(filter_type == "FitSin")
        ampl0 = max(signal(idxes)) - min(signal(idxes));
        freq0 = cutoff_freq; % normalized
        phase_offset0 = 0;
        val_offset0 = mean(signal(idxes));
        p0 = [ampl0 freq0 phase_offset0 val_offset0];
        fragment_filt = fit_sin(signal(idxes),p0);
    else
        error("Unsupported filter_type: " + filter_type)
    end
    filtered(idxes_cut) = fragment_filt(idxes_cut_local);
end

end

