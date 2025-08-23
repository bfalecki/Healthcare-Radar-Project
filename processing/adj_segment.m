function [connected, offset] = adj_segment(segment1,idxes1, segment2, idxes2)
%ADJ_SEGMENTS 
% adjust second breath-cycle segment - perform interpolation and adjust
% offset

% segment1 - phase corresponding to the first segment
% idxes1 - indexes of samples of the first segment
% segment22 - phase corresponding to the second segment
% idxes2 - indexes of samples of the second segment

Noffsets = 100;
InterpMethod = "makima";

offset_check_width = 2* max((max(segment1) - min(segment1)), (max(segment2) - min(segment2)));
offsets = linspace(-offset_check_width/2 , offset_check_width/2, Noffsets);
break_idxes = idxes1(end) + 1 : idxes2(1) - 1;
break_idxes_rel = break_idxes - idxes1(1) + 1;
break_len = length(break_idxes);

opt_funs = zeros(2,length(offsets));

for k = 1:Noffsets
    connected_trial = fillmissing([segment1(:); nan(break_len,1); segment2(:) + offsets(k)],InterpMethod);
    opt_funs(:,k) = opt_function(connected_trial(break_idxes_rel));
end

% optimization functions connection
weights = [0; 1];
opt_funs_norm = zeros(size(opt_funs));
for dim1 = 1:size(opt_funs,1)
    opt_funs_norm(dim1, :) = normalize(opt_funs(dim1, :));
end
opt_fun = sum(opt_funs_norm.*weights, 1);


% % peaks
% [pks,k_possible] = findpeaks(-opt_fun);
% [~,k_ind_best] = max(pks);
% k_best = k_possible(k_ind_best);
% if(isempty(k_best))
%     [~,k_best] = min(opt_fun);
% end

% min
[~,k_best] = min(opt_fun);

if(isempty(k_best))
    [~,k_best] = min(opt_fun);
end


connected = fillmissing([segment1(:); nan(break_len,1); segment2(:) + offsets(k_best)],InterpMethod);
offset = offsets(k_best);

end

function opt_fun_val = opt_function(break_samples)
    opt_fun_val(1) = min(diff(diff(break_samples)));
    opt_fun_val(2) = max(break_samples) - min(break_samples);

end