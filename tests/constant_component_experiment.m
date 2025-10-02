% this script shows how the interferences frequency depends on prf

maxSetSpeed = [1   1.2   1.4    1.6    1.8    ...
    2         2.2       2.4   2.6  2.8   ...
    3     3.2   3.4   3.6   3.8   ...
    4   4.2 4.4 4.6 4.8];
prf = 2*speed2dop(2*maxSetSpeed,physconst("LightSpeed")/10e9);
peak_freq = [32.71 74.8 58.93 20.75    23.05  ...
    33.88      36.2        40 75.862   82  ...
    87.8  93.5  99.5  105.2  94.8  ...
    99.7 104.68 109.74 114.66 119.64];

figure(1)
plot(prf, peak_freq, '-o')
xlabel("PRF [Hz]")
ylabel("Interference Freq. [Hz]")
xlims = xlim;
ylims = ylim;
xlim([0 xlims(2)])
ylim([0 ylims(2)])
grid on

figure(3)
plot(prf,peak_freq./prf, '-o')
xlabel("PRF [Hz]")
ylabel("Interf-Freq to PRF Ratio")
xlims = xlim;
ylims = ylim;
xlim([0 xlims(2)])
ylim([0 ylims(2)])
grid on

% figure(2)
% plot(1./prf, 1./peak_freq, '-o')
% xlabel("PRI [s]")
% ylabel("Interference Period. [s]")
% grid on
% xlims = xlim;
% ylims = ylim;
% xlim([0 xlims(2)])
% ylim([0 ylims(2)])