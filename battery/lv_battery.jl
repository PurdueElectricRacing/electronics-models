#=
# lv_battery.jl
# First-order rough LV batt sizing calcs
# Author: Irving Wang (irvingw@purdue.edu)
=#

using Unitful

# Michigan 2025 Endurance time:
const endurance_time = (1617 / 60)u"minute"

# Cell parameters
# https://cdn.shopify.com/s/files/1/0481/9678/0183/files/INR21700-RS50_2025.1.2.pdf
const RS50_capacity = 4950u"mA*hr"
const RS50_voltage = 3.6u"V"
const RS50_ACIR = 4u"mΩ" # @ 1kHz

# Battery parameters
const p_count = 3
const s_count = 7

# Find pack constants
const depth_of_charge_coeff = 0.90 # usable capacity
const end_of_life_coeff = 0.90 # aging effects
batt_capacity = RS50_capacity * p_count *
                depth_of_charge_coeff * end_of_life_coeff
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
const avg_fan_duty_cycle = 0.70
const fan_current_24V = 2u"A"
const num_fans = 9
fans_pack_current = fan_current_24V * num_fans * avg_fan_duty_cycle

# Pump loading
const avg_pump_duty_cycle = 1.00
const pump_current_24V = 3u"A"
const num_pumps = 2
pumps_pack_current = pump_current_24V * num_pumps * avg_pump_duty_cycle

# Add up active loads
active_pack_current = boards_pack_current + fans_pack_current + pumps_pack_current

# Add loss due to internal resistance @ total_pack_current
internal_power_loss = active_pack_current^2 * batt_internal_R
internal_power_loss_equiv_current = internal_power_loss / batt_voltage
total_pack_current = active_pack_current + internal_power_loss_equiv_current

# Calc runtime
runtime = uconvert(u"minute", batt_capacity / total_pack_current)
println("Runtime: ", runtime)
println("Sustained Total Current ", total_pack_current)

# Endurance factor of safety
endurance_fos = runtime / endurance_time
println("Endurance factor of safety: ", endurance_fos)
