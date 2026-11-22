clc;
clear;
close all;

% Number of samples
N = 2000;

% LMS parameters
M = 8;              % Filter order
mu = 0.01;          % Step size

% Create a useful signal
n = 0:N-1;
signal = sin(2*pi*0.05*n);

% Create noise
noise = 0.5*sin(2*pi*0.2*n);

% Primary input = signal + noise
d = signal + noise;

% Reference input = noise
x = noise;

% Initialize filter coefficients
w = zeros(M,1);

% Initialize output and error
y = zeros(1,N);
e = zeros(1,N);

% LMS algorithm
for n = M:N

    % Input vector
    x_vec = x(n:-1:n-M+1)';

    % Filter output / estimated noise
    y(n) = w' * x_vec;

    % Error / cleaned signal
    e(n) = d(n) - y(n);

    % LMS coefficient update
    w = w + mu * e(n) * x_vec;

end

% Plot results
figure;

subplot(3,1,1);
plot(d);
title('Noisy Signal d(n)');
xlabel('Sample');
ylabel('Amplitude');

subplot(3,1,2);
plot(y);
title('Estimated Noise y(n)');
xlabel('Sample');
ylabel('Amplitude');

subplot(3,1,3);
plot(e);
title('Filtered / Cleaned Signal e(n)');
xlabel('Sample');
ylabel('Amplitude');