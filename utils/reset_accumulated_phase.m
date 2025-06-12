function [phase] = reset_accumulated_phase(phase,start_samples,end_samples)
%reset_accumulated_phase this function resets the accumulated offset phase after
%demodulation of signal filled with breaks
phase_reset = place_dupl_values(phase(start_samples),start_samples,length(phase));
phase = phase - phase_reset;
[phase_reset2] = ...
    place_dupl_values_startend(phase(end_samples(1:end-1)+1),end_samples(1:end-1)+1, start_samples(2:end)-1, length(phase));
phase = phase - phase_reset2;

end

