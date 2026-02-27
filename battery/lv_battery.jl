#=
# lv_battery.jl
# First-order rough LV batt sizing calcs
# Author: Irving Wang (irvingw@purdue.edu)
=#

using Unitful
using Plots
using Printf

# Michigan 2025 Endurance times
const endurance_run_time = (1617 / 60)u"minute"
const endurance_wait_time = 5u"minute"
total_endurance_time = endurance_run_time + endurance_wait_time

# Cell parameters
# https://cdn.shopify.com/s/files/1/0481/9678/0183/files/INR21700-RS50_2025.1.2.pdf
const RS50_capacity = 4950u"mA*hr"
const RS50_voltage = 3.6u"V"
const RS50_ACIR = 4u"mΩ" # @ 1kHz

# Battery parameters
const p_count = 4
const s_count = 7

# Find pack constants
const depth_of_charge_coeff = 0.90 # usable capacity
const end_of_life_coeff = 0.90 # aging effects
batt_capacity = RS50_capacity * p_count * depth_of_charge_coeff * end_of_life_coeff
batt_voltage = RS50_voltage * s_count
batt_energy = batt_capacity * batt_voltage
batt_internal_R = (s_count * RS50_ACIR) / p_count

# Buck converter 24V -> 5V
# https://www.ti.com/lit/ds/symlink/lm53602.pdf
const LM53603_efficiency_coeff = 0.80 # Approximation based on figure 21

# Known board loads @ 5V
const single_board_current = 0.2u"A"
const board_voltage = 5u"V"
const num_boards = 8
board_power_5V = single_board_current * board_voltage * num_boards # W
# account for buck energy loss
boards_power_from_pack = board_power_5V / LM53603_efficiency_coeff
boards_pack_current = boards_power_from_pack / batt_voltage

# Fan loading
const fan_currents_24V = [
    0, 0.11, 0.154, 0.2, 0.26, 0.325,     # 0 - 25% duty
    0.404, 0.5, 0.606, 0.733, 0.891,      # 30 - 50% duty
    1.035, 1.226, 1.41, 1.58, 1.806,      # 55 - 75% duty
    2.02, 2.225, 2.47, 2.515, 2.52        # 80 - 100% duty
] # benchtop measurement off a 24V supply (fans pairs tied together)
# scale the power load to the battery voltage
fan_currents = fan_currents_24V .* (24u"V" / batt_voltage)
const avg_fan_duty_cycle = 0.70
idx = round(Int, avg_fan_duty_cycle * 100 / 5) + 1
scaled_fan_current = fan_currents[idx] * u"A"
const num_fans = 5
fans_pack_current = scaled_fan_current * num_fans

# Pump loading
const avg_pump_duty_cycle = 1.00
const pump_current_25V = 3u"A" # todo: characterize pumps
const num_pumps = 2
pumps_pack_current = pump_current_25V * num_pumps * avg_pump_duty_cycle

# AMK inverter loading
const avg_inverter_current_24V = 0.45u"A"  # benchtop measurement
const num_inverters = 4
inverters_pack_current = avg_inverter_current_24V * num_inverters

# Add up active loads
active_pack_current = boards_pack_current + fans_pack_current + pumps_pack_current + inverters_pack_current

# Add loss due to internal resistance @ total_pack_current
internal_power_loss = active_pack_current^2 * batt_internal_R
internal_power_loss_equiv_current = internal_power_loss / batt_voltage
total_pack_current = active_pack_current + internal_power_loss_equiv_current

# Calc runtime
runtime = uconvert(u"minute", batt_capacity / total_pack_current)
@printf("Runtime: %.2f\n", runtime)
@printf("Sustained Total Current: %.2f\n", total_pack_current)

# Endurance factor of safety
endurance_fos = runtime / total_endurance_time
@printf("Endurance factor of safety: %.2f\n", endurance_fos)

# Plot the load pie chart
labels = ["Boards", "Fans", "Pumps", "Inverter LV", "Internal Loss (equiv)"]
values = [
    ustrip(u"A", boards_pack_current),
    ustrip(u"A", fans_pack_current),
    ustrip(u"A", pumps_pack_current),
    ustrip(u"A", inverters_pack_current),
    ustrip(u"A", internal_power_loss_equiv_current)
]
# @show labels, values
p = pie(labels, values, dpi=300)
title!(p, @sprintf("Projected PER26 LV Current Loads @%ds%dp", s_count, p_count))

savefig("figures/per26_lv_loads.png")

gui()
readline()
