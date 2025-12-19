function [slow_time_signal,row, RT_processed, choice_fun] = choose_RT_row(RT)
%CHOOSE_RT_ROW This function can choose the best range time row with
%highest probability of vital signs signal presence.

% maximum amplitude after MTI
RT_processed = abs(mti(RT.')).'; 

choice_fun  = mean(RT_processed, 2);
choice_fun(1:3) = 0; % there is an offset range we want to discard
[~,row] = max(choice_fun);

slow_time_signal = RT(row, :);
end




% % alternatively, maximum amplitude
% RT_processed = abs(RT);
