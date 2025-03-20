% This script allows to save multi-frame recordings to a file
% composed from 
% - fmcwDemo.m - configuration
% - fmcwRunContinuous.m - recording loop
% which can be found here
% https://github.com/mathworks/Phaser-Control-with-MATLAB/tree/main

%% Clear, close figures, turn off warnings
% clear; close all;
warning('off','MATLAB:system:ObsoleteSystemObjectMixin')

%% Put some requirements on the system

maxRange = 10; % 100 m max range, use the system in a room
rangeResolution = 1/3; % Range resolution of 1/3 m
maxSpeed = 0.7; % Max speed we expect is 5 m/s, somebody moving towards the radar
speedResolution = maxSpeed/60; % Speed resolution of 1/2 m/s

%% Determine some parameter values based on system requirements, based on the
% following example - https://www.mathworks.com/help/radar/ug/automotive-adaptive-cruise-control-using-fmcw-technology.html

fc = 10e9; % rf carrier frequency is ~10 GHz
lambda = physconst("LightSpeed") / fc;
rampbandwidth = ceil(rangeres2bw(rangeResolution)/1e6)*1e6; % get ramp bandwidth for required range resolution, conviniently this brings us close to the maximum for the Phaser
fmaxdop = speed2dop(2*maxSpeed,lambda); % Maximum doppler shift depends on max speed we want to resolve, multiply by 2 for 2 way propagation
% prf = 2*fmaxdop; % PRF needs to be set to unambiguously resolve max speed
% nPulses = ceil(2*maxSpeed/speedResolution); % Number of pulses set to for speed resolution
prf = 500; % can be defined independently
nPulses = 2*prf; % one frame can handle up to 2^20 samples which is about 2 seconds on minimum fs
tpulse = ceil((1/prf)*1e3)*1e-3; % Pulse time, round up to the nearest ms
tsweep = getFMCWSweepTime(tpulse,tpulse); % Sweep across as much of the pulse as possible
sweepslope = rampbandwidth / tsweep; % Slope of the FMCW sweep
fmaxbeat = sweepslope * range2time(maxRange); % Max beat frequency in this case we only consider the f offset due to range delay. With faster targets, you need to consider doppler
fs = max(ceil(2*fmaxbeat),520834); % Set sample rate based on the maximum beat frequency or the minimum rate of the pluto.
nSamples = ceil(tpulse * nPulses * fs); % Get the total number of samples in a PRP
nCaptures = 5; % ilość złożonych frames

if(nSamples > 2^20)
    error("Too much nPulses per frame (nSamples > 2^20)")
end


%% Setup pluto
% 
% Setup the pluto
[rx,tx] = setupPluto();

% Setup pluto sampling
rx.SamplesPerFrame = nSamples;
rx.SamplingRate = fs;

% Setup transmitter
tx.SamplingRate = fs;
tx.EnabledChannels = [1,2];
tx.CenterFrequency = rx.CenterFrequency;
tx.AttenuationChannel0 = -3;
tx.AttenuationChannel1 = -3;
tx.EnableCyclicBuffers = true;
tx.DataSource = "DMA";

% This is where you could create some modulation scheme, we just use a
% constant amplitude baseband signal.
amp = 0.9 * 2^15;
txWaveform = amp*ones(nSamples,2);

%% Setup the Phaser
% Setup the pluto
[rx,tx] = setupPluto();

% Setup pluto sampling
rx.SamplesPerFrame = nSamples;
rx.SamplingRate = fs;

% Setup transmitter
tx.SamplingRate = fs;
tx.EnabledChannels = [1,2];
tx.CenterFrequency = rx.CenterFrequency;
tx.AttenuationChannel0 = -3;
tx.AttenuationChannel1 = -3;
tx.EnableCyclicBuffers = true;
tx.DataSource = "DMA";

% This is where you could create some modulation scheme, we just use a
% constant amplitude baseband signal.
amp = 0.9 * 2^15;
txWaveform = amp*ones(nSamples,2);

%% Setup the Phaser

% Setup beamformers all to max gain with no phase shifts
bf = setupPhaser(rx,fc);
bf.RxPowerDown(:) = 0;
bf.RxGain(:) = 127;

