## Combinación de óptima MSE con datos generados por generate_cv_data.jl
# Se obtienen métricas históricas y en la base 2010 del IPC para reportar

using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain
using Plots

## Directorios de resultados 
config_savepath = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI")
cv_savepath = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI", "cvdata")
test_savepath = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI", "testdata")

# Directorios de resultados de combinación MAI 
maioptfn_path = datadir("results", "CoreMai", "Esc-E-Scramble", "BestOptim", "mse-weights", "maioptfn.jld2")

# CountryStructure con datos hasta período de evaluación 
gtdata_eval = gtdata[Date(2020, 12)]


##  ----------------------------------------------------------------------------
#   Carga de trayectorias. Datos generados en generate_cv_data.jl
#   ----------------------------------------------------------------------------

testconfig = wload(joinpath(config_savepath, "cv_test_config_125k.jld2"), "testconfig")
testdata = wload(joinpath(test_savepath, savename(testconfig)))

tray_infl = testdata["infl_20"]

## Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
resamplefn = testconfig.resamplefn
trendfn = testconfig.trendfn
paramfn = testconfig.paramfn

# Medidas óptimas a diciembre de 2018
# Cargar función de inflación MAI óptima
# optmai2018_mse = wload(maioptfn_path, "maioptfn")
functions = [testconfig.inflfn.functions...]

## Obtener trayectoria paramétrica de inflación 

param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)


## Algoritmo de combinación 

# Máscara para remover exclusión fija de la combinación lineal
components_mask = [!(fn isa InflationFixedExclusionCPI) for fn in functions]

# Filtro de períodos, optimización de combinación lineal en período dic-2011 - dic-2020
combine_period = EvalPeriod(Date(2011, 12), Date(2020, 12), "combperiod") 
periods_filter = eval_periods(gtdata_eval, combine_period)

# Combinación de estimadores para minimizar el ABSME
a_optim = share_combination_weights(
    tray_infl[periods_filter, components_mask, :], 
    tray_infl_pob[periods_filter],
    show_status = true
)

dfweights = DataFrame(
    measure = measure_name.(functions[components_mask]), 
    weight = a_optim, 
    inflfn = functions[components_mask]
)

# Combinación lineal óptima para valor absoluto de error medio
optmse2022 = InflationCombination(
    dfweights.inflfn..., functions[.!components_mask]...,
    Float32[dfweights.weight..., 0], 
    "Subyacente óptima MSE 2022"
)

# Guardar función de inflación 
wsave(datadir(config_savepath, "optmse2022", "optmse2022.jld2"), "optmse2022", optmse2022)
optmse2022 = wload(datadir(config_savepath, "optmse2022", "optmse2022.jld2"), "optmse2022")


## Evaluación de trayectorias en tray_infl 

eval_window = periods_filter # Evaluación base 2010
df_results_10 = mapreduce(vcat, 1:size(tray_infl, 2)) do i 
    metrics = eval_metrics(tray_infl[eval_window, i:i, :], 
        tray_infl_pob[eval_window], 
        prefix = "gt_b10")
    df = DataFrame(metrics)
    df[!, :measure] = [measure_name(functions[i])]
    df
end

eval_window = (:) # Evaluación histórica
df_results_hist = mapreduce(vcat, 1:size(tray_infl, 2)) do i 
    metrics = eval_metrics(tray_infl[eval_window, i:i, :], 
        tray_infl_pob[eval_window])
    df = DataFrame(metrics)
    df[!, :measure] = [measure_name(functions[i])]
    df
end

df_results = innerjoin(df_results_hist, df_results_10, on = :measure)


## Evaluación de la combinación lineal a dic-20

a_optim = optmse2022.weights[1:end-1]

eval_window = periods_filter
tray_infl_opt = sum(tray_infl[eval_window, components_mask, :] .* a_optim', dims=2)
metrics = eval_metrics(tray_infl_opt, tray_infl_pob[eval_window])
combined_results_10 = DataFrame(metrics)
combined_results_10[!, :measure] = [optmse2022.name]
combined_results_10

eval_window = (:)
tray_infl_opt = sum(tray_infl[eval_window, components_mask, :] .* a_optim', dims=2)
metrics = eval_metrics(tray_infl_opt, tray_infl_pob[eval_window])
historic_df = DataFrame(metrics)
historic_df[!, :measure] = [optmse2022.name]
historic_df


## DataFrame de resultados

weights_period_results = [
    df_results[:, [:measure, :gt_b10_mse]]; 
    select(combined_results_10, :measure, :mse => :gt_b10_mse)
]

historic_results = [
    df_results[:, [:measure, :mse]]; 
    select(historic_df, :measure, :mse)
]

optmse_evalresults = innerjoin(historic_results, weights_period_results, on = :measure)
wsave(datadir(config_savepath, "optmse2022", "optmse2022_evalresults.jld2"), "optmse_evalresults", optmse_evalresults)

## Trayectorias históricas

historic_df = DataFrame(dates = infl_dates(gtdata), 
    optmse2022 = optmse2022(gtdata),
)
println(historic_df)

## Grafica de trayectorias y comparación con óptima MSE 

p1 = plot(InflationTotalCPI(), gtdata)
plot!(optmse2022, gtdata)

p2 = plot(InflationTotalCPI(), gtdata)
plot!(optmse2022.ensemble, gtdata, legend=false)

plot(p1, p2, layout=(1,2))