function [signal_filt,condition_function, thresh] = filter_noise_peaks(signal, opts)
% This function performs filtering of the measured differentiated phase signal.
% In the signal, there are often some noise peaks which needs to be removed

arguments
    signal % % before using this function, you need to extract signal in this way:
        % phase = unwrap(angle(radar_signal_raw));
        % signal = compl_diff(diff(phase));
        % % measured signal needs to be then filled with breaks
        % [signal, ~, ~, start_samples, end_samples] = ...
        %       fill_signal_gaps(signal, rec_file.times_post_burse, actual_fs);
    opts.ThresholdQuantile = 0.9  % Discrimination threshold is computed as thresh = quantile(condition_function,ThresholdQuantile) * ThresholdMultiplier;
    opts.ThresholdMultiplier = 3 % See above
    opts.SegmentsBounds = [1;length(signal)]; % Discrimined samples cannot be predicted based on the out-of-segment samples
            % Specify SegmentsBounds in format:
            % [start_samples; end_samples], e.g. [1 11 21; 7 17 27]
    opts.NeighborSize = 2 % Samples are predicted based on mean value of the valid samples in maximum neighbor of NeighborSize
            % For example, NeighborSize = 2 gives total 4 possible valid
            % samples to predict the middle value
            % If there is no valid samples, result will be filled by 0
    opts.Display = 0 % Display plot
end

ThresholdQuantile = opts.ThresholdQuantile;
ThresholdMultiplier = opts.ThresholdMultiplier;
SegmentsBounds = opts.SegmentsBounds;
neig_size = opts.NeighborSize;
Display = opts.Display;



% threshold based on differentation amplitude
condition_function = abs(compl_diff(diff(signal)));
thresh = quantile(condition_function,ThresholdQuantile) * ThresholdMultiplier;
out_idxes = condition_function > thresh;
out_idxes_found = find(out_idxes);

idxes_to_fill_matr = zeros(length(out_idxes_found),2*neig_size);

k = 1;
for shift = (-neig_size):neig_size
    if(shift ~= 0)
        idxes_to_fill_matr(:,k) = out_idxes_found+shift;
        k = k+1;
    end
end

% exclude invalid
idxes_to_fill_matr(idxes_to_fill_matr < 1 | idxes_to_fill_matr > length(signal)) = nan;

% set intersected to nan
original_size = size(idxes_to_fill_matr);
idxes_to_fill_matr = reshape(idxes_to_fill_matr,original_size(1) * original_size(2),1);
[idxes_idxes_out] = ismember(idxes_to_fill_matr, out_idxes_found);
idxes_to_fill_matr(idxes_idxes_out) = nan;
idxes_to_fill_matr = reshape(idxes_to_fill_matr, original_size);


% set out-of-segments to nan
start_samples = SegmentsBounds(1,:);
end_samples = SegmentsBounds(2,:);
valid_idxes = zeros(size(idxes_to_fill_matr));
for k = 1:length(start_samples)
    % works as alternative
    valid_idxes = valid_idxes + (idxes_to_fill_matr >= start_samples(k) & idxes_to_fill_matr <= end_samples(k));
end
valid_idxes = logical(valid_idxes);
idxes_to_fill_matr(~valid_idxes) = nan;

% count nans
nan_idxes = isnan(idxes_to_fill_matr);
Nnans = sum(nan_idxes, 2);

% nan to any valid
idxes_to_fill_matr(nan_idxes) = 1;

% take values
values_used = signal(idxes_to_fill_matr);

% take average from non nan
values_used(nan_idxes) = 0;
predicted = sum(values_used, 2) ./ (2*neig_size - Nnans);
predicted(isnan(predicted)) = 0;


signal_filt = signal;
signal_filt(out_idxes_found) = predicted;

if(Display)
    plot(signal)
    hold on
    plot(signal_filt, LineWidth=2)
    plot(condition_function)
    plot([1, length(signal_filt)], thresh*ones(1,2), '--')
    hold off
    legend('Raw', "Filtered","Discr. fun.", "Discr. thresh.")
end


end

