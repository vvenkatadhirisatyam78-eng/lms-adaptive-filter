clc;
clear;
close all;

% ============================================================
% 8-TAP LMS
% Q1.15 RANGE AND BIT-WIDTH ANALYSIS
% ============================================================

% ------------------------------------------------------------
% 1. PARAMETERS
% ------------------------------------------------------------

N = 1000;              % Number of samples
M = 8;                 % Number of taps

FRAC_BITS = 15;        % Q1.15
MU_SHIFT = 5;          % mu = 2^-5 = 1/32

mu = 1/32;

n = 0:N-1;

% ------------------------------------------------------------
% 2. GENERATE SAME TEST SIGNAL
% ------------------------------------------------------------

rng(1);

f = 0.05;

% Desired signal
d_float = sin(2*pi*f*n);

% Noise
noise_float = 0.5 * randn(1,N);

% Noisy input
x_float = d_float + noise_float;

% ------------------------------------------------------------
% 3. SCALE SIGNAL FOR Q1.15
% ------------------------------------------------------------

scale_factor = 0.8 / max(abs(x_float));

x_float = x_float * scale_factor;

d_float = d_float * scale_factor;

% ------------------------------------------------------------
% 4. QUANTIZE TO Q1.15
% ------------------------------------------------------------

d_q15 = q15_quantize(d_float);

x_q15 = q15_quantize(x_float);

% ============================================================
% 5. RANGE STORAGE
% ============================================================

% Maximum absolute values in INTEGER REPRESENTATION

max_input = int64(0);

max_coefficient = int64(0);

max_product = int64(0);

max_accumulator = int64(0);

max_output = int64(0);

max_error = int64(0);

max_error_x_product = int64(0);

max_correction = int64(0);

% ------------------------------------------------------------
% Also store histories for checking
% ------------------------------------------------------------

accumulator_history = zeros(1,N);

output_history = zeros(1,N);

error_history = zeros(1,N);

product_history = zeros(1,N);

error_product_history = zeros(1,N);

correction_history = zeros(1,N);

coefficient_history = zeros(M,N);

% ============================================================
% 6. INITIALIZE LMS
% ============================================================

w = zeros(M,1,'int64');

y_q15 = zeros(1,N,'int64');

e_q15 = zeros(1,N,'int64');

% ============================================================
% 7. FIXED-POINT LMS
% ============================================================

