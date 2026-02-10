function sig_env = extract_env_sp(sp,f_ax,opts)
%EXTRACT_ENV_STFT 
% extract signal power (envelope) based on the given STFT distribution in the given
% frequency range
arguments
    sp % complex STFT distribution
    f_ax % frequnecy axis
    opts.FreqRange = [min(f_ax) max(f_ax)] % frequency range to sum
    opts.LogScale = 0; % take in dB instead of abs()
    opts.Normalize = 0; % normalize along Doppler axis
end

[~,freq_row_idx_low] = min(abs(f_ax - opts.FreqRange(1) ));
[~,freq_row_idx_high] = min(abs(f_ax - opts.FreqRange(2) ));

sp_to_sum = sp(freq_row_idx_low:freq_row_idx_high, :);
if(opts.Normalize)
    sp_to_sum = sp_to_sum ./ (sum(sp_to_sum,2));
end


if(opts.LogScale)
    min_nonzero = min(nonzeros(sp_to_sum(:)));
    sp_to_sum(sp_to_sum == 0) = min_nonzero;
    min_nonzero_db = db(min_nonzero);
    sp_to_sum_db = db(sp_to_sum) - min_nonzero_db;
    sig_env = sum(sp_to_sum_db);
else
    sig_env = sum(abs(sp_to_sum));
end





end

