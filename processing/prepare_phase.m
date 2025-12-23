function [phaseRaw,phaseDiffRaw,segmentsBounds, timeLags,segmentDuration,phase,phaseDiff] =...
    prepare_phase(radarSignal,PRF,opts)
%PREPARE_PHASE 
% this function makes pre-processing of the raw signal to extract its phase

% output:
% phaseRaw - raw unwrapped phase of the signal (no interpolation, with reset_accumulated_phase function
%       performed and breaks placed)
% phaseDiffRaw - raw differentiated phase of the signal (no interpolation, no peak filtering, no edge fix)
% phaseDiff - filtered, differentiated phase of the signal with placed
%       with linearly interpolated breaks
% phase - unwrapped phase of the signal
% segmentsBounds - [start_samples;end_samples] of the segments, where
%       start_samples and end_samples are vectors (in samples)
% timeLags - time signature of samples [s]
% segmentDuration - calculated single segment duration [s]

arguments
    radarSignal % raw radar signal (single range cell in I/Q)
    PRF % Pulse repetition frequency of the radar signal
    opts.FrameStartTimes = [0] % vector containing start times of the consecutive frames [s].
        % In this case, breaks are automatically places in the signal
    opts.FilterNoisePeaks = 1 % perform filter_noise_peaks function on differentiated phase 
    opts.FNP_NeighborSize = 3 % NeighborSize argument to filter_noise_peaks function
    opts.FNP_ThresholdMultiplier = 3 % ThresholdMultiplier argument to filter_noise_peaks funciton
    opts.FNP_ThresholdQuantile = 0.9 % ThresholdQuantille argument to filter_noise_peaks funciton
    opts.FixEdgesDepth = 0.1 % How long period can be averaged to be placed on the segment's edges [s]

end
FrameStartTimes = opts.FrameStartTimes;
FilterNoisePeaks = opts.FilterNoisePeaks;
FNP_NeighborSize = opts.FNP_NeighborSize;
FNP_ThresholdMultiplier = opts.FNP_ThresholdMultiplier;
FNP_ThresholdQuantile = opts.FNP_ThresholdQuantile;
FixEdgesDepth = opts.FixEdgesDepth;

[signal_filled, timeLags, segmentDuration, start_samples, end_samples] = ... % filling gaps in the signal
    fill_signal_gaps(radarSignal, FrameStartTimes, PRF);
segmentsBounds = [start_samples;end_samples];
phaseRaw = unwrap(angle(signal_filled)); % % % % phase anaylsis: extracting unwrapped phase
phaseRaw = reset_accumulated_phase(phaseRaw, start_samples,end_samples);% get rid of big first difference sample
phaseDiffRaw = compl_diff(diff(phaseRaw));% differentiation
if(nargout > 5)
    phaseDiff = phaseDiffRaw;
    if(FilterNoisePeaks)     % outstanding vals filtering
        phaseDiff = filter_noise_peaks(phaseDiff, "Display",0,"NeighborSize",FNP_NeighborSize,...
            "SegmentsBounds",[start_samples;end_samples],...
            "ThresholdMultiplier",FNP_ThresholdMultiplier,"ThresholdQuantile",FNP_ThresholdQuantile);
    end
    % fix segment edge noise (put mean values to every edge) - helpful for
    % further linear interpolation
    depth_samples = round(segmentDuration * FixEdgesDepth * PRF);
    depth_samples(depth_samples < 1) = 1;
    phaseDiff = fix_edges(phaseDiff, start_samples,end_samples, depth_samples);

    [phaseDiff, max_gap] = placeNans_RN(phaseDiff,start_samples, end_samples);% place NaNs in breaks
    phaseDiff = fillmissing(phaseDiff, 'linear', 'MaxGap',max_gap*2); % interpolate breaks
    phaseDiff(isnan(phaseDiff)) = 0; % Restore zeroes in NaN samples
    phase = cumsum(phaseDiff);
    
end

end


