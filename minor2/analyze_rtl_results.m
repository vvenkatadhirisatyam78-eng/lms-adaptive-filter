clc;
clear;
close all;

% =========================================================
% VIVADO RTL Q1.15 LMS RESULT ANALYSIS
% =========================================================

N = 1000;
Q = 32768;

fprintf('\n');
fprintf('============================================================\n');
fprintf('             VIVADO RTL Q1.15 LMS ANALYSIS\n');
fprintf('============================================================\n');

% =========================================================
% READ MEMORY FILES
% =========================================================

input_hex   = readlines('input_q15.mem');
desired_hex = readlines('desired_q15.mem');
output_hex  = readlines('rtl_output_q15.mem');

% Remove empty lines
input_hex   = input_hex(strlength(strtrim(input_hex)) > 0);
desired_hex = desired_hex(strlength(strtrim(desired_hex)) > 0);
output_hex  = output_hex(strlength(strtrim(output_hex)) > 0);

% Check number of samples
fprintf('\nInput samples   = %d\n', length(input_hex));
fprintf('Desired samples = %d\n', length(desired_hex));
fprintf('RTL outputs     = %d\n', length(output_hex));

if length(input_hex) ~= N
    error('Input file does not contain 1000 samples.');
end

if length(desired_hex) ~= N
    error('Desired file does not contain 1000 samples.');
end

if length(output_hex) ~= N
    error('RTL output file does not contain 1000 samples.');
end

% =========================================================
% HEX -> UNSIGNED DECIMAL
% =========================================================

input_u   = hex2dec(strtrim(input_hex));
desired_u = hex2dec(strtrim(desired_hex));
output_u  = hex2dec(strtrim(output_hex));

% =========================================================
% UNSIGNED -> SIGNED 16-BIT
% =========================================================

input_q15   = input_u;
desired_q15 = desired_u;
output_q15  = output_u;

input_q15(input_q15 >= 32768) = ...
    input_q15(input_q15 >= 32768) - 65536;

desired_q15(desired_q15 >= 32768) = ...
    desired_q15(desired_q15 >= 32768) - 65536;

output_q15(output_q15 >= 32768) = ...
    output_q15(output_q15 >= 32768) - 65536;

% Convert to double
input_q15   = double(input_q15);
desired_q15 = double(desired_q15);
output_q15  = double(output_q15);

% =========================================================
% Q1.15 -> REAL VALUES
% =========================================================

input_real   = input_q15 / Q;
desired_real = desired_q15 / Q;
output_real  = output_q15 / Q;

% =========================================================
% INPUT ERROR
%
% Difference between noisy input and desired signal
% =========================================================

input_error = desired_real - input_real;

% =========================================================
% RTL OUTPUT ERROR
%
% Difference between desired signal and RTL output
% =========================================================

output_error = desired_real - output_real;

% =========================================================
% MSE
% =========================================================

input_MSE = mean(input_error.^2);

output_MSE = mean(output_error.^2);

% =========================================================
% SIGNAL POWER
% =========================================================

signal_power = mean(desired_real.^2);

input_noise_power = mean(input_error.^2);

output_noise_power = mean(output_error.^2);

% =========================================================
% SNR
% =========================================================

input_SNR = 10 * log10(signal_power / input_noise_power);

output_SNR = 10 * log10(signal_power / output_noise_power);

% =========================================================
% SNR IMPROVEMENT
% =========================================================

SNR_improvement = output_SNR - input_SNR;

% =========================================================
% MAXIMUM ERROR
% =========================================================

max_input_error = max(abs(input_error));

max_output_error = max(abs(output_error));

% =========================================================
% DISPLAY RESULTS
% =========================================================

fprintf('\n');
fprintf('---------------- INPUT ----------------\n');

fprintf('Input MSE           = %.9f\n', input_MSE);
fprintf('Input SNR           = %.3f dB\n', input_SNR);

fprintf('\n');
fprintf('---------------- VIVADO RTL OUTPUT ----------------\n');

fprintf('Output MSE          = %.9f\n', output_MSE);
fprintf('Output SNR          = %.3f dB\n', output_SNR);
fprintf('SNR Improvement     = %.3f dB\n', SNR_improvement);

fprintf('\n');
fprintf('---------------- ERROR ----------------\n');

fprintf('Max input error     = %.9f\n', max_input_error);
fprintf('Max RTL output error= %.9f\n', max_output_error);

% =========================================================
% DISPLAY SELECTED SAMPLES
% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('                 SELECTED RTL RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');
fprintf('Sample      Input       Desired       RTL Output\n');
fprintf('-------------------------------------------------\n');

indices = [1 2 3 4 5 6 7 8 9 10 100 200 500 1000];

for k = 1:length(indices)

    i = indices(k);

    fprintf('%5d    %8d    %8d    %8d\n', ...
        i-1, ...
        round(input_q15(i)), ...
        round(desired_q15(i)), ...
        round(output_q15(i)));

end

% =========================================================
% PLOT 1
% =========================================================

figure;

plot(0:N-1, desired_real, 'LineWidth', 1);
hold on;
plot(0:N-1, input_real, 'LineWidth', 1);
plot(0:N-1, output_real, 'LineWidth', 1);

xlabel('Sample');
ylabel('Amplitude');

title('Vivado RTL LMS: Desired vs Input vs Output');

legend('Desired','Noisy Input','Vivado RTL Output');

grid on;

% =========================================================
% PLOT 2
% =========================================================

figure;

plot(0:N-1, input_error);

xlabel('Sample');
ylabel('Error');

title('Input Error');

grid on;

% =========================================================
% PLOT 3
% =========================================================

figure;

plot(0:N-1, output_error);

xlabel('Sample');
ylabel('Error');

title('Vivado RTL LMS Error');

grid on;

% =========================================================
% FINAL SUMMARY
% =========================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('                    FINAL RTL RESULT\n');
fprintf('============================================================\n');

fprintf('Number of samples  = %d\n', N);
fprintf('Q format            = Q1.15\n');
fprintf('Input MSE           = %.9f\n', input_MSE);
fprintf('RTL Output MSE      = %.9f\n', output_MSE);
fprintf('Input SNR           = %.3f dB\n', input_SNR);
fprintf('RTL Output SNR      = %.3f dB\n', output_SNR);
fprintf('SNR Improvement     = %.3f dB\n', SNR_improvement);

fprintf('============================================================\n');