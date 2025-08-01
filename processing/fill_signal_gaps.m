function [signal_filled, t, segment_duration] = fill_signal_gaps(signal, time_starts, fs)
    % Liczba segmentów
    num_segments = length(time_starts);

    % Automatyczne wyliczenie długości segmentu
    segment_duration = length(signal) / (num_segments * fs);
    samples_per_segment = round(segment_duration * fs);

    % Obliczenie całkowitej długości sygnału z czasem
    total_duration = time_starts(end) + segment_duration;
    total_samples = round(total_duration * fs);
    signal_filled = zeros(1, total_samples);

    % Wstawianie danych
    current_idx = 1;
    for i = 1:num_segments
        start_sample = round(time_starts(i) * fs) + 1;
        end_sample = start_sample + samples_per_segment - 1;

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

    t = (0:length(signal_filled)-1) / fs;
end
