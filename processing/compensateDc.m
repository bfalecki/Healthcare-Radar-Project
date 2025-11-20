function [signalComp, middle] = compensateDc(signalIQ)
%COMPENSATEDC this function makes DC compensation of the signal

middle = mean(signalIQ);
signalComp = signalIQ - middle;
end

