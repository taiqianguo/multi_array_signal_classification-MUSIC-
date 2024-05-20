
clc;
clear;
close all;

M = 8;  
c = 3e8;  
lamda = 0.1;  
fc = c / lamda;  
fs = 500;  
snap = 500;  
dt = 1 / fs;  

SNR_dB = 10;  
SNR = 1 / db2mag(SNR_dB);  


theta = [-20, 0, 30];


d = 0.5 * lamda;
n = 0:M-1;


a1 = exp(-1j * 2 * pi * d / lamda * n * sin(theta(1) / 180 * pi))';
a2 = exp(-1j * 2 * pi * d / lamda * n * sin(theta(2) / 180 * pi))';
a3 = exp(-1j * 2 * pi * d / lamda * n * sin(theta(3) / 180 * pi))';
A = [a1, a2, a3];

t = (1:snap) * dt;
s1 = exp(1j * 2 * pi * (fc .* t + 0.5 * 30 * t .^ 2));
s2 = exp(1j * 2 * pi * (fc .* t + 0.5 * 20 * t .^ 2));
s3 = exp(1j * 2 * pi * (fc .* t + 0.5 * 10 * t .^ 2));
St = [s1; s2; s3];

Nt = zeros(M, length(t));
for k = 1:M
    noise = SNR * randn(1, length(t));
    Nt(k, :) = noise;
end
Xt = A * St + Nt;
R = Xt * Xt' / length(t);
[U, ~] = eig(R);

ac = 0;
amplitude = zeros(1, 121); 
for theta_scan = -60:1:60
    ac = ac + 1;
    a_theta = exp(-1j * 2 * pi * d / lamda * n .* sin(theta_scan / 180 * pi))';
    Pmusic = 1 / (a_theta' * (U(:, 1:5) * U(:, 1:5)') * a_theta);  
    amplitude(ac) = abs(Pmusic);
end

figure;
plot(-60:1:60, pow2db(amplitude / max(amplitude)), 'b');
xlabel('angle(°)');
ylabel('normalized_Amplitude(dB)');
title('MUSIC_AoA');
grid on;
