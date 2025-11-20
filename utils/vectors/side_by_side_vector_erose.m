function out = side_by_side_vector_erose(vect, margin_probes, side)
% example
% margin_probes = 2;
% vect  =  [0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 1 1 1 1 1 0 0];
% out      [0 0 0 0 0 1 1 1 1 0 0 0 0 0 0 0 0 1 0 0 0 0]

if(~exist("side", "var"))
    side = "both";
end

out = vect;
diff_vect = diff(vect);
diff_vect(diff_vect == -1) = 0;
raises = [0 diff_vect];

diff_not_vect = diff(~vect);
diff_not_vect(diff_not_vect == -1) = 0;
falls = [diff_not_vect 0];

if(side == "both" || side == "left")
    remaining2erose = 0;
    for pos = 1:length(vect)
        if(raises(pos) == 1)
            remaining2erose = margin_probes;
        end
        if(remaining2erose > 0)
            out(pos) = 0;
            remaining2erose = remaining2erose - 1;
        end
    end
end

if(side == "both" || side == "right")
    remaining2erose = 0;
    for pos = length(vect):-1:1
    
        if(falls(pos) == 1)
            remaining2erose = margin_probes;
        end
        if(remaining2erose > 0)
            out(pos) = 0;
            remaining2erose = remaining2erose - 1;
        end
    end
end

if(side == "left")
    out(1) = 0;
end
if(side == "right")
    out(end) = 0;
end
end