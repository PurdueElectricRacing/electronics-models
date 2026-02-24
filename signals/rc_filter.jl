#=
# rc_filter.jl
# contains transformation functions of RC filters on signals
# Author: Irving Wang (irvingw@purdue.edu)
=#

function apply_rc_lowpass(;
    sim_fs,
    original_signal,
    resistance,
    capacitance
)
    # derive simulation parameters
    dt = 1 / sim_fs

    tau = resistance * capacitance
    a = exp(-dt / tau)

    filtered_signal = similar(original_signal, Float64)
    filtered_signal[1] = original_signal[1]

    # Apply the discretized form of RC lowpass
    for n in 2:lastindex(original_signal)
        filtered_signal[n] = a * filtered_signal[n-1] + (1 - a) * original_signal[n]
    end

    return filtered_signal
end