for k = M:N

    % --------------------------------------------------------
    % Current 8-sample vector
    % --------------------------------------------------------

    x_vec = int64(x_q15(k:-1:k-M+1)).';

    % --------------------------------------------------------
    % INPUT RANGE
    % --------------------------------------------------------

    for i = 1:M

        if abs(x_vec(i)) > max_input

            max_input = abs(x_vec(i));

        end

    end

    % --------------------------------------------------------
    % 8-TAP ACCUMULATOR
    % --------------------------------------------------------

    accumulator = int64(0);

    for i = 1:M

        % ----------------------------------------------------
        % Q1.15 × Q1.15
        %
        % 16 × 16 = 32-bit product
        % 15 + 15 = 30 fractional bits
        % ----------------------------------------------------

        product = w(i) * x_vec(i);

        % Product range
        if abs(product) > max_product

            max_product = abs(product);

        end

        % Accumulate
        accumulator = accumulator + product;

    end

    % --------------------------------------------------------
    % ACCUMULATOR RANGE
    % --------------------------------------------------------

    if abs(accumulator) > max_accumulator

        max_accumulator = abs(accumulator);

    end

    accumulator_history(k) = double(accumulator);

    % --------------------------------------------------------
    % FILTER OUTPUT
    %
    % Q2.30 → Q1.15
    %
    % Shift right by 15
    % --------------------------------------------------------

    y_temp = bitsra(accumulator,FRAC_BITS);

    % Store output before saturation for range analysis

    if abs(y_temp) > max_output

        max_output = abs(y_temp);

    end

    % Saturate to Q1.15
    y_q15(k) = saturate_q15(y_temp);

    output_history(k) = double(y_q15(k));

    % --------------------------------------------------------
    % ERROR
    %
    % e = d - y
    %
    % d and y have 15 fractional bits.
    % --------------------------------------------------------

    e_q15(k) = int64(d_q15(k)) - y_q15(k);

    if abs(e_q15(k)) > max_error

        max_error = abs(e_q15(k));

    end

    error_history(k) = double(e_q15(k));

    % --------------------------------------------------------
    % COEFFICIENT UPDATE
    % --------------------------------------------------------

    for i = 1:M

        % ----------------------------------------------------
        % e × x
        %
        % e = 17-bit candidate
        % x = 16-bit
        %
        % Product = 33-bit candidate
        %
        % Fractional bits = 30
        % ----------------------------------------------------

        error_product = e_q15(k) * x_vec(i);

        if abs(error_product) > max_error_x_product

            max_error_x_product = abs(error_product);

        end

        error_product_history(k) = ...
            max(error_product_history(k), ...
            double(abs(error_product)));

        % ----------------------------------------------------
        % Apply:
        %
        % mu = 1/32 = 2^-5
        %
        % Return 30 fractional bits to Q1.15:
        % shift 15
        %
        % Total shift = 15 + 5 = 20
        % ----------------------------------------------------

        correction = bitsra( ...
            error_product, ...
            FRAC_BITS + MU_SHIFT);

        if abs(correction) > max_correction

            max_correction = abs(correction);

        end

        correction_history(k) = ...
            max(correction_history(k), ...
            double(abs(correction)));

        % ----------------------------------------------------
        % COEFFICIENT UPDATE
        % ----------------------------------------------------

        w(i) = w(i) + correction;

        % Saturate coefficient
        w(i) = saturate_q15(w(i));

        % ----------------------------------------------------
        % COEFFICIENT RANGE
        % ----------------------------------------------------

        if abs(w(i)) > max_coefficient

            max_coefficient = abs(w(i));

        end

    end

    % Store coefficients as decimal
    coefficient_history(:,k) = ...
        double(w) / 2^FRAC_BITS;

end

% ============================================================
% 8. CONVERT INTEGER VALUES TO REAL VALUES
% ============================================================

max_input_real = ...
    double(max_input) / 2^15;

max_coefficient_real = ...
    double(max_coefficient) / 2^15;

max_product_real = ...
    double(max_product) / 2^30;

max_accumulator_real = ...
    double(max_accumulator) / 2^30;

max_output_real = ...
    double(max_output) / 2^15;

max_error_real = ...
    double(max_error) / 2^15;

max_error_x_product_real = ...
    double(max_error_x_product) / 2^30;

max_correction_real = ...
    double(max_correction) / 2^15;

% ============================================================
% 9. CALCULATE THEORETICAL WIDTHS
% ============================================================

bits_input = required_signed_bits(max_input);

bits_coefficient = required_signed_bits(max_coefficient);

bits_product = required_signed_bits(max_product);

bits_accumulator = required_signed_bits(max_accumulator);

bits_output = required_signed_bits(max_output);

bits_error = required_signed_bits(max_error);

bits_error_product = ...
    required_signed_bits(max_error_x_product);

bits_correction = ...
    required_signed_bits(max_correction);

% ============================================================
% 10. DISPLAY RESULTS
% ============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('             Q1.15 RANGE ANALYSIS\n');
fprintf('============================================================\n');

fprintf('\n');
fprintf('Filter taps              = %d\n',M);
fprintf('Q format                 = Q1.15\n');
fprintf('Fractional bits          = %d\n',FRAC_BITS);
fprintf('Step size                = 1/32\n');
fprintf('Step-size shift          = %d\n',MU_SHIFT);

fprintf('\n');
fprintf('============================================================\n');
fprintf('              MAXIMUM INTEGER VALUES\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Input                    = %lld\n',max_input);

fprintf('Coefficient              = %lld\n',max_coefficient);

fprintf('Single product           = %lld\n',max_product);

fprintf('8-tap accumulator        = %lld\n',max_accumulator);

fprintf('Output                   = %lld\n',max_output);

fprintf('Error                    = %lld\n',max_error);

fprintf('Error × input            = %lld\n',max_error_x_product);

fprintf('Coefficient correction   = %lld\n',max_correction);

