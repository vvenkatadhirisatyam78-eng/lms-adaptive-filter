clc;
clear;

%% Parameters
Q = 2^15;

%% Read Verilog HEX memory files
conventional_hex = read_verilog_mem('rtl_output_q15.mem');
optimized_hex    = read_verilog_mem('rtl_output_optimized_q15.mem');

%% Convert 16-bit two's-complement HEX to signed decimal

conventional_q15 = hex16_to_signed(conventional_hex);
optimized_q15    = hex16_to_signed(optimized_hex);

%% Limit to 1000 samples
N = min([1000, length(conventional_q15), length(optimized_q15)]);

conventional_q15 = conventional_q15(1:N);
optimized_q15    = optimized_q15(1:N);

%% Convert Q1.15 to floating point
conventional_float = conventional_q15 / Q;
optimized_float    = optimized_q15 / Q;

%% Read input and desired files
input_q15   = read_verilog_mem('input_q15.mem');
desired_q15 = read_verilog_mem('desired_q15.mem');

input_q15   = hex16_to_signed(input_q15);
desired_q15 = hex16_to_signed(desired_q15);

input_q15   = input_q15(1:N);
desired_q15 = desired_q15(1:N);

input_float   = input_q15 / Q;
desired_float = desired_q15 / Q;

%% MSE
mse_input = mean((desired_float - input_float).^2);

mse_conventional = mean((desired_float - conventional_float).^2);

mse_optimized = mean((desired_float - optimized_float).^2);

%% SNR
signal_power = mean(desired_float.^2);

snr_input = 10*log10(signal_power / mse_input);

snr_conventional = 10*log10(signal_power / mse_conventional);

snr_optimized = 10*log10(signal_power / mse_optimized);

%% SNR improvement
improvement_conventional = snr_conventional - snr_input;

improvement_optimized = snr_optimized - snr_input;

%% Direct comparison
difference = conventional_q15 - optimized_q15;

max_difference = max(abs(difference));

mean_absolute_difference = mean(abs(difference));

different_samples = sum(difference ~= 0);

%% Display
fprintf('\n');
fprintf('====================================================\n');
fprintf('   CONVENTIONAL 35-BIT vs OPTIMIZED 32-BIT LMS\n');
fprintf('====================================================\n');

fprintf('Number of samples              : %d\n', N);

fprintf('\nMSE RESULTS\n');
fprintf('Input MSE                      : %.9f\n', mse_input);
fprintf('Conventional 35-bit MSE        : %.9f\n', mse_conventional);
fprintf('Optimized 32-bit MSE           : %.9f\n', mse_optimized);

fprintf('\nSNR RESULTS\n');
fprintf('Input SNR                      : %.3f dB\n', snr_input);
fprintf('Conventional 35-bit SNR        : %.3f dB\n', snr_conventional);
fprintf('Optimized 32-bit SNR           : %.3f dB\n', snr_optimized);

fprintf('\nSNR IMPROVEMENT\n');
fprintf('Conventional 35-bit            : %.3f dB\n', improvement_conventional);
fprintf('Optimized 32-bit               : %.3f dB\n', improvement_optimized);

fprintf('\nDIRECT RTL OUTPUT COMPARISON\n');
fprintf('Maximum output difference      : %d\n', max_difference);
fprintf('Mean absolute difference       : %.6f\n', mean_absolute_difference);
fprintf('Different samples              : %d / %d\n', ...
    different_samples, N);

fprintf('\n');

if max_difference == 0 && different_samples == 0
    fprintf('RESULT: EXACT FUNCTIONAL EQUIVALENCE PASS\n');
else
    fprintf('RESULT: OUTPUT MISMATCH - CHECK RTL\n');
end

fprintf('====================================================\n');


%% ====================================================
%  Local functions
%  ====================================================

function hex_values = read_verilog_mem(filename)

    fid = fopen(filename, 'r');

    if fid == -1
        error('Cannot open file: %s', filename);
    end

    hex_values = {};

    while ~feof(fid)

        line = strtrim(fgetl(fid));

        % Skip empty lines
        if isempty(line)
            continue;
        end

        % Skip Verilog comments/address markers
        if startsWith(line, '//')
            continue;
        end

        % Keep only hexadecimal memory words
        if ~isempty(regexp(line, '^[0-9a-fA-F]+$', 'once'))
            hex_values{end+1,1} = line;
        end

    end

    fclose(fid);

end


function signed_values = hex16_to_signed(hex_values)

    signed_values = zeros(length(hex_values),1);

    for k = 1:length(hex_values)

        value = hex2dec(hex_values{k});

        % Convert 16-bit two's complement
        if value >= 32768
            value = value - 65536;
        end

        signed_values(k) = value;

    end

end