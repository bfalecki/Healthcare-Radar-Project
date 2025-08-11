function vect_completed = compl_diff(vect)
%COMPL_DIFF funkja dopełnia diff (z przodu dodaje 1 liniowo ekstrapolowany element)
% example
% vect = [3 3.5 4].';
%

prev_el = vect(1) - (vect(2)-vect(1));
vect(end+1) = nan;
vect(2:end) = vect(1:end-1);
vect(1) = prev_el;
vect_completed = vect;
end

