function fd = vel2fdoppler(vel,fc)
%VEL2FDOPPLER Summary of this function goes here
fd = -vel*2/physconst("LightSpeed")*fc;
end

