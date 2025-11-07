clear; clc; close all;
%% Pulled key specs from: https://www.batterydesign.net/2024-chevrolet-silverado-ev/
%% ---- Battery Parameters ----
batt.E_total_kWh   = 176;       % total energy [kWh]
batt.E_usable_kWh  = 167;       % usable capacity [kWh]
batt.V_nom         = 296;       % nominal voltage [V]
batt.V_min         = 200;       % minimum voltage [V]
batt.Cap_Ah        = 595.8;     % nominal capacity [Ah]
batt.P_peak_kW     = 250;       % 10s peak power [kW]

% Efficiency assumptions
batt.eta_c         = 0.97;      % charge efficiency
batt.eta_d         = 0.97;      % discharge efficiency
inv.eta            = 0.95;      % inverter efficiency
batt.P_ch_max      = 19.2;      % max charge power [kW]
batt.P_dis_max     = 9.6;       % max discharge power [kW]
batt.SOC0          = 0.50;      % initial SOC (50%)
batt.k_cal         = 1.0e-5;    % calendar fade coefficient
batt.k_thru        = 5.0e-5;    % throughput fade coefficient

%% ---- Simulation Setup ----
dt = 1/60;      % time step [hr] = 1 minute
t_end = 24;     % 24 hours
time = 0:dt:t_end;

% Power profile [kW]: +charge, -discharge
P_profile = zeros(size(time));
P_profile(time>=0 & time<6) = 10;     % charge overnight
P_profile(time>=17 & time<21) = -6;   % discharge to house

%% ---- Simulation Loop ----
SOC = zeros(size(time));
SOC(1) = batt.SOC0;
E_in = 0; E_out = 0; E_loss = 0;

for k = 1:length(time)-1
    P = P_profile(k);
    P = min(max(P, -batt.P_dis_max), batt.P_ch_max);

    if P >= 0  % Charging
        dE = batt.eta_c * inv.eta * P * dt;
        E_in = E_in + P * dt;
    else       % Discharging
        dE = (1/inv.eta) * (1/batt.eta_d) * P * dt;
        E_out = E_out + abs(P * dt);
    end

    SOC(k+1) = SOC(k) + dE / batt.E_usable_kWh;
    SOC(k+1) = max(0, min(1, SOC(k+1)));  % bounds check

    E_loss = E_loss + abs(P * dt) * (1 - batt.eta_c*batt.eta_d*inv.eta);
end

%% ---- Calculations ----
RoundTrip_eff = 100 * (1 - E_loss / (E_in + E_out));
Battery_eff   = 100 * (batt.eta_c * batt.eta_d);
Inverter_eff  = 100 * inv.eta;

%% ---- Plot 1: SOC ----
figure('Name','Silverado EV Battery Dashboard','NumberTitle','off');
subplot(3,1,1)
plot(time, SOC*100, 'b', 'LineWidth', 2);
ylabel('SOC [%]');
title('GM Silverado EV Battery SOC Simulation');
grid on;

%% ---- Plot 2: Power Flow ----
subplot(3,1,2)
plot(time, P_profile, 'LineWidth', 2);
yline(0,'k--');
ylabel('Power [kW]');
title('Power Flow Profile (+Charge / -Discharge)');
grid on;

%% ---- Summary ----
fprintf('--- Silverado EV Battery Daily Summary ---\n');
fprintf('Total Energy Input (Charging): %.2f kWh\n', E_in);
fprintf('Total Energy Output (Discharging): %.2f kWh\n', E_out);
fprintf('Total Energy Losses: %.2f kWh\n', E_loss);
fprintf('Battery Efficiency: %.1f%%\n', Battery_eff);
fprintf('Final SOC: %.1f%%\n', SOC(end)*100);