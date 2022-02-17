using DrWatson
@quickactivate :HEMI 
using Plots
using Optim

using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

# Datos de calibración 
evaldata = GTDATA[Date(2021,12)]

# Directorio de gráficas 
plots_path = mkpath(plotsdir("trended-resample"))

## Funciones para calibrar el parámetro de probabilidad de ocurrencia contemporánea (p) 
# MSE observado
function mse_obs(p; data=evaldata)
    inflfn = InflationWeightedMean()

    paramfn = InflationWeightedMean()
    resamplefn = ResampleScrambleTrended(p)
    trendfn = TrendIdentity()
    param = InflationParameter(paramfn, resamplefn, trendfn)

    mse = mean(x -> x^2, inflfn(data) - param(data))
    mse
end

# Mediana del MSE de las realizaciones 
function mse_med(p; data=evaldata, K=10_000)
    inflfn = InflationWeightedMean() 
    resamplefn = ResampleScrambleTrended(p)
    trendfn = TrendIdentity() 

    tray_infl = pargentrayinfl(inflfn, resamplefn, trendfn, data; K)
    
    paramfn = InflationWeightedMean()
    resamplefn = ResampleScrambleTrended(p)
    trendfn = TrendIdentity()
    param = InflationParameter(paramfn, resamplefn, trendfn)

    tray_param = param(data)

    # MSE por realizaciones 
    mse_dist = mean(x -> x^2, tray_infl .- tray_param, dims=1)
    median(mse_dist) # mediana de la distribución
    # quantile(vec(mse_dist), 0.75)
end

## Generar métrica de calibración para diferentes valores de p
p_ = 0:0.1:1
# plot(mse_obs, p_)
# plot(mse_med, p_)

vals_mse_med = map(mse_med, p_)
vals_mse_obs = map(mse_obs, p_)
diff_mse = vals_mse_med - vals_mse_obs

## 
p1 = plot(p_, vals_mse_med, label="Mediana de la distribución de simulación",
    ylabel="Error cuadrático medio",
    # xlabel="Probabilidad de selección de período t"
)
plot!(p1, p_, vals_mse_obs, label="Observado entre MPA y parámetro")

p2 = plot(p_, abs.(diff_mse), label="Diferencia absoluta",
    color=:blue, linewidth=2, 
    ylabel="Error cuadrático medio",
    xlabel="Probabilidad de selección de período t"
)

plot(p1, p2, 
    size=(800,600), 
    layout = (2, 1)
)

savefig(joinpath(plots_path, "mse_difference.png"))


## Using Optim to find the minimum 

res = optimize(p -> abs(mse_med(p) - mse_obs(p)), 0.6, 0.8)
@info "Valor óptimo con este criterio" Optim.minimizer(res)
# ┌ Info: Valor óptimo con este criterio
# └   Optim.minimizer(res) = 0.7036687156959144


## 

p_opt = Optim.minimizer(res)

function plot_mse_obs(p; data=evaldata)
    inflfn = InflationWeightedMean()

    paramfn = InflationWeightedMean()
    resamplefn = ResampleScrambleTrended(p)
    trendfn = TrendIdentity()
    param = InflationParameter(paramfn, resamplefn, trendfn)

    # mse = mean(x -> x^2, inflfn(data) - param(data))
    plot(size=(800,600))
    plot!(inflfn, data)
    plot!(infl_dates(data), param(data), label="Trayectoria paramétrica p=$(round(p,digits=5))")
end

plot_mse_obs(p_opt)
savefig(joinpath(plots_path, "mpa_vs_param_$p_opt.png"))

function plot_mse_med(p; data=evaldata, K=10_000)
    inflfn = InflationWeightedMean() 
    resamplefn = ResampleScrambleTrended(p)
    trendfn = TrendIdentity() 

    tray_infl = pargentrayinfl(inflfn, resamplefn, trendfn, data; K)
    
    paramfn = InflationWeightedMean()
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

plot_mse_med(p_opt)
savefig(joinpath(plots_path, "simu_mpa_vs_param_$p_opt.png"))