#=
# signal_sim.jl
# general purpose signal simulation script
# Author: Irving Wang (irvingw@purdue.edu)
=#

include("digital_wavegen.jl")
include("isoSPI_wavegen.jl")
include("rc_filter.jl")

using Plots
using Printf

# Source signal configuration
const baud_rate = 1e6 # bits per second
const num_bits = 20   # num bits to simulate

# RC filter configuration
const R = 60.4   # resistance
const C = 4.7e-9 # capacitance

# Generate a signal
# original_signal, sim_fs = generate_digital_wave(
#     baud_rate=baud_rate,
#     num_bits=num_bits,
#     digital_high_volts=3.3,
#     digital_low_volts=0,
#     oversample=100,
#     rand_seed=1
# )

original_signal, sim_fs = generate_isoSPI(
    baud_rate=baud_rate,
    num_bits=num_bits,
    oversample=100,
    rand_seed=1
)

# Apply transformations
filtered_signal = apply_rc_lowpass(
    sim_fs=sim_fs,
    original_signal=original_signal,
    resistance=R,
    capacitance=C
)

# Plot results
const dt = 1 / sim_fs
time = (0:lastindex(original_signal)-1) .* dt
p = plot(xlabel="time (µs)", ylabel="voltage", dpi=600, size=(3600, 1200))
plot!(p, time .* 1e6, original_signal, label="Input signal")
plot!(p, time .* 1e6, filtered_signal, label="Output signal")

const t_per_bit = 1 / baud_rate
const line_delay_us = 1
title!(p, @sprintf("%.2e baud, R=%.2e Ω, C=%.2e F", baud_rate, R, C))
for k in 1:num_bits # add lines to show bit periods
    vline!(p, [k * t_per_bit * 1e6 + line_delay_us], color=:black, alpha=0.3, label=false)
end

savefig("plot.png")

# Hold the plot open when running julia from the terminal
gui()
readline()
