function signal_fixed = fix_edges(signal,start_samples, end_samples, depth)
%FIX_EDGES replace edge values in the segments by mean of N=depth near samples

% signal - signal to fix
% start_samples - segment start samples
% end_samples - segment end samples
% depth - number od samples to average




signal_fixed = signal;
for k = 1:length(start_samples)
    %  start_samples(k)+1 as we don't want to use the first sample
    % it is outstanding. The issue is connected with compl_diff function as
    % it adds one sample to the beggining, not to the end of signal.
    % In the second case, we would rather use end_samples(k)-1 instead of end_samples(k)
    % and start_samples(k) would be OK
    samples_to_avg_start = start_samples(k)+1:start_samples(k)+depth;
    signal_fixed(start_samples(k)) = median(signal(samples_to_avg_start));
    samples_to_avg_end = end_samples(k) - depth:end_samples(k);
    signal_fixed(end_samples(k)) = median(signal(samples_to_avg_end));
end

end

