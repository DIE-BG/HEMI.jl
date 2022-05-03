using DrWatson
@quickactivate :HEMI 
using StatsBase
using Plots
using Optim

using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Configuration 
# Change between :b00, :b10 and :b0010
PERIOD = :b00

# Inflation measure for calibrating
const PARAM_INFLFN = InflationTotalCPI() 

# Calibration evaluation periods used 
period1 = EvalPeriod(Date(2001,1), Date(2005,12), "b00_5y")
period2 = EvalPeriod(Date(2011,12), Date(2015,12), "b10_5y")

# Calibration data
if PERIOD == :b00 
    evaldata = UniformCountryStructure(GTDATA[1]) # CPI 2000 base 
    mask1 = eval_periods(evaldata, period1)
    evalmask = mask1
elseif PERIOD == :b10 
    evaldata = UniformCountryStructure(GTDATA[2]) # CPI 2010 base 
    mask2 = eval_periods(evaldata, period2)
    evalmask = mask2
else
    # All available data 
    evaldata = GTDATA[Date(2021,12)]
    mask1 = eval_periods(evaldata, period1)
    mask2 = eval_periods(evaldata, period2)
    evalmask = mask1 .| mask2 
end

# Directorio de gráficas 
plots_path = mkpath(plotsdir("trended-resample", 
    "total-cpi-calibration", 
    "five-years"
))

## Funciones para calibrar el parámetro de probabilidad de ocurrencia contemporánea (p) 
# MSE observado
function mse_obs(p; data=evaldata)
    inflfn = PARAM_INFLFN

    paramfn = PARAM_INFLFN
    resamplefn = ResampleScrambleTrended(p)
    trendfn = TrendIdentity()
    param = InflationParameter(paramfn, resamplefn, trendfn)

    tray_infl = inflfn(data)
    tray_infl_param = param(data)
    mse = mean(x -> x^2, tray_infl[evalmask] - tray_infl_param[evalmask])
    mse
end

# Mediana del MSE de las realizaciones 
function mse_simu(p; data=evaldata, K=10_000)
    inflfn = PARAM_INFLFN 
    resamplefn = ResampleScrambleTrended(p)
    trendfn = TrendIdentity() 

    tray_infl = pargentrayinfl(inflfn, resamplefn, trendfn, data; K)
    
    paramfn = PARAM_INFLFN
    resamplefn = ResampleScrambleTrended(p)
    trendfn = TrendIdentity()
    param = InflationParameter(paramfn, resamplefn, trendfn)

    tray_param = param(data)

    # MSE por realizaciones 
    mse_dist = mean(x -> x^2, tray_infl[evalmask, :, :] .- tray_param[evalmask], dims=1)
    vec(mse_dist)
end

function mse_simu_stats(p; data=evaldata, K=10_000)
    mse_dist = mse_simu(p; data, K)
    _median = median(mse_dist) # mediana de la distribución
    _mean = mean(mse_dist)
    _mode = mode(mse_dist)

    _mean, _median, _mode
end

## Generar métrica de calibración para diferentes valores de p
p_ = 0:0.1:1
# plot(mse_obs, p_)
# plot(mse_simu_stats, p_)

vals_sim = mapreduce((p -> [mse_simu_stats(p)...]), hcat, p_) |> transpose
vals_mse_obs = map(mse_obs, p_)
diff_mse = vals_sim .- vals_mse_obs

## Gráficas de MSE 

p1 = plot(p_, vals_sim, 
    label=["Media de la distribución de simulación" "Mediana de la distribución de simulación" "Moda de la distribución de simulación"],
    ylabel="Error cuadrático medio",
    # xlabel="Probabilidad de selección de período t"
)
plot!(p1, p_, vals_mse_obs, label="Observado entre Total y parámetro")

p2 = plot(p_, abs.(diff_mse), 
    label=["Diferencia absoluta con la media" "Diferencia absoluta con la mediana" "Diferencia absoluta con la moda"],
    color=[:red :blue :black], 
    linestyle = [:dot :solid :dash],
    # alpha = [0.5, 0.7, 0.9],
    linewidth=2, 
    ylabel="Error cuadrático medio",
    xlabel="Probabilidad de selección de período t"
)

plot(p1, p2, 
    size=(800,600), 
    layout = (2, 1)
)

filename = savename("mse_difference", (period=PERIOD,), "png")
savefig(joinpath(plots_path, filename))


## Using Optim to find the minimum 

