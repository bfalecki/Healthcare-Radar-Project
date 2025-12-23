function [signal_filled, t, segment_duration, start_samples, end_samples, segments_idxes] = fill_signal_gaps(signal, time_starts, fs, opts)
    
arguments
    signal % can be matrix, first dimension represent different channels
    time_starts 
    fs 
    opts.addtitional_samples = 0 % shift segments in samples
    opts.default_val = 0
    opts.samples_per_segment = []
    opts.cut_first_samples = 1 % how many samples to cut on the beggining of each frame (first pulse is somehow outlier)
end

    addtitional_samples = opts.addtitional_samples;
    default_val = opts.default_val;

% Liczba segmentów
    num_segments = length(time_starts);

    % Automatyczne wyliczenie długości segmentu
    segment_duration = size(signal,2) / (num_segments * fs);
    if(isempty(opts.samples_per_segment))
        samples_per_segment = round(segment_duration * fs);
    else
        samples_per_segment = opts.samples_per_segment;
    end

    % Obliczenie całkowitej długości sygnału z czasem
    total_duration = time_starts(end) + segment_duration;
    total_samples = round(total_duration * fs);
    signal_filled = ones(size(signal,1), total_samples) * default_val;

    % Wstawianie danych
    current_idx = 1;
    start_samples = zeros(1, length(num_segments));
    end_samples = zeros(1, length(num_segments));
    for i = 1:num_segments
        
        start_sample = round(time_starts(i) * fs) + 1 + addtitional_samples + opts.cut_first_samples;
        start_samples(i) = start_sample;

        end_sample = (start_sample-opts.cut_first_samples) + samples_per_segment - 1;
        end_samples(i) = end_sample;

        if current_idx + samples_per_segment - 1 > size(signal,2)
            warning('Niepełny ostatni segment – wstawiam tylko dostępne dane.');
            segment = signal(:,current_idx:end);
            signal_filled(:,start_sample:start_sample+length(segment)-1) = segment(:,1 + opts.cut_first_samples : end);
            break;
        else
            segment = signal(:,current_idx : current_idx + samples_per_segment - 1);
            signal_filled(:,start_sample:end_sample) = segment(:,1 + opts.cut_first_samples : end);
            current_idx = current_idx + samples_per_segment;
        end
    end

    % get segment indexes (logical)
    segments_idxes = get_segments_idxes(start_samples,end_samples, size(signal_filled,2));

    t = (0:size(signal_filled,2)-1) / fs;
end
