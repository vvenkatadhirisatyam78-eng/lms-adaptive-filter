clc;
clear;
close all;

%% =========================================================
%  COMPARE CONVENTIONAL LMS vs 32-BIT OPTIMIZED LMS
% ==========================================================

N = 1000;

%% Read input files

input_hex = readlines('input_q15.mem');
desired_hex = readlines('desired_q15.mem');

conv_hex = readlines('rtl_output_q15.mem');
opt_hex  = readlines('rtl_output_optimized_q15.mem');

%% Convert hexadecimal Q1.15 data to signed decimal

input_int  = hex2dec(input_hex);
desired_int = hex2dec(desired_hex);
conv_int   = hex2dec(conv_hex);
opt_int    = hex2dec(opt_hex);

%% Convert unsigned 16-bit values to signed 16-bit

input_int(input_int >= 32768) = input_int(input_int >= 32768) - 65536;
desired_int(desired_int >= 32768) = desired_int(desired_int >= 32768) - 65536;
conv_int(conv_int >= 32768) = conv_int(conv_int >= 32768) - 65536;
opt_int(opt_int >= 32768) = opt_int(opt_int >= 32768) - 65536;

%% Convert Q1.15 to real values

input_real   = input_int / 32768;
desired_real = desired_int / 32768;
conv_real    = conv_int / 32768;
opt_real     = opt_int / 32768;

%% =========================================================
%  MSE CALCULATIONS
% ==========================================================

input_mse = mean((desired_real - input_real).^2);

conv_mse = mean((desired_real - conv_real).^2);

opt_mse = mean((desired_real - opt_real).^2);

%% =========================================================
%  SNR CALCULATIONS
% ==========================================================

signal_power = mean(desired_real.^2);

input_noise_power = mean((desired_real - input_real).^2);
conv_noise_power  = mean((desired_real - conv_real).^2);
opt_noise_power   = mean((desired_real - opt_real).^2);

input_snr = 10 * log10(signal_power / input_noise_power);

conv_snr = 10 * log10(signal_power / conv_noise_power);

opt_snr = 10 * log10(signal_power / opt_noise_power);

%% =========================================================
%  SNR IMPROVEMENT
% ==========================================================

conv_snr_improvement = conv_snr - input_snr;

opt_snr_improvement = opt_snr - input_snr;

%% =========================================================
%  DIFFERENCE BETWEEN CONVENTIONAL AND OPTIMIZED
% ==========================================================

difference = conv_real - opt_real;

max_difference = max(abs(difference));

mean_difference = mean(abs(difference));

num_different = sum(conv_int ~= opt_int);

%% =========================================================
%  MSE DIFFERENCE
% ==========================================================

mse_difference = opt_mse - conv_mse;

mse_difference_percent = ...
    (abs(opt_mse - conv_mse) / conv_mse) * 100;

%% =========================================================
%  DISPLAY RESULTS
% ==========================================================

fprintf('\n');
fprintf('=====================================================\n');
fprintf(' CONVENTIONAL vs 32-BIT OPTIMIZED LMS\n');
fprintf('=====================================================\n');

fprintf('\n--- MSE RESULTS ---\n');

fprintf('Input MSE              = %.9f\n', input_mse);
fprintf('Conventional LMS MSE   = %.9f\n', conv_mse);
fprintf('Optimized LMS MSE      = %.9f\n', opt_mse);

fprintf('\n--- SNR RESULTS ---\n');

fprintf('Input SNR              = %.3f dB\n', input_snr);
fprintf('Conventional LMS SNR   = %.3f dB\n', conv_snr);
fprintf('Optimized LMS SNR      = %.3f dB\n', opt_snr);

fprintf('\n--- SNR IMPROVEMENT ---\n');

fprintf('Conventional improvement = %.3f dB\n', ...
    conv_snr_improvement);

fprintf('Optimized improvement    = %.3f dB\n', ...
    opt_snr_improvement);

fprintf('\n--- OUTPUT DIFFERENCE ---\n');

fprintf('Maximum output difference = %.9f\n', ...
    max_difference);

fprintf('Mean absolute difference  = %.9f\n', ...
    mean_difference);

fprintf('Number of different samples = %d / %d\n', ...
    num_different, N);

fprintf('\n--- MSE DIFFERENCE ---\n');

fprintf('Optimized - Conventional MSE = %.9f\n', ...
    mse_difference);

fprintf('MSE difference percentage    = %.6f %%\n', ...
    mse_difference_percent);

fprintf('\n=====================================================\n');

%% =========================================================
%  SELECTED SAMPLE COMPARISON
% ==========================================================

samples = [0 1 2 3 4 5 6 7 8 9 99 199 499 999];

fprintf('\n');
fprintf('SELECTED SAMPLE COMPARISON\n');
fprintf('-----------------------------------------------------\n');
fprintf('Sample    Conventional    Optimized    Difference\n');
fprintf('-----------------------------------------------------\n');

for k = 1:length(samples)

    idx = samples(k) + 1;

    fprintf('%4d      %10d      %10d      %10d\n', ...
        samples(k), ...
        conv_int(idx), ...
        opt_int(idx), ...
        conv_int(idx) - opt_int(idx));

end

fprintf('-----------------------------------------------------\n');

%% =========================================================
%  PLOT OUTPUT COMPARISON
% ==========================================================

figure;

plot(desired_real, 'LineWidth', 1);
hold on;
plot(input_real, 'LineWidth', 1);
plot(conv_real, 'LineWidth', 1);
plot(opt_real, '--', 'LineWidth', 1);

grid on;

xlabel('Sample');
ylabel('Amplitude');

title('Conventional vs 32-Bit Optimized LMS');

legend('Desired', ...
       'Noisy Input', ...
       'Conventional LMS', ...
       'Optimized LMS');

%% =========================================================
%  PLOT DIFFERENCE
% ==========================================================

figure;

plot(difference);

grid on;

xlabel('Sample');
ylabel('Difference');

title('Difference: Conventional LMS - Optimized LMS');
