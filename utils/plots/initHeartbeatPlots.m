function handlesHeartbeat = initHeartbeatPlots()
%INITHEARTBEATPLOTS Summary of this function goes here
%   Detailed explanation goes here
% Figure 11 - Filtered Phase Differentiation
figure(11)
hFilt = plot(nan,nan);
xlabel("Time [s]"); title("Filtered Phase Differentiation [rad/s]");

% Figure 12 - STFT
figure(12)
hSTFT = imagesc(nan,nan,nan); axis xy
colormap("jet");
ylim([0 inf]);
title("Short Time Fourier Transform");
xlabel("Time [s]"); ylabel("Frequency [Hz]");

% Figure 13 - Extracted Signal
figure(13)
hPred = plot(nan,nan); hold on
hAvail = plot(nan,nan,'LineWidth',2); hold off
title("Signal Extracted from STFT");
legend("Predicted","Available");
xlabel("Time [s]");

% Figure 14 - Synchrosqueezed STFT
figure(14)
hImg = imagesc(nan,nan,nan); axis xy
colormap(flip(gray)); colorbar
hRidge = line(nan,nan,'Color','r','LineWidth',1.5,'LineStyle','--');
ylabel("Heart Rate [BPM]"); xlabel("Time [s]");
title("Synchrosqueezed STFT with detected ridge");

% zapisz uchwyty w strukturze
handlesHeartbeat.filteredPhase = hFilt;
handlesHeartbeat.stft = hSTFT;
handlesHeartbeat.extractedSignal.pred = hPred;
handlesHeartbeat.extractedSignal.avail = hAvail;
handlesHeartbeat.sstft.img = hImg;
handlesHeartbeat.sstft.ridge = hRidge;
end

