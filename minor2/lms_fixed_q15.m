clc;
clear;
close all;

% ============================================================
% 8-TAP LMS FILTER
% FLOATING-POINT vs FIXED-POINT Q1.15
% ============================================================

% ------------------------------------------------------------
% 1. PARAMETERS
% ------------------------------------------------------------

N = 1000;              % Number of samples
M = 8;                 % Number of LMS taps

FRAC_BITS = 15;        % Q1.15 fractional bits

% Selected hardware-friendly step size
%
% mu = 1/32 = 2^-5
%
MU_SHIFT = 5;

n = 0:N-1;

% ------------------------------------------------------------
% 2. GENERATE TEST SIGNAL
% ------------------------------------------------------------

rng(1);                % Fixed seed for repeatable experiment

f = 0.05;

% Desired signal
d_float = sin(2*pi*f*n);

% Noise
noise_float = 0.5 * randn(1,N);

% Noisy input
x_float = d_float + noise_float;

% ------------------------------------------------------------
% 3. SCALE SIGNAL TO FIT Q1.15
% ------------------------------------------------------------
%
% Q1.15 range is approximately:
%
% -1 <= x <= 0.999969
%
% The noisy signal can naturally exceed this range.
% Therefore, scale both desired and noisy signals by
% the same factor.
%
% 0.8 is used to leave headroom.

scale_factor = 0.8 / max(abs(x_float));

x_float = x_float * scale_factor;

d_float = d_float * scale_factor;

% ------------------------------------------------------------
% CHECK SIGNAL RANGE
% ------------------------------------------------------------

fprintf('\n=============================================\n');
fprintf('             INPUT RANGE CHECK\n');
fprintf('=============================================\n');

fprintf('Scale factor       = %.6f\n', scale_factor);
fprintf('Maximum |x|        = %.6f\n', max(abs(x_float)));
fprintf('Maximum |d|        = %.6f\n', max(abs(d_float)));

% ============================================================
% 4. FLOATING-POINT LMS REFERENCE
% ============================================================

w_float = zeros(M,1);

y_float = zeros(1,N);

e_float = zeros(1,N);

W_float = zeros(M,N);

mu = 1/32;

for k = M:N

    % Current 8-sample input vector
    x_vec = x_float(k:-1:k-M+1).';

    % Filter output
    y_float(k) = w_float' * x_vec;

    % Error
    e_float(k) = d_float(k) - y_float(k);

    % LMS coefficient update
    w_float = w_float + mu * e_float(k) * x_vec;

    % Store coefficients
    W_float(:,k) = w_float;

end

% ============================================================
% 5. CONVERT INPUT SIGNALS TO Q1.15
% ============================================================

d_q15 = q15_quantize(d_float);

x_q15 = q15_quantize(x_float);

% ============================================================
% 6. FIXED-POINT LMS INITIALIZATION
% ============================================================

% Coefficients stored as signed integers
% representing Q1.15 values.

w_q15 = zeros(M,1,'int64');

% Output
y_q15 = zeros(1,N,'int64');

% Error
%
% Error is intentionally kept wider internally because
% d - y can exceed the normal Q1.15 range.

e_q15 = zeros(1,N,'int64');

% Coefficient history
W_q15 = zeros(M,N);

% ============================================================
% 7. FIXED-POINT LMS
% ============================================================

for k = M:N

    % --------------------------------------------------------
    % Current 8-sample vector
    % --------------------------------------------------------

    x_vec = int64(x_q15(k:-1:k-M+1)).';

    % --------------------------------------------------------
    % FILTER OUTPUT
    %
    % Q1.15 x Q1.15
    %
    %       ↓
    %
    % 30 fractional bits
    % --------------------------------------------------------

    accumulator = int64(0);

    for i = 1:M

        product = w_q15(i) * x_vec(i);

        accumulator = accumulator + product;

    end

    % --------------------------------------------------------
    % Convert accumulated product back toward Q1.15
    %
    % 30 fractional bits -> 15 fractional bits
    %
    % Therefore shift right by 15.
    % --------------------------------------------------------

    y_temp = bitsra(accumulator,FRAC_BITS);

    % Saturate output to Q1.15
    y_q15(k) = saturate_q15(y_temp);

    % --------------------------------------------------------
    % ERROR
    %
    % e = d - y
    %
    % Both d and y have 15 fractional bits.
    % Keep the result in int64 internally.
    % --------------------------------------------------------

    e_q15(k) = int64(d_q15(k)) - y_q15(k);

    % --------------------------------------------------------
    % COEFFICIENT UPDATE
    %
    % w(n+1) = w(n) + mu*e(n)*x(n)
    %
    % mu = 1/32 = 2^-5
    %
    % e*x:
    %
    % 15 + 15 = 30 fractional bits
    %
    % To return to Q1.15:
    %
    % 30 - 15 = 15-bit shift
    %
    % Applying mu = 2^-5:
    %
    % additional 5-bit shift
    %
    % Total:
    %
    % 15 + 5 = 20
    % --------------------------------------------------------

    for i = 1:M

        correction_product = e_q15(k) * x_vec(i);

        correction = bitsra( ...
            correction_product, ...
            FRAC_BITS + MU_SHIFT);

        % Update coefficient
        w_q15(i) = w_q15(i) + correction;

        % Saturate coefficient
        w_q15(i) = saturate_q15(w_q15(i));

    end

    % Convert coefficient to decimal for plotting
    W_q15(:,k) = double(w_q15) / 2^FRAC_BITS;

