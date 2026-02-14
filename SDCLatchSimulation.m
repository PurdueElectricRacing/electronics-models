%% SDC Latch Simulation
% Overlay: RC1 -> Schmitt, RC2 -> PRESET_n (active-low), Flip-Flop Q

clear; clc; close all;

%% 1) Time base
Fs = 50e3;
T  = 4;
t  = (0:1/Fs:T).';
Vlogic = 5;

%% 2) RC1 curve (for Schmitt input) — example: discharge from V0
V0_1 = 5;
R1   = 47e3;
C1   = 10e-6;
tau1 = R1*C1;

v_rc1 = V0_1 * exp(-t/tau1); % discharge (this is what we have)
% v_rc1 = V0_1 * (1 - exp(-t/tau1)); % charge

%% 3) Schmitt trigger from RC1 (acts like a digital waveform / “clock source”)
Vth_hi1 = 2.16; % rising threshold
Vth_lo1 = 1.41; % falling threshold

clk01 = schmittTrigger(v_rc1, Vth_hi1, Vth_lo1);
clk01 = 1 - clk01;  %inverting Schmitt Trigger                              
v_clk = Vlogic * clk01;


%% 4) RC2 curve that drives PRESET_n (active-low)
V0_2 = 5;
R2   = 51e3;
C2   = 10e-6;
tau2 = R2*C2;

v_rc2 = V0_2 - V0_2 * exp(-t/tau2);

Vpreset_th = 3.5; % threshold for asserting preset (edit)
preset_n01 = ~(v_rc2 <= Vpreset_th); % 1=not asserted, 0=asserted
v_preset_n = Vlogic * preset_n01;

%% 5) Flip-flop model: D-FF with async active-low preset
D = 0; % constant D (Our current circuit has D=GND or D=0)
q01 = dff_rising_edge_async_preset_n(clk01, D, preset_n01);
v_q = Vlogic * q01;

%% 6) Plot overlay
figure('Color','w'); hold on; grid on;

plot(t, v_rc1,       'LineWidth', 2);
plot(t, v_rc2,       'LineWidth', 2);
plot(t, v_clk,       'LineWidth', 2);
%plot(t, v_preset_n,  'LineWidth', 1.6);
plot(t, v_q,         'LineWidth', 3);

xlabel('Time (s)', 'FontSize', 18);
ylabel('Voltage (V)', 'FontSize', 18);
title('Flip-Flop Output with Open Circuit Detection', 'FontSize', 18);

  %'PRESET\_n (active-low)', ...%
legend( ...
  'RC1 input', ...
  'RC2 (preset RC)', ...
  'Schmitt output (inverted)', ...
  'Flip-flop Q', ...
  'Location','best');
legend('FontSize', 18)


% Threshold lines
s = yline(Vth_lo1, ':', 'Schmitt V_{TL}', 'LineWidth', 2);
p = yline(Vpreset_th, ':', 'Preset Threshold', 'LineWidth', 2);
s.FontSize = 16;
p.FontSize = 16;

%% Helper Functions 

% Schmitt Trigger: y latches high when x>=Vhi, low when x<=Vlo
function y = schmittTrigger(x, Vhi, Vlo)
    y = zeros(size(x));
    state = 0;
    for i = 1:numel(x)
        if state == 0 && x(i) >= Vhi
            state = 1;
        elseif state == 1 && x(i) <= Vlo
            state = 0;
        end
        y(i) = state;
    end
end
% D-FF with async active-low preset:
% preset = 0 forces Q = 1 immediately
% rising edge of clk01 latches to D otherwise
function q = dff_rising_edge_async_preset_n(clk01, D, preset_n01)
    n = numel(clk01);
    q = zeros(n,1);

    if isscalar(D), D = D*ones(n,1); end
    qstate = 0;
    prev = clk01(1);

    for i = 1:n
        if preset_n01(i) == 0
            qstate = 1;
        else
            if prev == 0 && clk01(i) == 1
                qstate = D(i);
            end
        end
        q(i) = qstate;
        prev = clk01(i);
    end
end
