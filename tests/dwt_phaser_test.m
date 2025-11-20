

time = results_heartbeat.filteredPhase.time;
signal = results_heartbeat.filteredPhase.data;

[CA1,CD1] = dwt(signal,'db4');
[CA2,CD2] = dwt(CA1,'db4');
[CA3,CD3] = dwt(CA2,'db4');

figure(1)
plot(CA3)
figure(2)
plot(CD3)