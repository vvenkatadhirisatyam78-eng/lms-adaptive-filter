clc;
clear;
close all;

% =========================================================
% LMS TEST DATA GENERATION
% Q1.15 - SAME SCALING AS MATLAB LMS REFERENCE
% =========================================================

N = 1000;
FRAC_BITS = 15;
Q = 2^FRAC_BITS;

% =========================================================
% FIXED RANDOM SEED
% =========================================================

rng(1);

% =========================================================
% SAMPLE INDEX
% =========================================================

n = 0:N-1;

% =========================================================
% DESIRED SIGNAL
% =========================================================

f = 0.05;

d_float = sin(2*pi*f*n);

% =========================================================
% NOISE
% =========================================================

noise_float = 0.5 * randn(1,N);

% =========================================================
% NOISY INPUT
% =========================================================

x_float = d_float + noise_float;

% =========================================================
% SCALE BOTH SIGNALS BY THE SAME FACTOR
%
% Leave headroom inside Q1.15.
% This MUST match lms_fixed_q15.m
% =========================================================

scale_factor = 0.8 / max(abs(x_float));

x_float = x_float * scale_factor;

d_float = d_float * scale_factor;

% =========================================================
% RANGE CHECK
% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('          Q1.15 INPUT RANGE CHECK\n');
fprintf('============================================\n');

fprintf('Scale factor = %.9f\n', scale_factor);
fprintf('Maximum |x| = %.9f\n', max(abs(x_float)));
fprintf('Maximum |d| = %.9f\n', max(abs(d_float)));

% =========================================================
% CONVERT TO Q1.15
% =========================================================

x_q15 = round(x_float * Q);
d_q15 = round(d_float * Q);

% =========================================================
% Q1.15 SATURATION
% =========================================================

x_q15(x_q15 > 32767) = 32767;
x_q15(x_q15 < -32768) = -32768;

d_q15(d_q15 > 32767) = 32767;
d_q15(d_q15 < -32768) = -32768;

% =========================================================
% CONVERT SIGNED INTEGER TO 16-BIT HEX
% =========================================================

x_hex = dec2hex(mod(x_q15,65536),4);
d_hex = dec2hex(mod(d_q15,65536),4);

% =========================================================
% WRITE INPUT MEMORY
% =========================================================

fid = fopen('input_q15.mem','w');

if fid == -1
    error('Cannot create input_q15.mem');
end

for k = 1:N
    fprintf(fid,'%s\n',x_hex(k,:));
end

fclose(fid);

% =========================================================
% WRITE DESIRED MEMORY
% =========================================================

fid = fopen('desired_q15.mem','w');

if fid == -1
    error('Cannot create desired_q15.mem');
end

for k = 1:N
    fprintf(fid,'%s\n',d_hex(k,:));
end

fclose(fid);

% =========================================================
% DISPLAY FIRST 10 SAMPLES
% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('       Q1.15 TEST DATA GENERATED\n');
fprintf('============================================\n');

fprintf('\n');
fprintf('Sample    d(real)    d(Q1.15)    x(real)    x(Q1.15)\n');
fprintf('------------------------------------------------------\n');

for k = 1:10

    fprintf('%4d    % .6f    %7d    % .6f    %7d\n', ...
        k-1, ...
        d_float(k), ...
        d_q15(k), ...
        x_float(k), ...
        x_q15(k));

end

% =========================================================
% FILE INFORMATION
% =========================================================

fprintf('\n');
fprintf('Files created:\n');
fprintf('input_q15.mem\n');
fprintf('desired_q15.mem\n');

fprintf('\n');
fprintf('Number of samples = %d\n',N);

% =========================================================
% PLOT
% =========================================================

figure;

plot(n,d_float,'LineWidth',1);
hold on;

plot(n,x_float,'LineWidth',1);

xlabel('Sample');
ylabel('Amplitude');

title('Scaled Q1.15 LMS Test Signals');

legend('Desired','Noisy Input');

grid on;