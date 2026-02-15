#=
# thermistor_plot.jl
# using data sheet values to understand behavior of our battery thermistors
# Author: Irving Wang (irvingw@purdue.edu)
=#

using Plots

# Part number: B57861S0103-A039
# https://www.tdk-electronics.tdk.com/inf/50/db/ntc/NTC_Mini_sensors_S861.pdf
const R25 = 1e3
const B25_100 = 3988.0
const T25K = 25 + 273.15

# T values are in 5 step increments
const T_START = -55.0
const T_END = 155.0
const T_STEP = 5.0
const T_C = collect(T_START:T_STEP:T_END)

# from pg 6: R/T No. 8016
const RT_over_R25 = [
    96.3, 67.01, 47.17, 33.65, 24.26, # -55 to -35
    17.7, 13.04, 9.707, 7.293, 5.533, # -30 to -10
    4.232, 3.265, 2.539, 1.99, 1.571, # -5 to 15
    1.249, 1.0000, 0.8057, 0.6531, 0.5327, # 20 to 40
    0.4369, 0.3603, 0.2986, 0.2488, 0.2083, # 45 to 65
    0.1752, 0.1481, 0.1258, 0.1072, 0.09177, # 70 to 90
    0.07885, 0.068, 0.05886, 0.05112, 0.04454, # 95 to 115
    0.03893, 0.03417, 0.03009, 0.02654, 0.02348, # 120 to 140
    0.02083, 0.01853, 0.01653 # 145 to 155
]
const RT = RT_over_R25 .* R25

# compute standard thermistor model
beta_model(Tc) = R25 * exp(B25_100 * (1.0 / (Tc + 273.15) - 1.0 / T25K))
T_C_dense = collect(range(minimum(T_C), maximum(T_C), length=1000))
R_beta = beta_model.(T_C_dense)

p = plot(xlabel="Temperature (°C)", ylabel="Resistance (Ω)", dpi=600)
title!(p, "B57861S0103A039\n Resistance vs Temperature (R25=10k, B=3988K)")
plot!(T_C, RT, marker=:circle, label="Derived from datasheet")
plot!(T_C_dense, R_beta; lw=2, label="Beta model")

savefig("plot.png")

# gui()
# readline()
