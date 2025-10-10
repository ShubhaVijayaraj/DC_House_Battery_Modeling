-------------------------------------------------------------------------------
Overview
-------------------------------------------------------------------------------
This MATLAB script implements a simple discrete-time battery model to simulate
energy storage and discharge behavior for EV or stationary batteries (e.g., the
GM Energy PowerBank). It tracks how the state of charge (SOC) and usable energy
capacity change over time based on user-defined power commands, efficiencies,
and degradation rates.

The model is designed to:
- Demonstrate battery charging and discharging under power constraints.
- Include charge/discharge efficiency losses.
- Account for gradual degradation (capacity fade) over time.
- Plot SOC, power commands, and capacity changes.

-------------------------------------------------------------------------------
Key Parameters
-------------------------------------------------------------------------------
All parameters are defined at the top of the script under the section 'Parameters'.

Variable          Meaning                               Units     Example
------------------------------------------------------------------------------
batt.E0_kWh       Initial usable energy capacity         kWh       10.0
batt.eta_c        Charging efficiency                    -         0.97
batt.eta_d        Discharging efficiency                 -         0.97
batt.P_ch_max     Max charging power                     kW        5.0
batt.P_dis_max    Max discharging power                  kW        5.0
batt.SOC0         Initial state of charge (0–1)          -         0.5
batt.k_cal        Calendar degradation rate              kWh/hr    1.0e-5
batt.k_thru       Throughput degradation rate            kWh/kWh   5.0e-5
batt.V_nom        Nominal voltage (for current calc.)    V         52

-------------------------------------------------------------------------------
Simulation Flow
-------------------------------------------------------------------------------
1. Parameter setup:
   Defines battery characteristics and simulation duration.

2. Create time vector:
   Uses a 1-minute timestep (dt = 1/60 hours) for a 4-hour test case.

3. Generate power command (P_cmd):
   +3 kW charge for the first 2 hours, then -3 kW discharge for the next 2 hours.

4. Loop through each timestep:
   - Calculates charge/discharge energy flow using efficiencies.
   - Updates SOC and total energy throughput.
   - Applies degradation using calendar and throughput rates.
   - Enforces physical limits (SOC between 0–1, capacity ≥ 50%).

5. Plots:
   - Battery Power Command (kW)
   - State of Charge (SOC)
   - Nominal Capacity (kWh)

6. KPIs (Key Performance Indicators):
   Prints summary results for round-trip efficiency, energy stored/extracted, and capacity loss.

-------------------------------------------------------------------------------
Output Example
-------------------------------------------------------------------------------
Round-trip efficiency target: 94.1%
Energy stored total:  5.82 kWh
Energy extracted total: 5.99 kWh
Capacity loss: 0.002 kWh (0.02%)

Three plots are generated to visualize power, SOC, and capacity over time.

-------------------------------------------------------------------------------
Customization Notes
-------------------------------------------------------------------------------
- Change batt.E0_kWh to match a real system (e.g., 17.7 kWh for the GM PowerBank e1.17).
- Modify P_cmd for real power data from sensors or control commands.
- Adjust degradation constants to simulate aging.
- Possible extensions:
  - Add temperature dependence
  - Include efficiency variation with SOC
  - Add voltage-SOC relationships
  - Integrate into Simulink model
