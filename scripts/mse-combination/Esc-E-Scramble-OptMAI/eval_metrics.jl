##  ----------------------------------------------------------------------------
#   Evaluación de variantes de combinación de esetimadores óptimos de inflación
#   utilizando metodología de evaluación hasta diciembre de 2018. En la
#   combinación lineal de estimadores, se utilizan los ponderadores de mínimos
#   cuadrados y sus variantes con regularización y restricciones 
#   ----------------------------------------------------------------------------
using DrWatson
@quickactivate "HEMI" 

using HEMI 
using Plots
using CSV
using DataFrames, Chain, PrettyTables

# Rutas de datos y resultados 
config_savepath = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI")
test_savepath = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI", "testdata")
results_path = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI", "results")
compilation_path = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI", "compilation")
plots_path = mkpath(plotsdir("mse-combination", "Esc-E-Scramble-OptMAI", "compilation-results"))

# Funciones de apoyo
include(scriptsdir("mse-combination-2019", "optmse2019.jl"))
include(scriptsdir("mse-combination", "optmse2022.jl"))

# Métricas de evaluación se obtienen en el período de la base 2010 (sin la
# transición)
metrics_config = Dict(
    :eval_date_start => Date(2011, 12), # Inicio período de evaluación 
    :weights_date_start => Date(2011, 12) # Inicio período de ajuste de ponderadores
)

##  ----------------------------------------------------------------------------
#   Cargar datos y configuración de prueba 
#   ----------------------------------------------------------------------------

cvconfig, testconfig = wload(
    joinpath(config_savepath, "cv_test_config_125k.jld2"), 
    "cvconfig", "testconfig"
)

testdata = wload(joinpath(test_savepath, savename(testconfig)))


##  ----------------------------------------------------------------------------
#   Métricas de evaluación 
#   ----------------------------------------------------------------------------

gtdata_20 = gtdata[Date(2020, 12)]
tray_infl = testdata["infl_20"]
tray_param = testdata["param_20"]

# Métricas de evaluación en período de optimización: diciembre de 2001 a diciembre de 2018
period = EvalPeriod(Date(2001, 12), Date(2018, 12), "optim")
evalmask = eval_periods(gtdata_20, period)

# Evaluación de las medidas individuales
mse_opt_measures = mean(x -> x^2, tray_infl[evalmask, :, :] .- tray_param[evalmask], dims=[1,3]) |> vec
# Evaluación medida combinada 
w = weights(optmse2022)
tray_infl_optmse = sum(tray_infl .* w', dims=2)
mse_opt_optmse = mean(x -> x^2, tray_infl_optmse[evalmask, :, :] .- tray_param[evalmask])


# Métricas de evaluación en período de ajuste de ponderadores: diciembre de 2011 a diciembre de 2020
period = EvalPeriod(Date(2011, 12), Date(2020, 12), "weights")
evalmask = eval_periods(gtdata_20, period)

# Evaluación de las medidas individuales
mse_wperiod_measures = mean(x -> x^2, tray_infl[evalmask, :, :] .- tray_param[evalmask], dims=[1,3]) |> vec
# Evaluación medida combinada 
w = weights(optmse2022)
tray_infl_optmse = sum(tray_infl .* w', dims=2)
mse_wperiod_optmse = mean(x -> x^2, tray_infl_optmse[evalmask, :, :] .- tray_param[evalmask])

# DataFrame de MSE de evaluación en período de optimización y ajuste de ponderadores
opt_metrics = DataFrame(
    measure = measure_name.([testconfig.inflfn.functions..., optmse2022]),
    mse_opt_period = [mse_opt_measures; mse_opt_optmse], 
    mse_wperiod_period = [mse_wperiod_measures; mse_wperiod_optmse]
)

CSV.write(joinpath(config_savepath, "metrics.csv"), opt_metrics)

## Intervalos de confianza simples óptima MSE

# Distribución de errores en período de ajuste de ponderadores
err_dist_b10 = vec(tray_infl_optmse[evalmask, :, :] .- tray_param[evalmask])
q_975 = quantile(err_dist_b10, [0.0125, 0.9875])
# q_95 = quantile(err_dist_b10, [0.025, 0.975])
histogram(err_dist_b10, normalize=:pdf)

# Intervalos de confianza
opt_limits = optmse2022(gtdata) .- reverse(q_975)'
dates = infl_dates(gtdata)
optmse_ci = [fill(missing, 120, 2); opt_limits[dates .>= Date(2011,12), :]]

plot(optmse2022, gtdata, lw=2)
plot!(dates, opt_ci, label=["Lim. inf 97.5%" "Lim. sup 97.5%"])


# Distribución de errores en período completo
err_dist = vec(tray_infl_optmse .- tray_param)
histogram(err_dist, normalize=:pdf)
quantile(err_dist, [0.0125, 0.9875])