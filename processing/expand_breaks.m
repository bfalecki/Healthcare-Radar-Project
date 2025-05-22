function [signal_filled, time_lags_filled] = expand_breaks(signal,PRF,times_post_tx, times_post_rx)
%EXPAND_BREAKS Summary of this function goes here
%   Detailed explanation goes here
times_rec_starts = times_post_tx - times_post_tx(1);
time_rec_ends = times_post_rx -  times_post_tx(1);

time_lags_cont = linspace(0, length(signal)/PRF, length(signal));
% now insert breaks to time_lags
time_lags_cut = time_lags_cont;
idxs_first = zeros(1,length(times_rec_starts));
for k = 1:length(times_rec_starts)
    idx_shift = time_lags_cut > times_rec_starts(k);
    idx_first = find(idx_shift, 1, "first");
    if(~isempty(idx_first))
        idxs_first(k) = idx_first;
    end
    time_lags_cut(idx_shift) = time_lags_cut(idx_shift) + times_rec_starts(k)-time_lags_cut(idx_first);
end
signal_filled = signal;
time_lags_filled = time_lags_cut;
for k = length(times_rec_starts):-1:1
    idx_start_break = idxs_first(k)-1;
    idx_end_break = idxs_first(k);
    break_lags = times_rec_starts(k):1/PRF:time_rec_ends(k);
    zeropad = zeros(size(break_lags));
    time_lags_filled = [time_lags_filled(1:idx_start_break) break_lags  time_lags_filled(idx_end_break:end)];
    signal_filled = [signal_filled(1:idx_start_break) zeropad  signal_filled(idx_end_break:end)];
end

end

