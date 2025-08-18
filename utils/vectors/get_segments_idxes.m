function segments_idxes = get_segments_idxes(start_samples,end_samples, Nsamples)
%GET_SEGMENTS_IDXES 
% place zeros out of the segments, place 1 in the segments


segments_idxes = zeros(1, Nsamples);
all_idxes = 1:Nsamples;
for k = 1:length(start_samples)
    % works as alternative
    segments_idxes = segments_idxes + (all_idxes >= start_samples(k) & all_idxes <= end_samples(k));
end
segments_idxes = logical(segments_idxes);


end

