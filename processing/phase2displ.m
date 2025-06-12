function [displ] = phase2displ(phase,fc)
%PHASE2DISPL converts phase [rad] to displacement [m]
displ = phase*physconst("LightSpeed")/(fc*4*pi); 
end

