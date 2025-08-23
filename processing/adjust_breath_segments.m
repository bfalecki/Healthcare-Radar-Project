function phase_adj = adjust_breath_segments(phase,start_samples,end_samples)
%ADJUST_BREATH_SEGMENTS This function adjusts phase offset and performs
%interpolation between the segments

phase_adj = zeros(size(phase));
for k = 1:length(start_samples)-1
    if(k == 1)
        offset = 0;
    else
        offset = offset + offset_next;
    end
    idxes1 = start_samples(k):end_samples(k);
    idxes2 = start_samples(k+1):end_samples(k+1);
    segment1 = phase(idxes1);
    segment2 = phase(idxes2);
    [connected, offset_next] = adj_segment(segment1,idxes1,segment2,idxes2);
    phase_adj(idxes1(1):idxes2(end)) = connected + offset;
end

end

