clc;
clear;
close all;

% ------------------------------------------------
% LMS PARAMETERS
% ------------------------------------------------

N = 1000;       % Number of samples
M = 8;          % Number of LMS taps
mu = 0.01;      % Step size

n = 0:N-1;      % Sample index

% ------------------------------------------------
% GENERATE DESIRED SIGNAL
% ------------------------------------------------

f = 0.05;

d = sin(2*pi*f*n);

% ------------------------------------------------
% GENERATE NOISE
% ------------------------------------------------

noise = 0.5 * randn(1,N);

% Noisy input
x = d + noise;

% ------------------------------------------------
% INITIALIZE LMS
% ------------------------------------------------

w = zeros(M,1);

y = zeros(1,N);
e = zeros(1,N);

% Store coefficient history
W = zeros(M,N);

% ------------------------------------------------
% LMS ALGORITHM
% ------------------------------------------------

for k = M:N

    % Current sample + previous 7 samples
    x_vec = x(k:-1:k-M+1).';

    % Filter output
    y(k) = w' * x_vec;

    % Error
    e(k) = d(k) - y(k);

    % LMS coefficient update
    w = w + mu * e(k) * x_vec;

    % Store coefficients
    W(:,k) = w;

end

% ------------------------------------------------
% PLOT 1: DESIRED, NOISY INPUT AND LMS OUTPUT
% ------------------------------------------------

figure;

plot(n,d);
hold on;
plot(n,x);
plot(n,y);

legend('Desired','Noisy Input','LMS Output');

xlabel('Sample');
ylabel('Amplitude');

title('8-Tap LMS Filter');

grid on;

% ------------------------------------------------
% PLOT 2: ERROR
% ------------------------------------------------

figure;

plot(n,e);

xlabel('Sample');
ylabel('Error');

title('LMS Error Signal');

grid on;

% ------------------------------------------------
% PLOT 3: COEFFICIENT CONVERGENCE
% ------------------------------------------------

figure;

plot(n,W.');

xlabel('Sample');
ylabel('Coefficient Value');

title('LMS Coefficient Adaptation');

legend('w0','w1','w2','w3','w4','w5','w6','w7');

grid on;clc;
clear;
close all;

% ------------------------------------------------
% LMS PARAMETERS
% ------------------------------------------------

N = 1000;       % Number of samples
M = 8;          % Number of LMS taps
mu = 0.01;      % Step size

n = 0:N-1;      % Sample index

% ------------------------------------------------
% GENERATE DESIRED SIGNAL
% ------------------------------------------------

f = 0.05;

d = sin(2*pi*f*n);

% ------------------------------------------------
% GENERATE NOISE
% ------------------------------------------------

noise = 0.5 * randn(1,N);

% Noisy input
x = d + noise;

% ------------------------------------------------
% INITIALIZE LMS
% ------------------------------------------------

w = zeros(M,1);

y = zeros(1,N);
e = zeros(1,N);

% Store coefficient history
W = zeros(M,N);

% ------------------------------------------------
% LMS ALGORITHM
% ------------------------------------------------

for k = M:N

    % Current sample + previous 7 samples
    x_vec = x(k:-1:k-M+1).';

    % Filter output
    y(k) = w' * x_vec;

    % Error
    e(k) = d(k) - y(k);

    % LMS coefficient update
    w = w + mu * e(k) * x_vec;

    % Store coefficients
    W(:,k) = w;

end

% ------------------------------------------------
% PLOT 1: DESIRED, NOISY INPUT AND LMS OUTPUT
% ------------------------------------------------

figure;

plot(n,d);
hold on;
plot(n,x);
plot(n,y);

legend('Desired','Noisy Input','LMS Output');

xlabel('Sample');
ylabel('Amplitude');

title('8-Tap LMS Filter');

grid on;

% ------------------------------------------------
% PLOT 2: ERROR
% ------------------------------------------------

figure;

plot(n,e);

xlabel('Sample');
ylabel('Error');

title('LMS Error Signal');

grid on;

% ------------------------------------------------
% PLOT 3: COEFFICIENT CONVERGENCE
% ------------------------------------------------

figure;

plot(n,W.');

xlabel('Sample');
ylabel('Coefficient Value');

title('LMS Coefficient Adaptation');

legend('w0','w1','w2','w3','w4','w5','w6','w7');

grid on;

% ------------------------------------------------
% PERFORMANCE ANALYSIS
% ------------------------------------------------

% Ignore initial adaptation period
start_idx = 300;

% Input error relative to desired signal
input_error = x(start_idx:end) - d(start_idx:end);

% LMS output error relative to desired signal
output_error = y(start_idx:end) - d(start_idx:end);

% Mean square error
MSE_input = mean(input_error.^2);
MSE_output = mean(output_error.^2);

% SNR before filtering
SNR_input = 10*log10(mean(d(start_idx:end).^2) / MSE_input);

% SNR after filtering
SNR_output = 10*log10(mean(d(start_idx:end).^2) / MSE_output);

% Improvement
SNR_improvement = SNR_output - SNR_input;

fprintf('\n----- LMS PERFORMANCE -----\n');
fprintf('Input MSE  = %.6f\n', MSE_input);
fprintf('Output MSE = %.6f\n', MSE_output);
fprintf('Input SNR  = %.3f dB\n', SNR_input);
fprintf('Output SNR = %.3f dB\n', SNR_output);
fprintf('SNR Improvement = %.3f dB\n', SNR_improvement);