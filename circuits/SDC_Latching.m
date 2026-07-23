% Generic Time-Delay Logic Simulation: Hardware Hold-off & Fault Discharge
clear; clc; close all;

%% --- Component Values & Tolerances ---
% Preset Circuit (Startup Delay)
R_pre_nom = 100e4;
C_pre_nom = 10e-6;

% Status RC Circuit (Input RC)
R_status_nom = 510e3;
C_status_nom = 10e-6;

% Tolerances (Multiplier Form)
tol_R_max = 1.01;   % +1%
tol_R_min = 0.99;   % -1%
tol_C_max = 1.10;   % +10%
tol_C_min = 0.90;   % -10%

% Logic Parameters
V_logic  = 5.0;     % Logic High Voltage (V)
Vt_minus = 1.4;     % Schmitt Trigger negative-going threshold (V)
Vt_plus  = 3.3;     % Schmitt Trigger positive-going threshold (V)

%% --- Time Calculations ---
% 1. Preset Startup Delay Time (Charging 0V to Vt_plus)
log_factor_charge = -log(1 - (Vt_plus / V_logic));

t_pre_start_nom = (R_pre_nom * C_pre_nom) * log_factor_charge;
t_pre_start_min = (R_pre_nom * tol_R_min * C_pre_nom * tol_C_min) * log_factor_charge;
t_pre_start_max = (R_pre_nom * tol_R_max * C_pre_nom * tol_C_max) * log_factor_charge;

% 2. Status RC Time (Falling 5V to Vt_minus for both Boot-up and Fault)
log_factor_discharge = -log(Vt_minus / V_logic);

t_stat_drop_nom = (R_status_nom * C_status_nom) * log_factor_discharge;
t_stat_drop_min = (R_status_nom * tol_R_min * C_status_nom * tol_C_min) * log_factor_discharge;
t_stat_drop_max = (R_status_nom * tol_R_max * C_status_nom * tol_C_max) * log_factor_discharge;

%% --- Console Output ---
fprintf('==================================================\n');
fprintf('TIMING ANALYSIS (1%% Resistor, 10%% Capacitor error)\n');
fprintf('==================================================\n\n');

fprintf('PRESET STARTUP DELAY (0V up to 3.3V):\n');
fprintf('  Nominal Time : %.3f seconds\n', t_pre_start_nom);
fprintf('  Range        : %.3f s to %.3f s\n\n', t_pre_start_min, t_pre_start_max);

fprintf('STATUS RC DISCHARGE (5V down to 1.4V):\n');
fprintf('  Nominal Time : %.3f seconds\n', t_stat_drop_nom);
fprintf('  Range        : %.3f s to %.3f s\n', t_stat_drop_min, t_stat_drop_max);
fprintf('==================================================\n');

%% --- Simulation (Using Nominal Values) ---
% Calculate 5 time constants for worst-case stabilization to 0V
tau_status_max = (R_status_nom * tol_R_max) * (C_status_nom * tol_C_max);
t_stabilize = 5 * tau_status_max;

t_event = ceil(t_stabilize) + 5; % Wait for full decay of Stage 1 + 5s buffer
t_end = t_event + 25;            % Extend simulation to capture full fault drop
t = linspace(0, t_end, 5000);

% Preallocate arrays for decoupled plotting
V_preset_node      = zeros(size(t));
V_preset_schmitt   = zeros(size(t));

V_status_node_1    = zeros(size(t));
V_status_schmitt_1 = zeros(size(t));

V_status_node_2    = zeros(size(t));
V_status_schmitt_2 = zeros(size(t));

% Initial states for Schmitt Hysteresis
preset_schmitt_state   = V_logic; % Starts HIGH (input is 0V)
status_schmitt_state_1 = 0;       % Starts LOW (input is 5V instantly at boot)
status_schmitt_state_2 = 0;       % Starts LOW (input is 5V in no-fault state)