% Setup ADF4159
bf.Frequency = (fc+rx.CenterFrequency)/4;
BW = rampbandwidth / 4; 
num_steps = 2^9;
bf.FrequencyDeviationRange = BW;
bf.FrequencyDeviationStep = ((BW) / num_steps);
bf.FrequencyDeviationTime = tsweep*1e6; % convert to us
bf.RampMode = "single_sawtooth_burst"; % use a single sawtooth, other waveforms are available
bf.TriggerEnable = true;  % start a ramp with TXdata
bf.EnablePLL = true;
bf.EnableTxPLL = true;
bf.EnableOut1 = false; % send transmit out of SMA2

%% Setup the TDD engine

bf_TDD = setupTddEngine();
tStartRamp = 0;
tStartCollection = 0;
bf_TDD.PhaserEnable = 1; % enable triggered mode
bf_TDD.Enable = 0;   % TDD must be disabled before changing properties
bf_TDD.EnSyncExternal = 1;
bf_TDD.StartupDelay = 0;
bf_TDD.SyncReset = 0;
bf_TDD.FrameLength = tpulse*1e3;  %frame length in ms
bf_TDD.BurstCount = nPulses; % Number of pulses in a CPI
bf_TDD.Ch0Enable = 1;
bf_TDD.Ch0Polarity = 0;
bf_TDD.Ch0On = tStartRamp; % Time to start PLL sweep in a frame
bf_TDD.Ch0Off = tsweep; % this doesn't need to be tsweep, this just ensures control pulse ends before next PLL pulse starts
bf_TDD.Ch1Enable = 1;
bf_TDD.Ch1Polarity = 0;
bf_TDD.Ch1On = tStartCollection; % Time to start data collection in a frame
bf_TDD.Ch1Off = tStartCollection+0.1;
bf_TDD.Ch2Enable = 1;
bf_TDD.Ch2Polarity = 0;
bf_TDD.Ch2On = 0;
bf_TDD.Ch2Off = 0.1;
bf_TDD.Enable = 1;


% %% pluto, phaser, TDD
% 
% % See fmcw demo for these setup steps
% [rx,tx,bf,bf_TDD,model] = setupFMCWRadar(fc,fs,tpulse,tsweep,nPulses,rampbandwidth);
% 
% % Clear cache
% rx();
% 
% % Use constant amplitude baseband transmit data
% amp = 0.9 * 2^15;
% txWaveform = amp*ones(rx.SamplesPerFrame,2);


%% Trigger TDD and Plot



rx(); % wyczyszczenie bufora jest konieczne

size_data_dim2 = nPulses;
size_data_dim1 = ceil(fs*tsweep);

% alokacja
data1 = zeros(size_data_dim1, size_data_dim2*nCaptures);
data2 = data1;

% Create a range doppler plot
rd = phased.RangeDopplerResponse(DopplerOutput="Speed",...
    OperatingFrequency=fc,SampleRate=fs,RangeMethod="FFT",...
    SweepSlope=sweepslope,PRFSource="Property",PRF=prf);
ax = axes(figure);
time = zeros(1, nCaptures);
tic
for i = 1:nCaptures
    idx_start = size_data_dim2*(i-1)+1;
    idx_end = idx_start +size_data_dim2-1;
    % capture data
    raw_data = captureTransmitWaveform(rx,tx,bf,txWaveform);
    time(i) = toc;

    % Remove excess data, rearrange into nSamples x nPulses
    data1(:,idx_start:idx_end) = arrangePulseData(raw_data(:,1),rx,bf,bf_TDD);
    data2(:,idx_start:idx_end) = arrangePulseData(raw_data(:,2),rx,bf,bf_TDD);
    % 
    % % Plot the data
    % rd.plotResponse(data1(:,idx_start:idx_end));
    % xlim(ax,[-maxSpeed,maxSpeed]); ylim(ax,[0,maxRange]);
    % drawnow;
end



