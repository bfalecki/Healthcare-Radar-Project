function [slow_time_signal,row] = choose_RT_row(RT)
%CHOOSE_RT_ROW This function can choose the best range time row with
%highest probability of vital signs signal presence.
% To be improved...

% maximum amplitude after MTI
[~,row] = max(mean(abs(mti(RT.')), 1));

% maximum amplitude
% [~,row] = max(mean(abs(RT), 2));

slow_time_signal = RT(row, :);
end