res = optimize(p -> abs(mse_simu_stats(p)[2] - mse_obs(p)), 0.01, 0.99)
@info "Valor óptimo con este criterio" Optim.minimizer(res)
# ┌ Info: Valor óptimo con este criterio
# └   Optim.minimizer(res) = 0.7036687156959144

# InflationTotalCPI
# Período completo 
# ┌ Info: Valor óptimo con este criterio
# └   Optim.minimizer(res) = 0.674591082486356
# Base 2000
# ┌ Info: Valor óptimo con este criterio
# └   Optim.minimizer(res) = 0.8445503239179435
# Base 2010
# ┌ Info: Valor óptimo con este criterio
# └   Optim.minimizer(res) = 0.3979484811865918


# # InflationTotalCPI con evaluación de 5 años 
# Período completo 
# ┌ Info: Valor óptimo con este criterio
# └   Optim.minimizer(res) = 0.46031723899305166
# Base 2000
# ┌ Info: Valor óptimo con este criterio
# └   Optim.minimizer(res) = 0.5695731554158409
# Base 2010
# ┌ Info: Valor óptimo con este criterio
# └   Optim.minimizer(res) = 0.42360815127381435

p_opt = Optim.minimizer(res)

## Histograma con p óptimo 

mse_dist = mse_simu(p_opt)
stats_opt = mse_simu_stats(p_opt)
ph = histogram(mse_dist, bins=0:0.025:4, 
    label="Distribución de MSE", 
    normalize = :probability, 
    linealpha = 0.05, 
    # color = :blue, 
    xlims = (0, 3)
)
opts = Dict(:linewidth => 1.5, :linestyle => :dash, )
vline!(ph, [stats_opt[1]]; label="Media", color = :red, opts...)
vline!(ph, [stats_opt[2]]; label="Mediana", color = :blue, opts...)

h = fit(Histogram, mse_dist, 0:0.025:4)
i = argmax(h.weights)
_mode = h.edges[1][i]
vline!(ph, [_mode]; label="Moda", color = :black, opts...)

plot(ph, size = (800, 600))
filename = savename("mse_dist", (period=PERIOD,), "png")
savefig(joinpath(plots_path, filename))

## Gráficas de trayectorias con el p óptimo

function plot_mse_obs(p; data=evaldata)
    inflfn = InflationTotalCPI()

    paramfn = InflationTotalCPI()
    resamplefn = ResampleScrambleTrended(p)
    trendfn = TrendIdentity()
    param = InflationParameter(paramfn, resamplefn, trendfn)

    # mse = mean(x -> x^2, inflfn(data) - param(data))
    plot(size=(800,600))
    plot!(inflfn, data)
    plot!(infl_dates(data), param(data), label="Trayectoria paramétrica p=$(round(p,digits=5))")
end

plot_mse_obs(p_opt)
filename = savename("total_vs_param", (period=PERIOD, p=p_opt), "png")
savefig(joinpath(plots_path, filename))

function plot_mse_simu_stats(p; data=evaldata, K=10_000)
    inflfn = InflationTotalCPI() 
    resamplefn = ResampleScrambleTrended(p)
    trendfn = TrendIdentity() 

    tray_infl = pargentrayinfl(inflfn, resamplefn, trendfn, data; K)
    
    paramfn = InflationTotalCPI()
    resamplefn = ResampleScrambleTrended(p)
    trendfn = TrendIdentity()
    param = InflationParameter(paramfn, resamplefn, trendfn)

    tray_param = param(data)

    # MSE por realizaciones 
    mse_dist = mean(x -> x^2, tray_infl .- tray_param, dims=1) |> vec
    med = median(mse_dist) # mediana de la distribución
    i = argmin(abs.(mse_dist .- med))

    # Realización mediana 
    med_tray_infl = tray_infl[:, :, i]
    plot(size=(800,600))

    # Graficar una nube representativa 
    cloud_idx = rand(1:K, 200)
    tray_cloud = reduce(hcat, map(r -> tray_infl[:, :, r], cloud_idx))
    plot!(infl_dates(data), tray_cloud, label=false, color=:gray, alpha=0.1)
    
    plot!(infl_dates(data), med_tray_infl, label="Realización de la trayectoria con MSE mediano", 
        color=1, linewidth=2)
    plot!(infl_dates(data), param(data), label="Trayectoria paramétrica p=$(round(p,digits=5))", 
        color=2, linewidth=2)
end

plot_mse_simu_stats(p_opt)
filename = savename("simu_total_vs_param", (period=PERIOD, p=p_opt), "png")
savefig(joinpath(plots_path, filename))