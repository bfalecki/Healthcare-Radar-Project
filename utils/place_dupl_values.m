function [placed] = place_dupl_values(values,positions, final_length)
%PLACE_DUPL_VALUES - places duplicated values starting from positions
% example
% values = [1 3 5 10];
% positions = [5 10 20 25];
% final_length = 35;

placed = zeros(1, final_length);
for k = 1:length(values)
    if(k ~= length(values))
        pos_next = positions(k+1)-1;
    else
        pos_next = final_length;
    end
    placed(positions(k):pos_next) = values(k);
end

end

