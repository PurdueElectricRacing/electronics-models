#=
# lv_battery.jl
# First-order rough LV batt sizing calcs
# Author: Irving Wang (irvingw@purdue.edu)
=#

using Unitful, Plots, Printf

# Include components
include("../components/40_9CRA_fan.jl")

# Cell parameters
# https://cdn.shopify.com/s/files/1/0481/9678/0183/files/INR21700-RS50_2025.1.2.pdf
const RS50_CAPACITY = 4950u"mA*hr"
const RS50_NOMINAL_VOLTAGE = 3.6u"V"
const RS50_DCIR = 6.5u"mΩ" # found from independent testing by "Battery Mooch"
# https://www.e-cigarette-forum.com/threads/bench-test-results-reliance-rs50-ccc-logo-70a-4950mah-21700.992097/

# LV Battery parameters
const P_COUNT = 4
const S_COUNT = 7
const DEPTH_OF_CHARGE_COEFF = 0.90 # usable capacity
const END_OF_LIFE_COEFF = 0.95 # aging effects

# Calc pack constants
batt_usable_capacity = RS50_CAPACITY * P_COUNT * DEPTH_OF_CHARGE_COEFF * END_OF_LIFE_COEFF
batt_voltage = RS50_NOMINAL_VOLTAGE * S_COUNT
batt_energy = batt_usable_capacity * batt_voltage
batt_internal_R = (S_COUNT * RS50_DCIR) / P_COUNT

# Buck converter 24V -> 5V
# https://www.ti.com/lit/ds/symlink/lm53602.pdf
const LM53603_EFFICIENCY_COEFF = 0.80 # Approximation based on figure 21

# Measured board loads @ 5V
const SINGLE_BOARD_POWER = 0.2u"A" * 5u"V"
const NUM_BOARDS = 8
lv_boards_power = SINGLE_BOARD_POWER * NUM_BOARDS
lv_boards_power = lv_boards_power / LM53603_EFFICIENCY_COEFF # account for buck losses

# Fans
const AVG_FAN_DUTY_CYCLE = 0.80
const NUM_FANS = 5
fans_pack_power = duty2watts_40_9CRA(AVG_FAN_DUTY_CYCLE) * NUM_FANS

# Pumps
const AVG_PUMP_DUTY_CYCLE = 1.00
const PUMP_POWER_25V = 3u"A" * 25u"V" # todo: characterize pumps
const NUM_PUMPS = 2
pumps_pack_power = PUMP_POWER_25V * NUM_PUMPS * AVG_PUMP_DUTY_CYCLE

# AMK inverter LV
const AVG_INVETER_POWER_24V = 0.45u"A" * 24u"V" # benchtop measurement
const NUM_INVETERS = 4
inverters_pack_power = AVG_INVETER_POWER_24V * NUM_INVETERS

# Bullet Radio
const BULLET_RADIO_POWER = 0.1u"A" * 24u"V" # benchtop measurement

# Add up active loads
total_active_power = lv_boards_power + fans_pack_power + pumps_pack_power + inverters_pack_power + BULLET_RADIO_POWER

# Add loss due to internal resistance @ nominal voltage
# I_nominal = P_active / V_nominal
active_pack_current_nominal = total_active_power / batt_voltage
internal_power_loss = active_pack_current_nominal^2 * batt_internal_R
total_pack_power = total_active_power + internal_power_loss

# Calc runtime
runtime = uconvert(u"minute", batt_energy / total_pack_power)
@printf("Runtime: %.2f\n", runtime)
@printf("Sustained Total Power: %.2f\n", total_pack_power)

# Endurance factor of safety
const ENDURANCE_RUN_TIME = (1617 / 60)u"minute" # Michigan 2025 Endurance
const ENDURANCE_WAIT_TIME = 5u"minute"
total_endurance_time = ENDURANCE_RUN_TIME + ENDURANCE_WAIT_TIME
endurance_fos = runtime / total_endurance_time
@printf("Endurance factor of safety: %.2f\n", endurance_fos)

# Plot the load pie chart
labels = ["Boards", "Fans", "Pumps", "Inverter LV", "Bullet Radio", "Internal Loss"]
values = [
    ustrip(u"W", lv_boards_power),
    ustrip(u"W", fans_pack_power),
    ustrip(u"W", pumps_pack_power),
    ustrip(u"W", inverters_pack_power),
    ustrip(u"W", BULLET_RADIO_POWER),
    ustrip(u"W", internal_power_loss)
]
percentages = values ./ sum(values) .* 100
labels_with_pct = [
    @sprintf("%s (%.1f%%)", labels[i], percentages[i])
    for i in eachindex(labels)
]
p = pie(labels_with_pct, values, dpi=300)
title!(p, @sprintf("PER26 LV Power Loads @%ds%dp", S_COUNT, P_COUNT))

savefig("figures/per26_lv_loads.png")

gui()
readline()