file_suffix = string(datetime("now"));
file_suffix = strrep(file_suffix, ":", "-");
file_suffix = strrep(file_suffix, " ", "_");
save("phaser_rec_"+  file_suffix + ".mat", "data1","data2", "fc", "fs", "prf","tpulse","rampbandwidth", "rx", "bf", "bf_TDD","sweepslope","maxSpeed","maxRange")
%% 

% Create a range doppler plot
rd = phased.RangeDopplerResponse(DopplerOutput="Speed",...
    OperatingFrequency=fc,SampleRate=fs,RangeMethod="FFT",...
    SweepSlope=sweepslope,PRFSource="Property",PRF=prf);
axes(figure)
rd.plotResponse(data1);
ax = gca;
xlim(ax,[-maxSpeed,maxSpeed]); ylim(ax,[0,maxRange]);

%% Disable TDD Trigger so we can operate in Receive only mode
disableTddTrigger(bf_TDD)

%% Helpers

function plotDataTiming(data,fs,tStartRamp,tSweep,tPulse)

plotSinglePulseTiming(data,fs,tStartRamp,tSweep,tPulse);
plotAllPulses(data,fs,tPulse);

end

function plotSinglePulseTiming(data,fs,tStartRamp,tSweep,tPulse)
    % Plot the data collection timing diagram. Only plot a single channel of data
    pulseSamples = floor(tPulse*fs);
    pulseTimes = 0:tPulse/(pulseSamples-1):tPulse;
    firstPulseReal = real(data(1:pulseSamples,1));
    minData = min(firstPulseReal);
    maxData = max(firstPulseReal);

    % Convert to ms
    scalefactor = 1e3;
    pulseTimes = pulseTimes * scalefactor;
    tStartRamp = tStartRamp * scalefactor;
    tSweep = tSweep * scalefactor;
    tPulse = tPulse * scalefactor;
    
    ax1 = axes(figure); hold(ax1,"on"); title(ax1,"Timing for a single pulse");
    plot(ax1,pulseTimes,firstPulseReal,DisplayName="Collected Data");
    plot(ax1,[tStartRamp,tStartRamp],[minData,maxData],DisplayName="Start Frequency Ramp",LineStyle="--");
    plot(ax1,[tSweep,tSweep],[minData,maxData],DisplayName="End Frequency Ramp",LineStyle="--");
    plot(ax1,[tPulse,tPulse],[minData,maxData],DisplayName="End Burst Frame",LineStyle="--");
    xlim(ax1,[0-tPulse/10 tPulse+tPulse/10]); xlabel(ax1,"Time (ms)"); legend(ax1,Visible="on");
    hold(ax1,"off");
end

function plotAllPulses(data,fs,tPulse)
    % Plot all of the data with ends of pulse periods
    
    % Get collected data to plot
    nSamples = size(data,1);
    tEnd = getEndTime(data,fs);
    allTimes = 0:tEnd/(nSamples-1):tEnd;
    dataReal = real(data(:,1));

    % Get pulse period ends to plot
    nPulses = getPulseNum(data,fs,tPulse);
    pulseIdx = 1:nPulses;
    tEndPulses = pulseIdx * tPulse;
    pulseEndTimes = [tEndPulses;tEndPulses];
    pulseEndY = repmat([min(dataReal);max(dataReal)],1,nPulses);

    % Convert to ms
    scalefactor = 1e3;
    allTimes = allTimes * scalefactor;
    pulseEndTimes = pulseEndTimes * scalefactor;
    
    ax1 = axes(figure); hold(ax1,"on"); title(ax1,"Timing for entire PRI");
    plot(ax1,allTimes,dataReal,DisplayName="Collected Data");
    plot(ax1,pulseEndTimes,pulseEndY,DisplayName="End of Burst Frame",Color="k",LineStyle="--");
    xlabel(ax1,"Time (ms)"); l = legend(ax1,Visible="on"); l.String = l.String(1:2);
    hold(ax1,"off");
end

function nPulses = getPulseNum(data,fs,tPulse)
    tEnd = getEndTime(data,fs);
    nPulses = round(tEnd / tPulse);
end

function tEnd = getEndTime(data,fs)
    nSamples = size(data,1);
    tEnd = nSamples/fs;
end



