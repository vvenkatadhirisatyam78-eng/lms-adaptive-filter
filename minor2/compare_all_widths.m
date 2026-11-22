clc;
clear;
close all;

%% Number of samples
N = 1000;

%% Read input and desired signals
input_hex   = readlines('input_q15.mem');
desired_hex = readlines('desired_q15.mem');

%% Read RTL outputs
out35_hex = readlines('rtl_output_q15.mem');
out34_hex = readlines('rtl_output_34_q15.mem');
out33_hex = readlines('rtl_output_33_q15.mem');
out32_hex = readlines('rtl_output_optimized_q15.mem');

%% Convert hexadecimal to signed 16-bit integers
input_int   = typecast(uint16(hex2dec(input_hex)), 'int16');
desired_int = typecast(uint16(hex2dec(desired_hex)), 'int16');

out35_int = typecast(uint16(hex2dec(out35_hex)), 'int16');
out34_int = typecast(uint16(hex2dec(out34_hex)), 'int16');
out33_int = typecast(uint16(hex2dec(out33_hex)), 'int16');
out32_int = typecast(uint16(hex2dec(out32_hex)), 'int16');

%% Convert Q1.15 integers to real values
input_real   = double(input_int) / 2^15;
desired_real = double(desired_int) / 2^15;

out35 = double(out35_int) / 2^15;
out34 = double(out34_int) / 2^15;
out33 = double(out33_int) / 2^15;
out32 = double(out32_int) / 2^15;

%% Calculate input MSE
input_mse = mean((desired_real - input_real).^2);

%% Calculate MSE for each width
mse35 = mean((desired_real - out35).^2);
mse34 = mean((desired_real - out34).^2);
mse33 = mean((desired_real - out33).^2);
mse32 = mean((desired_real - out32).^2);

%% Calculate SNR
input_snr = 10*log10(mean(desired_real.^2) / input_mse);

snr35 = 10*log10(mean(desired_real.^2) / mse35);
snr34 = 10*log10(mean(desired_real.^2) / mse34);
snr33 = 10*log10(mean(desired_real.^2) / mse33);
snr32 = 10*log10(mean(desired_real.^2) / mse32);

%% SNR improvement
imp35 = snr35 - input_snr;
imp34 = snr34 - input_snr;
imp33 = snr33 - input_snr;
imp32 = snr32 - input_snr;

%% Compare each width against conventional 35-bit output

diff34 = out35 - out34;
diff33 = out35 - out33;
diff32 = out35 - out32;

maxdiff34 = max(abs(diff34));
maxdiff33 = max(abs(diff33));
maxdiff32 = max(abs(diff32));

mad34 = mean(abs(diff34));
mad33 = mean(abs(diff33));
mad32 = mean(abs(diff32));

different34 = sum(diff34 ~= 0);
different33 = sum(diff33 ~= 0);
different32 = sum(diff32 ~= 0);

%% Percentage of different samples
percent34 = (different34/N)*100;
percent33 = (different33/N)*100;
percent32 = (different32/N)*100;

%% Display results
fprintf('\n=============================================\n');
fprintf('       LMS ACCUMULATOR WIDTH COMPARISON\n');
fprintf('=============================================\n');

fprintf('\nInput Signal:\n');
fprintf('Input MSE       = %.9f\n', input_mse);
fprintf('Input SNR       = %.3f dB\n', input_snr);

fprintf('\n---------------------------------------------\n');
fprintf('Width       MSE          SNR(dB)    Improvement\n');
fprintf('---------------------------------------------\n');
fprintf('35-bit   %.9f     %.3f       %.3f dB\n', mse35, snr35, imp35);
fprintf('34-bit   %.9f     %.3f       %.3f dB\n', mse34, snr34, imp34);
fprintf('33-bit   %.9f     %.3f       %.3f dB\n', mse33, snr33, imp33);
fprintf('32-bit   %.9f     %.3f       %.3f dB\n', mse32, snr32, imp32);

fprintf('\n=============================================\n');
fprintf('Comparison Against 35-bit Conventional\n');
fprintf('=============================================\n');

fprintf('\n34-bit:\n');
fprintf('Maximum difference       = %.9f\n', maxdiff34);
fprintf('Mean absolute difference = %.9f\n', mad34);
fprintf('Different samples        = %d / %d\n', different34, N);
fprintf('Percentage different     = %.3f %%\n', percent34);

fprintf('\n33-bit:\n');
fprintf('Maximum difference       = %.9f\n', maxdiff33);
fprintf('Mean absolute difference = %.9f\n', mad33);
fprintf('Different samples        = %d / %d\n', different33, N);
fprintf('Percentage different     = %.3f %%\n', percent33);

fprintf('\n32-bit:\n');
fprintf('Maximum difference       = %.9f\n', maxdiff32);
fprintf('Mean absolute difference = %.9f\n', mad32);
fprintf('Different samples        = %d / %d\n', different32, N);
fprintf('Percentage different     = %.3f %%\n', percent32);

%% Exact equality check
fprintf('\n=============================================\n');
fprintf('Exact Output Equality\n');
fprintf('=============================================\n');

fprintf('34-bit == 35-bit : %s\n', string(isequal(out34_int,out35_int)));
fprintf('33-bit == 35-bit : %s\n', string(isequal(out33_int,out35_int)));
fprintf('32-bit == 35-bit : %s\n', string(isequal(out32_int,out35_int)));

%% Plot outputs
figure;
plot(desired_real);
hold on;
plot(out35);
plot(out34);
plot(out33);
plot(out32);
grid on;

legend('Desired','35-bit','34-bit','33-bit','32-bit');
xlabel('Sample');
ylabel('Amplitude');
title('LMS Output Comparison');