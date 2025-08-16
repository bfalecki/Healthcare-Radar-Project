function x_filled = fill_gaps_ar_bidirectional(x,p)
%FILL_GAPS_AR_BIDIRECTIONAL 

% x – vector with NaNs at gaps locations (multiple gaps allowed)
% p – order of the AR model (e.g., 20, 50… see tips below)
%
% Returns: x_filled – signal with gap filled based on bidirectional AR


% example
% x = [1 2 3 nan nan nan 5 6 7 nan nan nan nan 10 11 12];
% p = 3;


x = x(:);
nanmask = isnan(x);

gap_starts = find(compl_diff(diff(nanmask)) == 1);
gap_ends = find(compl_diff(diff(nanmask)) == -1) - 1;

% do prediction for every gap independently
x_filled = x;
for gap_nr = 1:length(gap_starts)
    if(gap_nr == 1)
        signal_with_gap_idxes = 1:gap_starts(gap_nr+1)-1;
    elseif(gap_nr == length(gap_starts))
        signal_with_gap_idxes = gap_ends(gap_nr-1)+1:length(x);
    else
        signal_with_gap_idxes = gap_ends(gap_nr-1)+1:gap_starts(gap_nr+1)-1;
    end
    signal_to_predict = x(signal_with_gap_idxes);
    x_filled_part = fill_gap_ar_bidirectional(signal_to_predict, p);
    gap_idxes_local = (gap_starts(gap_nr):gap_ends(gap_nr)) - signal_with_gap_idxes(1) + 1;
    x_filled(gap_starts(gap_nr):gap_ends(gap_nr)) = x_filled_part(gap_idxes_local);
end

end

