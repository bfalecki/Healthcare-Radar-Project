function outdata = arrangePulseData_fix(indata,rx,bf,bf_TDD, opts)
% Rearrange a full stream of data into an nSample x nPulse data matrix.
%
% Copyright 2023 The MathWorks, Inc.

arguments
    indata 
    rx 
    bf 
    bf_TDD 
    opts.fs = 520834 % if we have to provide these values without using phaser objects
    opts.tsweep = []
    opts.tstartsweep = 0
    opts.tpulse = []
    opts.nPulses = []
    opts.digitalweights = []
end

% Combine data from channels with calibration (and steering) weights
if(size(indata,2) == 2)
    if(isempty(opts.digitalweights)) % saved in file
        indata = applyDigitalCalWeights(indata);
    else % wtih beam steering
        indata = indata * conj(opts.digitalweights);
    end
end

if(isempty(opts.tpulse))
    % Extract timing from pluto and phaser setup
    fs = rx.SamplingRate;
    tsweep = double(bf.FrequencyDeviationTime) / 1e6;
    tstartsweep = bf_TDD.Ch0On;
    tpulse = bf_TDD.FrameLength / 1e3;
    nPulses = bf_TDD.BurstCount;
else
    fs = opts.fs;
    tsweep = opts.tsweep;
    tstartsweep = opts.tstartsweep;
    tpulse = opts.tpulse;
    nPulses = opts.nPulses;
end

% Get the number of samples into the pulse that the sweep starts
sweepoffsetsamples = ceil(tstartsweep * fs);

% Get indices within a pulse that contain the sweep data
sweepsamples = 1:ceil(tsweep * fs) + sweepoffsetsamples;

% Get end index of pulse
pulseendsample = round(tpulse * fs);

% Get all of the pulse start indices
pulsestartsamples = (0:nPulses-1)*pulseendsample;
allsweepsamples = repmat(sweepsamples',1,nPulses);
sampleidxs = allsweepsamples + pulsestartsamples;

% Get output data rearranged. If we are trying to index a value that is too
% high, return all zeros. Sometimes pluto can return incorrect number of
% samples.
nCollectedSamples = size(indata,1);
nRequiredSamples = max(sampleidxs,[],"all");
if nRequiredSamples > nCollectedSamples
    indata = padarray(indata, nRequiredSamples - nCollectedSamples, "post");
    outdata = indata(sampleidxs);
    % outdata = zeros(size(sampleidxs));
else
    outdata = indata(sampleidxs);
end

end