% Dane
x = linspace(0, 4*pi, 100)';
y = 2*sin(1.5*x + 0.5) + 0.3 + 0.2*randn(size(x));

% Model
model = @(p,x) p(1)*sin(p(2)*x + p(3)) + p(4);

% Funkcja błędu
err = @(p) sum((y - model(p,x)).^2);

% Start
p0 = [1, 1, 0, 0];

% Optymalizacja
p = fminsearch(err, p0);

disp('Parametry [A, w, phi, C]:')
disp(p)

% Wykres
figure(1)
plot(x, y, 'o')
hold on
plot(x, model(p,x), '-r', 'LineWidth', 2)