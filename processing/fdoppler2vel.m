function vd = fdoppler2vel(fd,fc)
%FDOPPLER2VEL Summary of this function goes here
vd = -fd/2*physconst("LightSpeed")/fc;
end