for i = 1:length(t)
    
    % --- STAGE 1: Preset Power-On Charge ---
    V_preset_node(i) = V_logic * (1 - exp(-t(i) / (R_pre_nom * C_pre_nom)));
    
    if V_preset_node(i) >= Vt_plus
        preset_schmitt_state = 0;
    elseif V_preset_node(i) <= Vt_minus
        preset_schmitt_state = V_logic;
    end
    V_preset_schmitt(i) = preset_schmitt_state;
    
    % --- STAGE 1: Status Boot-up Hold-off (Decays 5V to 0V) ---
    V_status_node_1(i) = V_logic * exp(-t(i) / (R_status_nom * C_status_nom));
    
    if V_status_node_1(i) >= Vt_plus
        status_schmitt_state_1 = 0;
    elseif V_status_node_1(i) <= Vt_minus
        status_schmitt_state_1 = V_logic;
    end
    V_status_schmitt_1(i) = status_schmitt_state_1;
    
    % --- STAGE 2: Status Fault Drop (Steady 5V, then Decays) ---
    if t(i) < t_event
        V_status_node_2(i) = V_logic;
    else
        V_status_node_2(i) = V_logic * exp(-(t(i) - t_event) / (R_status_nom * C_status_nom));
    end
    
    if V_status_node_2(i) >= Vt_plus
        status_schmitt_state_2 = 0;
    elseif V_status_node_2(i) <= Vt_minus
        status_schmitt_state_2 = V_logic;
    end
    V_status_schmitt_2(i) = status_schmitt_state_2;
    
end

%% --- Plotting ---
% Dynamic Axis Limits: 5 seconds after both signals have crossed their thresholds
t_lim_stage1 = max(t_pre_start_max, t_stat_drop_max) + 5;
t_lim_stage2 = t_stat_drop_max + 5;

% Colors optimized for both Light and Dark mode visibility
color_pre_rc   = '#4DBEEE'; % Bright Cyan
color_pre_dig  = '#EDB120'; % Golden Yellow
color_stat_rc  = '#D95319'; % Bright Orange
color_stat_dig = '#77AC30'; % Bright Green
color_thresh   = [0.5 0.5 0.5]; % Neutral Gray

figure('Name', 'Hardware Hold-off and Fault Simulation', 'NumberTitle', 'off', 'Position', [100, 100, 950, 700]);

% Plot 1: Power-On Startup Sequence (Absolute Time)
subplot(2,1,1);
plot(t(t<=t_event), V_preset_node(t<=t_event), '-', 'Color', color_pre_rc, 'LineWidth', 2); hold on;
plot(t(t<=t_event), V_preset_schmitt(t<=t_event), '-.', 'Color', color_pre_dig, 'LineWidth', 2);
plot(t(t<=t_event), V_status_node_1(t<=t_event), '-', 'Color', color_stat_rc, 'LineWidth', 2);
plot(t(t<=t_event), V_status_schmitt_1(t<=t_event), '-.', 'Color', color_stat_dig, 'LineWidth', 2);

yline(Vt_plus, '--', 'Color', color_thresh, 'LineWidth', 1.5, 'Label', ' Positive Threshold (Vt+ = 3.3V)', 'LabelHorizontalAlignment', 'left');
yline(Vt_minus, '--', 'Color', color_thresh, 'LineWidth', 1.5, 'Label', ' Negative Threshold (Vt- = 1.4V)', 'LabelHorizontalAlignment', 'left');
title('Stage 1: Power-On Boot-up Hold-off (Status Decays 5V to 0V)');
ylabel('Voltage (V)');
xlim([0 t_lim_stage1]);
ylim([-0.5 V_logic+1.5]);
legend('Preset RC Voltage', 'Preset Logic State', 'Status RC Voltage', 'Status Logic State', 'Location', 'east');
grid on;

% Plot 2: Status Fault Drop (Relative Time)
subplot(2,1,2);
% Create a shifted time vector so the event occurs at t = 0
t_rel = t(t>=t_event-2) - t_event; 

plot(t_rel, V_status_node_2(t>=t_event-2), '-', 'Color', color_stat_rc, 'LineWidth', 2); hold on;
plot(t_rel, V_status_schmitt_2(t>=t_event-2), '-.', 'Color', color_stat_dig, 'LineWidth', 2);

xline(0, ':', 'Color', color_thresh, 'LineWidth', 1.5, 'Label', ' Fault Triggered', 'LabelVerticalAlignment', 'bottom');
yline(Vt_minus, '--', 'Color', color_thresh, 'LineWidth', 1.5, 'Label', ' Negative Threshold (Vt- = 1.4V)', 'LabelHorizontalAlignment', 'left');
title(sprintf('Stage 2: Status Fault Discharge (Nominal Drop Time: %.2fs)', t_stat_drop_nom));
xlabel('Time Relative to Fault (seconds)');
ylabel('Voltage (V)');
xlim([-2 t_lim_stage2]);
ylim([-0.5 V_logic+1.5]);
legend('Status RC Voltage', 'Status Logic State', 'Location', 'east');
grid on;