end

% ============================================================
% 8. CONVERT FIXED-POINT RESULTS BACK TO DECIMAL
% ============================================================

d_fixed = double(d_q15) / 2^FRAC_BITS;

x_fixed = double(x_q15) / 2^FRAC_BITS;

y_fixed = double(y_q15) / 2^FRAC_BITS;

e_fixed = double(e_q15) / 2^FRAC_BITS;

% ============================================================
% 9. PERFORMANCE ANALYSIS
% ============================================================

% Ignore initial adaptation period
start_idx = 300;

% ------------------------------------------------------------
% Floating-point performance
% ------------------------------------------------------------

input_error_float = ...
    x_float(start_idx:end) - d_float(start_idx:end);

output_error_float = ...
    y_float(start_idx:end) - d_float(start_idx:end);

input_MSE_float = mean(input_error_float.^2);

output_MSE_float = mean(output_error_float.^2);

input_SNR_float = 10*log10( ...
    mean(d_float(start_idx:end).^2) / input_MSE_float);

output_SNR_float = 10*log10( ...
    mean(d_float(start_idx:end).^2) / output_MSE_float);

SNR_improvement_float = ...
    output_SNR_float - input_SNR_float;

% ------------------------------------------------------------
% Fixed-point performance
% ------------------------------------------------------------

input_error_fixed = ...
    x_fixed(start_idx:end) - d_fixed(start_idx:end);

output_error_fixed = ...
    y_fixed(start_idx:end) - d_fixed(start_idx:end);

input_MSE_fixed = mean(input_error_fixed.^2);

output_MSE_fixed = mean(output_error_fixed.^2);

input_SNR_fixed = 10*log10( ...
    mean(d_fixed(start_idx:end).^2) / input_MSE_fixed);

output_SNR_fixed = 10*log10( ...
    mean(d_fixed(start_idx:end).^2) / output_MSE_fixed);

SNR_improvement_fixed = ...
    output_SNR_fixed - input_SNR_fixed;

% ============================================================
% 10. FIXED-POINT QUANTIZATION ERROR
% ============================================================

input_quantization_error = ...
    x_fixed - x_float;

desired_quantization_error = ...
    d_fixed - d_float;

max_input_quantization_error = ...
    max(abs(input_quantization_error));

max_desired_quantization_error = ...
    max(abs(desired_quantization_error));

% ============================================================
% 11. MAXIMUM COEFFICIENT VALUE
% ============================================================

max_coefficient_float = max(abs(W_float(:)));

max_coefficient_fixed = max(abs(W_q15(:)));

% ============================================================
% 12. DISPLAY MAIN RESULTS
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('             LMS Q1.15 FIXED-POINT RESULTS\n');
fprintf('============================================================\n');

fprintf('\n');
fprintf('Number of taps          = %d\n',M);
fprintf('Input/coeff format      = Q1.15\n');
fprintf('Fractional bits         = %d\n',FRAC_BITS);
fprintf('Step size               = 1/32 = %.6f\n',mu);
fprintf('Step-size implementation= Right shift by %d\n',MU_SHIFT);

% ------------------------------------------------------------
% Floating-point results
% ------------------------------------------------------------

fprintf('\n');
fprintf('---------------- FLOATING-POINT ----------------\n');

fprintf('Input MSE               = %.6f\n',input_MSE_float);
fprintf('Output MSE              = %.6f\n',output_MSE_float);

fprintf('Input SNR               = %.3f dB\n',input_SNR_float);
fprintf('Output SNR              = %.3f dB\n',output_SNR_float);

fprintf('SNR Improvement         = %.3f dB\n', ...
    SNR_improvement_float);

% ------------------------------------------------------------
% Fixed-point results
% ------------------------------------------------------------

