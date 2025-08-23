function [best_sin,p] = fit_sin(signal,p0)
%FIT_SIN fit sinusoid part to the data

% p0 - start parameters [amplitude, norm_frequency, phase_offset, val_offset]


t = 0:length(signal)-1;

% Model
model = @(p,t) p(1)*sin(p(2)*t + p(3)) + p(4);

% Funkcja błędu
err = @(p) sum((signal - model(p,t)).^2);

% Optymalizacja
p = fminsearch(err, p0);
best_sin = model(p,t);

% disp('Parametry [A, w, phi, C]:')
% disp(p)
% 
% % Wykres
% figure(1)
% plot(x, y, 'o')
% hold on
% plot(x, model(p,x), '-r', 'LineWidth', 2)
end

