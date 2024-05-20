% 参数：
% 阵元数：8
% 入射信号角度：[-20 0 30]
% 信噪比：10
% 信源数：3
% 快拍数：500
clc;
clear;
close all;

M = 8;  % 阵元数
c = 3e8;  % 光速
lamda = 0.1;  % 波长
fc = c / lamda;  % 载波频率
fs = 500;  % 采样频率
snap = 500;  % 快拍数
dt = 1 / fs;  % 采样间隔

SNR_dB = 10;  % 信噪比（以dB为单位）
SNR = 1 / db2mag(SNR_dB);  % 转换为线性单位

% 入射信号角度
theta = [-20, 0, 30];

% 阵元间距为半波长
d = 0.5 * lamda;
n = 0:M-1;

% 导向矢量
a1 = exp(-1j * 2 * pi * d / lamda * n * sin(theta(1) / 180 * pi))';
a2 = exp(-1j * 2 * pi * d / lamda * n * sin(theta(2) / 180 * pi))';
a3 = exp(-1j * 2 * pi * d / lamda * n * sin(theta(3) / 180 * pi))';
A = [a1, a2, a3];

t = (1:snap) * dt;
s1 = exp(1j * 2 * pi * (fc .* t + 0.5 * 30 * t .^ 2));
s2 = exp(1j * 2 * pi * (fc .* t + 0.5 * 20 * t .^ 2));
s3 = exp(1j * 2 * pi * (fc .* t + 0.5 * 10 * t .^ 2));
St = [s1; s2; s3];

% 生成噪声并进行DOA估计
Nt = zeros(M, length(t));
for k = 1:M
    noise = SNR * randn(1, length(t));
    Nt(k, :) = noise;
end
Xt = A * St + Nt;
R = Xt * Xt' / length(t);
[U, ~] = eig(R);

ac = 0;
amplitude = zeros(1, 121);  % 初始化amplitude数组
for theta_scan = -60:1:60
    ac = ac + 1;
    a_theta = exp(-1j * 2 * pi * d / lamda * n .* sin(theta_scan / 180 * pi))';
    Pmusic = 1 / (a_theta' * (U(:, 1:5) * U(:, 1:5)') * a_theta);  % 计算MUSIC算法的谱估计值，只考虑了前5个特征向量
    amplitude(ac) = abs(Pmusic);
end

figure;
plot(-60:1:60, pow2db(amplitude / max(amplitude)), 'b');
xlabel('角度(°)');
ylabel('归一化幅度(dB)');
title('MUSIC算法DOA估计 ');
grid on;