fprintf('\n');
fprintf('---------------- FIXED-POINT Q1.15 -------------\n');

fprintf('Input MSE               = %.6f\n',input_MSE_fixed);
fprintf('Output MSE              = %.6f\n',output_MSE_fixed);

fprintf('Input SNR               = %.3f dB\n',input_SNR_fixed);
fprintf('Output SNR              = %.3f dB\n',output_SNR_fixed);

fprintf('SNR Improvement         = %.3f dB\n', ...
    SNR_improvement_fixed);

% ------------------------------------------------------------
% Difference
% ------------------------------------------------------------

fprintf('\n');
fprintf('---------------- FLOAT vs Q1.15 ----------------\n');

fprintf('Output MSE difference   = %.6f\n', ...
    output_MSE_fixed - output_MSE_float);

fprintf('Output SNR difference   = %.3f dB\n', ...
    output_SNR_fixed - output_SNR_float);

fprintf('SNR improvement diff.   = %.3f dB\n', ...
    SNR_improvement_fixed - SNR_improvement_float);

% ------------------------------------------------------------
% Quantization
% ------------------------------------------------------------

fprintf('\n');
fprintf('---------------- QUANTIZATION ------------------\n');

fprintf('Max input quant. error  = %.8f\n', ...
    max_input_quantization_error);

fprintf('Max desired quant. err. = %.8f\n', ...
    max_desired_quantization_error);

% ------------------------------------------------------------
% Coefficient range
% ------------------------------------------------------------

fprintf('\n');
fprintf('---------------- COEFFICIENT RANGE -------------\n');

fprintf('Max floating coefficient = %.6f\n', ...
    max_coefficient_float);

fprintf('Max fixed coefficient    = %.6f\n', ...
    max_coefficient_fixed);

fprintf('\n');

% ============================================================
% 13. PLOT 1 — FLOATING vs FIXED LMS OUTPUT
% ============================================================

figure;

plot(n,d_float,'LineWidth',1.0);
hold on;

plot(n,x_float,'LineWidth',1.0);

plot(n,y_float,'LineWidth',1.0);

plot(n,y_fixed,'--','LineWidth',1.0);

xlabel('Sample');
ylabel('Amplitude');

title('Floating-Point vs Q1.15 LMS');

legend( ...
    'Desired', ...
    'Noisy Input', ...
    'Floating LMS Output', ...
    'Fixed Q1.15 LMS Output');

grid on;

% ============================================================
% 14. PLOT 2 — FIXED-POINT ERROR
% ============================================================

figure;

plot(n,e_fixed);

xlabel('Sample');
ylabel('Error');

title('Fixed-Point Q1.15 LMS Error');

grid on;

% ============================================================
% 15. PLOT 3 — FLOATING-POINT COEFFICIENTS
% ============================================================

figure;

plot(n,W_float.');

xlabel('Sample');
ylabel('Coefficient Value');

title('Floating-Point LMS Coefficient Adaptation');

legend( ...
    'w0','w1','w2','w3', ...
    'w4','w5','w6','w7');

grid on;

% ============================================================
% 16. PLOT 4 — FIXED-POINT COEFFICIENTS
% ============================================================

figure;

plot(n,W_q15.');

xlabel('Sample');
ylabel('Coefficient Value');

title('Fixed-Point Q1.15 Coefficient Adaptation');

legend( ...
    'w0','w1','w2','w3', ...
    'w4','w5','w6','w7');

grid on;

% ============================================================
% 17. PLOT 5 — COEFFICIENT COMPARISON
% ============================================================

figure;

plot(n,W_float(1,:),'LineWidth',1.2);
hold on;

plot(n,W_q15(1,:),'--','LineWidth',1.2);

xlabel('Sample');
ylabel('w0');

title('Floating-Point vs Q1.15 Coefficient w0');

legend('Floating Point','Q1.15');

grid on;

% ============================================================
% LOCAL FUNCTION 1
% Q1.15 QUANTIZATION
% ============================================================

function q = q15_quantize(x)

    SCALE = 2^15;

    % Convert real value to Q1.15 integer
    q_temp = round(x * SCALE);

    % Q1.15 limits
    q_temp(q_temp > 32767) = 32767;
    q_temp(q_temp < -32768) = -32768;

    q = int64(q_temp);

end

% ============================================================
% LOCAL FUNCTION 2
% Q1.15 SATURATION
% ============================================================

function y = saturate_q15(x)

    if x > 32767

        y = int64(32767);

    elseif x < -32768

        y = int64(-32768);

    else

        y = int64(x);

    end

end