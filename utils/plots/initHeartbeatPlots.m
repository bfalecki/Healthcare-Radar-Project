function handlesHeartbeat = initHeartbeatPlots()
%INITHEARTBEATPLOTS Summary of this function goes here
%   Detailed explanation goes here
% Figure 11 - Filtered Phase Differentiation
% figure(11)
% hFilt = plot(nan,nan);
% xlabel("Time [s]"); title("Filtered Phase Differentiation [rad/s]");

% Figure 12 - STFT
figure(12)
hSTFT = imagesc(nan); axis xy
colormap("jet"); colorbar
ylim([0 inf]);
title("Short Time Fourier Transform (Heartbeat detection)");
xlabel("Time [s]"); ylabel("Frequency [Hz]");
% setFigSize([0.0 0.35 0.6 0.3]) % config 1
setFigSize([0.0 0.35 0.7 0.3]) % config 2

% Figure 13 - Extracted Signal
figure(13)
hPred = plot(nan,nan); hold on
hAvail = plot(nan,nan,'LineWidth',2); hold off
title("Signal Extracted from STFT (Heartbeat signal)");
legend("Predicted","Available");
xlabel("Time [s]");
% setFigSize([0.0 0.05 0.6 0.3]) % config 1
setFigSize([0.0 0.05 0.7 0.3]) % config 2

% Figure 14 - Synchrosqueezed STFT
figure(14)
hImg = imagesc(nan); axis xy
colormap(flip(gray)); colorbar
hRidge = line(nan,nan,'Color','r','LineWidth',1.5,'LineStyle','--');
ylabel("Heart Rate [BPM]"); xlabel("Time [s]");
title("Synchrosqueezed STFT");
% setFigSize([0.6 0.05 0.4 0.475]) % config 1
setFigSize([0.7 0.05 0.3 0.3]) % config 2

% zapisz uchwyty w strukturze
% handlesHeartbeat.filteredPhase = hFilt;
handlesHeartbeat.stft = hSTFT;
handlesHeartbeat.extractedSignal.pred = hPred;
handlesHeartbeat.extractedSignal.avail = hAvail;
handlesHeartbeat.sstft.img = hImg;
handlesHeartbeat.sstft.ridge = hRidge;
end

