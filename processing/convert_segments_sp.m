function [start_samples_sp,end_samples_sp] = convert_segments_sp(...
    start_samples,end_samples, original_fs, desired_fs, overlap_len)
%RESAMPLE_SEGMENTS_IDXES 
% convert segment starts/ends idxes from original_fs to desired_fs to fit
% spectrogram values

% start_samples - starts of segments vector (samples)
% end_samples - ends of segments vector (samples)
% original_fs - original sampling frequency [Hz]
% desired_fs - desired sampling frequency [Hz]
% overlap_len - overlap length of the STFT - number of samples according to original_fs

% % overlap_len/2 is experimental but it works - with no symmetric padarray
% start_samples_sp = round(start_samples / original_fs * desired_fs - 0.5*overlap_len / original_fs * desired_fs);
% end_samples_sp = round(end_samples / original_fs * desired_fs - 0.5*overlap_len / original_fs * desired_fs);

% for symmetric padarray - ceil experimental
start_samples_sp = ceil(start_samples / original_fs * desired_fs);
end_samples_sp = ceil(end_samples / original_fs * desired_fs);

end

