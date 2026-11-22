clc;
clear;
close all;

% ------------------------------------------------
% COMMON PARAMETERS
% ------------------------------------------------

N = 1000;
M = 8;

n = 0:N-1;

% ------------------------------------------------
% SAME DESIRED SIGNAL AND NOISE FOR EVERY TEST
% ------------------------------------------------

rng(1);    % Fix random noise so comparison is fair

f = 0.05;

d = sin(2*pi*f*n);

noise = 0.5 * randn(1,N);

x = d + noise;

% ------------------------------------------------
% STEP-SIZE VALUES TO TEST
% ------------------------------------------------

mu_values = [0.001 0.005 0.01 0.02 0.05];

num_mu = length(mu_values);

% Storage for results
MSE_output = zeros(1,num_mu);
SNR_output = zeros(1,num_mu);
SNR_improvement = zeros(1,num_mu);

% ------------------------------------------------
% TEST EACH MU
% ------------------------------------------------

for m = 1:num_mu

    mu = mu_values(m);

    % Initialize coefficients
    w = zeros(M,1);

    % Output and error
    y = zeros(1,N);
    e = zeros(1,N);

    % LMS algorithm
    for k = M:N

        x_vec = x(k:-1:k-M+1).';

        % Filter output
        y(k) = w' * x_vec;

        % Error
        e(k) = d(k) - y(k);

        % Coefficient update
        w = w + mu * e(k) * x_vec;

    end

    % --------------------------------------------
    % PERFORMANCE AFTER CONVERGENCE
    % --------------------------------------------

    start_idx = 300;

    output_error = y(start_idx:end) - d(start_idx:end);

    input_error = x(start_idx:end) - d(start_idx:end);

    MSE_output(m) = mean(output_error.^2);

    input_MSE = mean(input_error.^2);

    SNR_output(m) = ...
        10*log10(mean(d(start_idx:end).^2) / MSE_output(m));

    input_SNR = ...
        10*log10(mean(d(start_idx:end).^2) / input_MSE);

    SNR_improvement(m) = SNR_output(m) - input_SNR;

end

% ------------------------------------------------
% DISPLAY RESULTS
% ------------------------------------------------

fprintf('\n========================================\n');
fprintf('       LMS STEP SIZE COMPARISON\n');
fprintf('========================================\n');

fprintf('\n   mu          MSE          SNR(dB)      Improvement(dB)\n');
fprintf('----------------------------------------------------------\n');

for m = 1:num_mu

    fprintf(' %.3f      %.6f       %.3f          %.3f\n', ...
        mu_values(m), ...
        MSE_output(m), ...
        SNR_output(m), ...
        SNR_improvement(m));

end

% ------------------------------------------------
% PLOT SNR IMPROVEMENT
% ------------------------------------------------

figure;

plot(mu_values, SNR_improvement, '-o');

xlabel('Step Size (\mu)');
ylabel('SNR Improvement (dB)');

title('LMS Performance vs Step Size');

grid on;