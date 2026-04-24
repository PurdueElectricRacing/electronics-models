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
const RS50_capacity = 4950u"mA*hr"
const RS50_voltage = 3.6u"V"
const RS50_DCIR = 6.5u"mΩ" # found from independent testing by "Battery Mooch"
# https://www.e-cigarette-forum.com/threads/bench-test-results-reliance-rs50-ccc-logo-70a-4950mah-21700.992097/

# LV Battery parameters
const p_count = 4
const s_count = 7

# Calc pack constants
const depth_of_charge_coeff = 0.90 # usable capacity
const end_of_life_coeff = 0.90 # aging effects
batt_capacity = RS50_capacity * p_count * depth_of_charge_coeff * end_of_life_coeff
batt_voltage = RS50_voltage * s_count
batt_energy = batt_capacity * batt_voltage
batt_internal_R = (s_count * RS50_DCIR) / p_count

# Buck converter 24V -> 5V
# https://www.ti.com/lit/ds/symlink/lm53602.pdf
const LM53603_efficiency_coeff = 0.80 # Approximation based on figure 21

# Known board loads @ 5V
const single_board_power = 0.2u"A" * 5u"V"
const num_boards = 8
lv_boards_power = single_board_power * num_boards
lv_boards_power = lv_boards_power / LM53603_efficiency_coeff # account for buck losses

# Fans
const avg_fan_duty_cycle = 0.80
const num_fans = 5
fans_pack_power = duty2watts_40_9CRA(avg_fan_duty_cycle) * num_fans

# Pumps
const avg_pump_duty_cycle = 1.00
const pump_power_25V = 3u"A" * 25u"V" # todo: characterize pumps
const num_pumps = 2
pumps_pack_power = pump_power_25V * num_pumps * avg_pump_duty_cycle

# AMK inverter LV
const avg_inverter_power_24V = 0.45u"A" * 24u"V" # benchtop measurement
const num_inverters = 4
inverters_pack_power = avg_inverter_power_24V * num_inverters

# Bullet Radio
const bullet_radio_power = 0.1u"A" * 24u"V" # benchtop measurement

# Add up active loads
total_active_power = lv_boards_power + fans_pack_power + pumps_pack_power + inverters_pack_power + bullet_radio_power

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
const endurance_run_time = (1617 / 60)u"minute" # Michigan 2025 Endurance
const endurance_wait_time = 5u"minute"
total_endurance_time = endurance_run_time + endurance_wait_time
endurance_fos = runtime / total_endurance_time
@printf("Endurance factor of safety: %.2f\n", endurance_fos)

# Plot the load pie chart
labels = ["Boards", "Fans", "Pumps", "Inverter LV", "Bullet Radio", "Internal Loss"]
values = [
    ustrip(u"W", lv_boards_power),
    ustrip(u"W", fans_pack_power),
    ustrip(u"W", pumps_pack_power),
    ustrip(u"W", inverters_pack_power),
    ustrip(u"W", bullet_radio_power),
    ustrip(u"W", internal_power_loss)
]
# @show labels, values
p = pie(labels, values, dpi=300)
title!(p, @sprintf("Projected PER26 LV Power Loads @%ds%dp", s_count, p_count))

savefig("figures/per26_lv_loads.png")

gui()
readline()
