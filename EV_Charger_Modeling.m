clear; clc;

% ---- Parameters ----
batt.E0_kWh      = 10.0;    % initial usable capacity [kWh]
batt.E_kWh       = batt.E0_kWh;
batt.eta_c       = 0.97;    % charging efficiency
batt.eta_d       = 0.97;    % discharging efficiency
batt.P_ch_max    = 5.0;     % max charge power [kW]
batt.P_dis_max   = 5.0;     % max discharge power [kW]
batt.SOC0        = 0.50;    % initial SOC [0-1]
batt.k_cal       = 1.0e-5;  % calendar fade [kWh per hour]
batt.k_thru      = 5.0e-5;  % throughput fade [kWh per kWh-throughput]
batt.V_nom       = 52;      % nominal DC bus voltage if needed [V] (example)

% ---- Timeline & example command ----
dt = 1/60;                   % 1-minute steps in hours
T_hours = 4;                 % 4 hours
t = (0:dt:T_hours)';         % time vector
N = numel(t);

% Example command: charge for 2 h at 3 kW, then discharge 2 h at 3 kW
P_cmd = 3*ones(N,1);
P_cmd(t>2) = -3;

% (Optional) enforce limits up-front
P_cmd = max(-batt.P_dis_max, min(batt.P_ch_max, P_cmd));

% ---- Preallocate ----
SOC = zeros(N,1); SOC(1) = batt.SOC0;
E_nom = zeros(N,1); E_nom(1) = batt.E_kWh;
P_ch = zeros(N,1); P_dis = zeros(N,1);
E_throughput = zeros(N,1);     % cumulative throughput [kWh]
E_in = zeros(N,1); E_out = zeros(N,1);

% ---- Simulation loop ----
for k = 1:N-1
    % Split command
    P_ch(k)  = max(0, P_cmd(k));
    P_dis(k) = max(0,-P_cmd(k));

    % Enforce instantaneous power limits (safety)
    P_ch(k)  = min(P_ch(k),  batt.P_ch_max);
    P_dis(k) = min(P_dis(k), batt.P_dis_max);

    % SOC update with efficiencies
    dSOC = ( batt.eta_c*P_ch(k)*dt - (P_dis(k)*dt)/batt.eta_d ) / E_nom(k);
    SOC(k+1) = min(1, max(0, SOC(k) + dSOC));

    % Energy bookkeeping
    E_in(k+1)  = E_in(k)  + batt.eta_c*P_ch(k)*dt;  % stored energy [kWh]
    E_out(k+1) = E_out(k) + (P_dis(k)*dt)/batt.eta_d; % extracted energy [kWh]
    E_throughput(k+1) = E_throughput(k) + (P_ch(k)+P_dis(k))*dt;

    % Capacity fade
    dE_cal  = batt.k_cal*dt;
    dE_thru = batt.k_thru*(P_ch(k)+P_dis(k))*dt;
    E_nom(k+1) = max(0.5*batt.E0_kWh, E_nom(k) - dE_cal - dE_thru); % floor @ 50% of initial
end

% Final step values
P_ch(end)  = max(0,P_cmd(end));
P_dis(end) = max(0,-P_cmd(end));

% ---- Plots ----
figure; 
subplot(3,1,1); plot(t,P_cmd,'LineWidth',1.5); grid on; ylabel('P_{cmd} [kW]'); xlabel('Time [h]');
title('Battery Power Command');

subplot(3,1,2); plot(t,SOC,'LineWidth',1.5); grid on; ylabel('SOC [-]'); 
ylim([0 1]); title('State of Charge');

subplot(3,1,3); plot(t,E_nom,'LineWidth',1.5); grid on; ylabel('E_{nom} [kWh]'); xlabel('Time [h]');
title('Nominal Capacity with Degradation');

%% KPIs
E_roundtrip_loss_kWh = E_in(end) - (E_in(end) - (E_out(end) - (E_throughput(end)-E_in(end)))); %#ok<NASGU>
fprintf('Round-trip efficiency target: %.1f%%\n', 100*batt.eta_c*batt.eta_d);
fprintf('Energy stored total:  %.2f kWh\n', E_in(end));
fprintf('Energy extracted total: %.2f kWh\n', E_out(end));
fprintf('Capacity loss: %.3f kWh (%.2f%%)\n', batt.E0_kWh - E_nom(end), 100*(1 - E_nom(end)/batt.E0_kWh));
