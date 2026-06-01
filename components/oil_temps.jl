using DelimitedFiles
using Measures
using Plots

const DATA_FILE = joinpath(@__DIR__, "..", "datasets", "oil_temps.csv")
const OUTPUT_FILE = joinpath(@__DIR__, "..", "figures", "oil_temp_error.png")
const SENSOR_SCALE = 0.01

raw_data, raw_header = readdlm(DATA_FILE, ',', header=true)
header = vec(String.(raw_header))
data = Float64.(raw_data)

actual = data[:, 1]
sensors = 2:size(data, 2)

p = plot(
    layout=(length(sensors), 1),
    size=(1000, 700),
    dpi=600,
    plot_title="Oil temperature sensor error",
    left_margin=10mm,
    legend=false,
)

for (i, col) in enumerate(sensors)
    scatter!(
        p,
        actual,
        data[:, col] .* SENSOR_SCALE .- actual,
        subplot=i,
        title=header[col],
        xlabel=i == length(sensors) ? "$(header[1]) temperature (°C)" : "",
        ylabel="error (°C)",
        markersize=4,
        markerstrokewidth=0,
    )
    hline!(p, [0], subplot=i, color=:black, linestyle=:dash, alpha=0.8)
end

mkpath(dirname(OUTPUT_FILE))
savefig(p, OUTPUT_FILE)
println("Saved plot to ", OUTPUT_FILE)

gui()
readline()
