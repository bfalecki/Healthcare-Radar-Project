function [signal_filled, t, segment_duration, start_samples, end_samples, segments_idxes] = fill_signal_gaps(signal, time_starts, fs, addtitional_samples, default_val)
    

    if(~exist("addtitional_samples", "var") || isempty(addtitional_samples))
        % shift segments in samples
        addtitional_samples = 0;
    end

    if(~exist("default_val", "var") || isempty(default_val))
        default_val = 0;
    end

% Liczba segmentów
    num_segments = length(time_starts);

    % Automatyczne wyliczenie długości segmentu
    segment_duration = length(signal) / (num_segments * fs);
    samples_per_segment = round(segment_duration * fs);

    % Obliczenie całkowitej długości sygnału z czasem
    total_duration = time_starts(end) + segment_duration;
    total_samples = round(total_duration * fs);
    signal_filled = ones(1, total_samples) * default_val;

    % Wstawianie danych
    current_idx = 1;
    start_samples = zeros(1, length(num_segments));
    end_samples = zeros(1, length(num_segments));
    for i = 1:num_segments
        
        start_sample = round(time_starts(i) * fs) + 1 + addtitional_samples;
        start_samples(i) = start_sample;

        end_sample = start_sample + samples_per_segment - 1;
        end_samples(i) = end_sample;

        if current_idx + samples_per_segment - 1 > length(signal)
            warning('Niepełny ostatni segment – wstawiam tylko dostępne dane.');
            segment = signal(current_idx:end);
            signal_filled(start_sample:start_sample+length(segment)-1) = segment;
            break;
        else
            segment = signal(current_idx : current_idx + samples_per_segment - 1);
            signal_filled(start_sample:end_sample) = segment;
            current_idx = current_idx + samples_per_segment;
        end
    end

    % get break indexes
    segments_idxes = zeros(size(signal_filled));
    all_idxes = 1:length(signal_filled);
    for k = 1:length(start_samples)
        % works as alternative
        segments_idxes = segments_idxes + (all_idxes >= start_samples(k) & all_idxes <= end_samples(k));
    end
    segments_idxes = logical(segments_idxes);

    t = (0:length(signal_filled)-1) / fs;
end
