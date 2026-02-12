#=
# isoSPI_wavegen.jl
# generates a typical isoSPI waveform according to datasheet values
# Author: Irving Wang (irvingw@purdue.edu)
=#

using Random

# isoSPI parameters (typical)
# https://www.analog.com/media/en/technical-documentation/data-sheets/adbms6821-adbms6822.pdf
const pulse_amplitude = 1.25
const t_pulse_long = 150e-9 # half-width (long)
const t_pulse_short = 50e-9 # half-width (short)

# Main pulse generation function
function generate_pulse(bit, n_half)
    if (bit == 1)
        first_half = fill(+pulse_amplitude, n_half)
        second_half = fill(-pulse_amplitude, n_half)
    else
        first_half = fill(-pulse_amplitude, n_half)
        second_half = fill(+pulse_amplitude, n_half)
    end

    pulse = vcat(first_half, second_half)
    return pulse
end

# Helper functions
generate_data_high(n_half) = generate_pulse(1, n_half)
generate_data_low(n_half) = generate_pulse(0, n_half)
generate_cs_falling_edge(n_half) = generate_pulse(0, n_half)
generate_cs_rising_edge(n_half) = generate_pulse(1, n_half)

# Compute signals
function generate_isoSPI(;
    baud_rate, # bits per second
    num_bits,  # num bits to simulate
    oversample,
    rand_seed,
)
    # derive simulation parameters
    sim_fs = oversample * baud_rate
    dt = 1 / sim_fs
    samples_per_bit = Int(round(sim_fs / baud_rate))

    # derive waveform parameters
    n_half_short = Int(round(t_pulse_short / dt))
    n_half_long = Int(round(t_pulse_long / dt))

    short_pair_len = 2 * n_half_short
    pad_len = samples_per_bit - short_pair_len

    # generate random bits
    Random.seed!(rand_seed)
    bits = rand(0:1, num_bits)

    # start with an empty vector then construct the wave by isoSPI event
    wave = Float64[]

    append!(wave, zeros(pad_len))
    append!(wave, generate_cs_falling_edge(n_half_long))
    append!(wave, zeros(pad_len))

    for b in bits
        append!(
            wave, (b == 1) ?
                  generate_data_high(n_half_short) :
                  generate_data_low(n_half_short)
        )
        append!(wave, zeros(pad_len))
    end

    append!(wave, generate_cs_rising_edge(n_half_long))
    append!(wave, zeros(pad_len))

    return wave, sim_fs
end
