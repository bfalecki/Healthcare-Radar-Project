function signal_fixed = fix_edges(signal,start_samples, end_samples, depth)
%FIX_EDGES replace edge values in the segments by mean of N=depth near samples

% signal - signal to fix
% start_samples - segment start samples
% end_samples - segment end samples
% depth - number od samples to average




signal_fixed = signal;
for k = 1:length(start_samples)
    samples_to_avg_start = start_samples(k):start_samples(k)+depth;
    signal_fixed(start_samples(k)) = median(signal(samples_to_avg_start));
    samples_to_avg_end = end_samples(k) - depth:end_samples(k);
    signal_fixed(end_samples(k)) = median(signal(samples_to_avg_end));
end

end

