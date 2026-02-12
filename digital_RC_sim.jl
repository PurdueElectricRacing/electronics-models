#=
This script simulates the effect of an RC lowpass
on an ideal digital signal (like a UART line with instant edges)
@author Irving Wang (irvingw@purdue.edu)
=#

using Random
using Plots
using Printf

# Source signal configuration
const baud_rate = 1e6 # bits per second
const num_bits = 30   # num bits to simulate
const digital_high_volts = 3.3 # voltage of digital 1
const digital_low_volts = 0   # voltage of digital 0

# RC filter configuration
const R = 50    # resistance
const C = 10e-9 # capacitance

# Derive simulation parameters
const sim_fs = 100 * baud_rate
const samples_per_bit = Int(round(sim_fs / baud_rate))
const dt = 1 / sim_fs
const t_bit = 1 / baud_rate
const tau = R * C

# Generate digital source
Random.seed!(1) # use the same seed for each simulation
bit_sequence = rand(0:1, num_bits)
voltage_levels = ifelse.(bit_sequence .== 1, digital_high_volts, digital_low_volts)
digital_signal = repeat(voltage_levels, inner=samples_per_bit)

# Apply the discrete-time RC update equation to a vector of input samples
function apply_rc_lowpass(vin, R, C, dt)
    a = exp(-dt / (R * C))
    vout = similar(vin, Float64)
    vout[1] = vin[1]

    for n in 2:length(vin)
        vout[n] = a * vout[n-1] + (1 - a) * vin[n]
    end

    return vout
end

# Compute Simulation
t = (0:length(digital_signal)-1) .* dt
filtered_signal = apply_rc_lowpass(digital_signal, R, C, dt)

# Plot results
p = plot(t .* 1e6, digital_signal, label="ideal digital signal", xlabel="time (µs)", ylabel="voltage", lw=1)
plot!(t .* 1e6, filtered_signal, label="RC filtered signal", lw=1)
title!(p, @sprintf("%.2e baud, R=%.2e Ω, C=%.2e F", baud_rate, R, C))
for k in 0:num_bits # add lines to show bit periods
    vline!(p, [k * t_bit * 1e6], color=:black, alpha=0.2, label=false)
end

# Hold the plot open when running julia from the terminal
gui()
readline()
