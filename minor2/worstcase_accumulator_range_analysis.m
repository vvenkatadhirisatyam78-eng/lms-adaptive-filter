clc;
clear;

%% =========================================================
% ACTUAL WORST-CASE ACCUMULATOR ANALYSIS
% 8-tap LMS
% Based on actual bounded input and coefficient ranges
% =========================================================

N_TAPS = 8;

% Actual maximum magnitudes from the implemented design
max_input = 0.799987793;
max_coeff = 0.258789062;

%% ---------------------------------------------------------
% Maximum single product
% ---------------------------------------------------------

max_product = max_input * max_coeff;

%% ---------------------------------------------------------
% Maximum 8-tap accumulation
% ---------------------------------------------------------

max_accumulator = N_TAPS * max_product;

%% ---------------------------------------------------------
% Q2.30 fixed-point representation
% ---------------------------------------------------------

FRAC_BITS = 30;

max_product_integer = round(max_product * 2^FRAC_BITS);
max_accumulator_integer = round(max_accumulator * 2^FRAC_BITS);

%% ---------------------------------------------------------
% Display
% ---------------------------------------------------------

fprintf('\n');
fprintf('====================================================\n');
fprintf(' ACTUAL LMS ACCUMULATOR RANGE ANALYSIS\n');
fprintf('====================================================\n');

fprintf('\nNumber of taps              = %d\n', N_TAPS);

fprintf('\nMaximum input magnitude     = %.9f\n', max_input);
fprintf('Maximum coefficient magnitude = %.9f\n', max_coeff);

fprintf('\nMaximum single product      = %.9f\n', max_product);

fprintf('\nMaximum 8-tap accumulation  = %.9f\n', ...
    max_accumulator);

fprintf('\nFixed-point product integer = %d\n', ...
    max_product_integer);

fprintf('Fixed-point accumulator     = %d\n', ...
    max_accumulator_integer);

%% ---------------------------------------------------------
% Check accumulator widths
% ---------------------------------------------------------

fprintf('\n====================================================\n');
fprintf(' ACCUMULATOR WIDTH CHECK\n');
fprintf('====================================================\n');

widths = [32 33 34 35];

for W = widths

    % Q2.30 signed range
    max_integer = 2^(W-1) - 1;
    min_integer = -2^(W-1);

    if max_accumulator_integer <= max_integer && ...
       -max_accumulator_integer >= min_integer

        fprintf('%2d-bit accumulator : SAFE\n', W);

    else

        fprintf('%2d-bit accumulator : NOT SAFE\n', W);

    end

    fprintf('    Maximum integer = %d\n', max_integer);

end

%% ---------------------------------------------------------
% 32-bit detailed check
% ---------------------------------------------------------

fprintf('\n====================================================\n');
fprintf(' 32-BIT ACCUMULATOR CHECK\n');
fprintf('====================================================\n');

max_32_integer = 2^31 - 1;

max_32_real = max_32_integer / 2^FRAC_BITS;

margin = max_32_real - max_accumulator;

fprintf('32-bit maximum real value = %.9f\n', max_32_real);

fprintf('Required maximum value     = %.9f\n', ...
    max_accumulator);

fprintf('Remaining safety margin    = %.9f\n', ...
    margin);

fprintf('\n');

if margin > 0
    fprintf('RESULT: 32-bit accumulator is SAFE\n');
else
    fprintf('RESULT: 32-bit accumulator is NOT SAFE\n');
end

fprintf('====================================================\n');