function [placed] = place_dupl_values_startend(values,position_starts, position_ends, final_length)
%PLACE_DUPL_VALUES - places duplicated values starting from positions
% example
% values = [1 3 5 10];
% position_starts = [5 10 20 25];
% position_ends = [7 13 24 27];
% final_length = 35;

placed = zeros(1, final_length);
for k = 1:length(values)
    placed(position_starts(k):position_ends(k)) = values(k);
end

end

