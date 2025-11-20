base = [1 2 5];
frame_lens = [base*1e-2 base*1e-1 1 1.87];
break_lens = zeros(size(frame_lens));


for k = 1:numel(frame_lens)
    clearvars -except base frame_lens break_lens k
    sc = SignalCapturer("DoSave",0,"FrameLength",frame_lens(k),"TotalRecLength",frame_lens(k)*5,"SeparateChannels",0,"MaxSpeed", 1,"SaveRaw",1);
    sc.configure();
    sc.record();
    period_len = mean(diff(sc.times_post_tx(2:end)));
    break_lens(k) = period_len - frame_lens(k);
end

%%
figure(1)
plot(frame_lens, break_lens, 'ok', MarkerSize=10)
p = polyfit(frame_lens, break_lens,1);
hold on
x = 0:0.1:2;
y = x * p(1) + p(2); % break_length = 0.6171 * frame_length +  0.1027
plot(x ,y, '--k', LineWidth=2)
hold off
grid on
legend('Measured Steps','Linear Fit')
xlabel('Frame Duration [s]')
ylabel('Break Duration [s]')