fprintf('\n');
fprintf('============================================================\n');
fprintf('               MAXIMUM REAL VALUES\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Input                    = %.9f\n',max_input_real);

fprintf('Coefficient              = %.9f\n',max_coefficient_real);

fprintf('Single product           = %.9f\n',max_product_real);

fprintf('8-tap accumulator        = %.9f\n',max_accumulator_real);

fprintf('Output                   = %.9f\n',max_output_real);

fprintf('Error                    = %.9f\n',max_error_real);

fprintf('Error × input            = %.9f\n', ...
    max_error_x_product_real);

fprintf('Coefficient correction   = %.9f\n', ...
    max_correction_real);

fprintf('\n');
fprintf('============================================================\n');
fprintf('              MINIMUM SIGNED WIDTHS\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Input                    = %d bits\n',bits_input);

fprintf('Coefficient              = %d bits\n',bits_coefficient);

fprintf('Single product           = %d bits\n',bits_product);

fprintf('8-tap accumulator        = %d bits\n',bits_accumulator);

fprintf('Output                   = %d bits\n',bits_output);

fprintf('Error                    = %d bits\n',bits_error);

fprintf('Error × input            = %d bits\n', ...
    bits_error_product);

fprintf('Coefficient correction   = %d bits\n', ...
    bits_correction);

fprintf('\n');

% ============================================================
% 11. THEORETICAL WIDTH CHECK
% ============================================================

fprintf('============================================================\n');
fprintf('             PROPOSED RTL WIDTH CHECK\n');
fprintf('============================================================\n');

fprintf('\n');

fprintf('Input:                  16 bits  -> ');

if bits_input <= 16
    fprintf('PASS\n');
else
    fprintf('FAIL\n');
end

fprintf('Coefficient:            16 bits  -> ');

if bits_coefficient <= 16
    fprintf('PASS\n');
else
    fprintf('FAIL\n');
end

fprintf('Product:                32 bits  -> ');

if bits_product <= 32
    fprintf('PASS\n');
else
    fprintf('FAIL\n');
end

fprintf('Accumulator:            35 bits  -> ');

if bits_accumulator <= 35
    fprintf('PASS\n');
else
    fprintf('FAIL\n');
end

fprintf('Output:                 16 bits  -> ');

if bits_output <= 16
    fprintf('PASS\n');
else
    fprintf('FAIL\n');
end

fprintf('Error:                  17 bits  -> ');

if bits_error <= 17
    fprintf('PASS\n');
else
    fprintf('FAIL\n');
end

fprintf('Error × input:          33 bits  -> ');

if bits_error_product <= 33
    fprintf('PASS\n');
else
    fprintf('FAIL\n');
end

fprintf('\n');

% ============================================================
% 12. PLOT ACCUMULATOR RANGE
% ============================================================

figure;

plot(n,accumulator_history);

xlabel('Sample');

ylabel('Accumulator Integer Value');

title('8-Tap LMS Accumulator Range');

grid on;

% ============================================================
% 13. PLOT ERROR RANGE
% ============================================================

figure;

plot(n,error_history);

xlabel('Sample');

ylabel('Error Integer Value');

title('LMS Error Range');

grid on;

% ============================================================
% 14. PLOT COEFFICIENT RANGE
% ============================================================

figure;

plot(n,coefficient_history.');

xlabel('Sample');

ylabel('Coefficient Value');

title('LMS Coefficient Range');

legend( ...
    'w0','w1','w2','w3', ...
    'w4','w5','w6','w7');

grid on;

% ============================================================
% LOCAL FUNCTION 1
% Q1.15 QUANTIZATION
% ============================================================

function q = q15_quantize(x)

    SCALE = 2^15;

    q_temp = round(x * SCALE);

    % Q1.15 signed limits

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

% ============================================================
% LOCAL FUNCTION 3
% MINIMUM SIGNED BIT WIDTH
% ============================================================

function bits = required_signed_bits(max_value)

    % Maximum positive magnitude

    value = double(max_value);

    if value == 0

        bits = 1;

    else

        % Signed two's-complement representation
        %
        % Need one sign bit plus enough magnitude bits.

        bits = ceil(log2(value + 1)) + 1;

    end

end