clc;
clear;
close all;

% ============================================================
% 8-TAP LMS FILTER
% Step-Size, Convergence, MSE and SNR Analysis
% ============================================================

% ------------------------------------------------------------
% 1. COMMON PARAMETERS
% ------------------------------------------------------------

N = 1000;              % Number of samples
M = 8;                 % Number of LMS taps

n = 0:N-1;             % Sample index

% ------------------------------------------------------------
% 2. GENERATE SAME SIGNAL AND NOISE FOR EVERY MU
% ------------------------------------------------------------

rng(1);                % Fixed random seed

f = 0.05;              % Normalized frequency

% Desired signal
d = sin(2*pi*f*n);

% Noise
noise = 0.5 * randn(1,N);

% Noisy input
x = d + noise;

% ------------------------------------------------------------
% 3. STEP-SIZE VALUES
% ------------------------------------------------------------

mu_values = [0.010 0.015625 0.020 0.03125 0.050];

num_mu = length(mu_values);

% ------------------------------------------------------------
% 4. RESULT STORAGE
% ------------------------------------------------------------

error_history = zeros(num_mu,N);

W_all = zeros(M,N,num_mu);

MSE_output = zeros(1,num_mu);

SNR_output = zeros(1,num_mu);

SNR_improvement = zeros(1,num_mu);

convergence_sample = zeros(1,num_mu);

final_mse = zeros(1,num_mu);

% Also store LMS outputs
Y_all = zeros(num_mu,N);

% ------------------------------------------------------------
% 5. RUN LMS FOR EACH MU
% ------------------------------------------------------------

for m = 1:num_mu

    % Current step size
    mu = mu_values(m);

    % Initialize coefficients
    w = zeros(M,1);

    % Initialize output and error
    y = zeros(1,N);
    e = zeros(1,N);

    % --------------------------------------------------------
    % LMS ITERATION
    % --------------------------------------------------------

    for k = M:N

        % Current 8-sample vector
        x_vec = x(k:-1:k-M+1).';

        % Filter output
        y(k) = w' * x_vec;

        % Error
        e(k) = d(k) - y(k);

        % LMS coefficient update
        w = w + mu * e(k) * x_vec;

        % Store coefficients
        W_all(:,k,m) = w;

    end

    % Store output
    Y_all(m,:) = y;

    % Store squared error
    error_history(m,:) = e.^2;

end

% ============================================================
% 6. SMOOTHED MSE CURVE
% ============================================================

window = 50;

mse_curve = zeros(num_mu,N);

for m = 1:num_mu

    mse_curve(m,:) = movmean(error_history(m,:),window);

end

% ============================================================
% 7. NUMERICAL CONVERGENCE ANALYSIS
% ============================================================

% Convergence criterion:
% Smoothed MSE reaches within 10% of the final
% steady-state MSE and remains there for 100 samples.

convergence_threshold = 1.10;

for m = 1:num_mu

    % Final steady-state MSE
    final_mse(m) = mean(mse_curve(m,end-99:end));

    % Convergence limit
    threshold = convergence_threshold * final_mse(m);

    % Find convergence sample
    for k = 1:N-99

        if all(mse_curve(m,k:k+99) <= threshold)

            convergence_sample(m) = k;

            break;

        end

    end

end

% ============================================================
% 8. MSE AND SNR PERFORMANCE
% ============================================================

% Ignore initial adaptation period
start_idx = 300;

% ------------------------------------------------------------
% Input performance
% ------------------------------------------------------------

input_error = x(start_idx:end) - d(start_idx:end);

input_MSE = mean(input_error.^2);

input_SNR = 10 * log10( ...
    mean(d(start_idx:end).^2) / input_MSE);

% ------------------------------------------------------------
% LMS performance for each mu
% ------------------------------------------------------------

for m = 1:num_mu

    % LMS output
    y = Y_all(m,:);

    % Output error relative to desired signal
    output_error = y(start_idx:end) - d(start_idx:end);

    % Output MSE
    MSE_output(m) = mean(output_error.^2);

    % Output SNR
    SNR_output(m) = 10 * log10( ...
        mean(d(start_idx:end).^2) / MSE_output(m));

    % SNR improvement
    SNR_improvement(m) = ...
        SNR_output(m) - input_SNR;

end

% ============================================================
% 9. DISPLAY CONVERGENCE RESULTS
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('             LMS CONVERGENCE ANALYSIS\n');
fprintf('============================================================\n');

fprintf('\n');
fprintf('   mu          Final MSE       Convergence Sample\n');
fprintf('------------------------------------------------------------\n');

for m = 1:num_mu

    fprintf(' %.6f       %.6f              %d\n', ...
        mu_values(m), ...
        final_mse(m), ...
        convergence_sample(m));

end

% ============================================================
% 10. DISPLAY MSE AND SNR RESULTS
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('             LMS PERFORMANCE ANALYSIS\n');
fprintf('============================================================\n');

fprintf('\n');
fprintf('Input MSE  = %.6f\n', input_MSE);
fprintf('Input SNR  = %.3f dB\n', input_SNR);

fprintf('\n');
fprintf('   mu          Output MSE      Output SNR     SNR Improvement\n');
fprintf('------------------------------------------------------------\n');

for m = 1:num_mu

    fprintf(' %.6f       %.6f        %.3f dB          %.3f dB\n', ...
        mu_values(m), ...
        MSE_output(m), ...
        SNR_output(m), ...
        SNR_improvement(m));

end

% ============================================================
% 11. PLOT 1 — LINEAR CONVERGENCE
% ============================================================

figure;

for m = 1:num_mu

    plot(n,mse_curve(m,:),'LineWidth',1.2);
    hold on;

end

xlabel('Sample');

ylabel('Smoothed Squared Error');

title('8-Tap LMS Convergence for Different Step Sizes');

legend( ...
    '\mu = 0.010', ...
    '\mu = 0.015625', ...
    '\mu = 0.020', ...
    '\mu = 0.03125', ...
    '\mu = 0.050');

grid on;

% ============================================================
% 12. PLOT 2 — LOG-SCALE CONVERGENCE
% ============================================================

figure;

for m = 1:num_mu

    semilogy(n,mse_curve(m,:),'LineWidth',1.2);
    hold on;

end

xlabel('Sample');

ylabel('Smoothed Squared Error');

title('8-Tap LMS Convergence - Log Scale');

legend( ...
    '\mu = 0.010', ...
    '\mu = 0.015625', ...
    '\mu = 0.020', ...
    '\mu = 0.03125', ...
    '\mu = 0.050');

grid on;

% ============================================================
% 13. PLOT 3 — SNR IMPROVEMENT
% ============================================================

figure;

plot(mu_values,SNR_improvement,'-o','LineWidth',1.2);

xlabel('Step Size (\mu)');

ylabel('SNR Improvement (dB)');

title('LMS SNR Improvement vs Step Size');

grid on;

% ============================================================
% 14. PLOT 4 — OUTPUT MSE
% ============================================================

figure;

plot(mu_values,MSE_output,'-o','LineWidth',1.2);

xlabel('Step Size (\mu)');

ylabel('Output MSE');

title('LMS Output MSE vs Step Size');

grid on;

% ============================================================
% 15. PLOT 5 — CONVERGENCE SAMPLE
% ============================================================

figure;

plot(mu_values,convergence_sample,'-o','LineWidth',1.2);

xlabel('Step Size (\mu)');

ylabel('Convergence Sample');

title('LMS Convergence Speed vs Step Size');

grid on;