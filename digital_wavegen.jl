#=
# digital_wavegen.jl
# generates an ideal digital waveform (instant edges)
# Author: Irving Wang (irvingw@purdue.edu)
=#

using Random

function generate_digital_wave(;
    baud_rate,          # bits per second
    num_bits,           # num bits to simulate
    digital_high_volts, # voltage of digital 1
    digital_low_volts,  # voltage of digital 0
    oversample,
    rand_seed,
)
    # derive simulation parameters
    sim_fs = oversample * baud_rate
    samples_per_bit = Int(round(sim_fs / baud_rate))

    # generate random bits
    Random.seed!(rand_seed)
    bit_sequence = rand(0:1, num_bits)

    # fill wave vector (assumes equal high/low durations per bit)
    voltage_levels = ifelse.(bit_sequence .== 1, digital_high_volts, digital_low_volts)
    wave = repeat(voltage_levels, inner=samples_per_bit)

    return wave, sim_fs
end
