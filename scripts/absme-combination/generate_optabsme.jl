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
config_savepath = datadir("results", "absme-combination", "Esc-G")
tray_dir = datadir(config_savepath, "tray_infl")

# Directorios de resultados de combinación MAI 
maioptfn_path = datadir("results", "CoreMai", "Esc-G", "BestOptim", "absme-weights", "maioptfn.jld2")

# CountryStructure con datos hasta período de evaluación 
gtdata_eval = gtdata[Date(2020, 12)]


include(scriptsdir("mse-combination", "optmse2022.jl"))

##  ----------------------------------------------------------------------------
#   Configuración de simulación para generación de trayectorias de combinación
#   de valor absoluto de error medio
#   ----------------------------------------------------------------------------

## Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk() 
paramfn = InflationTotalRebaseCPI(36, 2)

# Medidas óptimas a diciembre de 2018

# Cargar función de inflación MAI óptima
optmai2018_absme = wload(maioptfn_path, "maioptfn")

# Configurar el conjunto de medidas a combinar

# Medida de exclusión fija óptima para minimizar el ABSME
infxexc = InflationFixedExclusionCPI(
    [35, 30, 190, 36, 37, 40, 31, 104, 162], 
    [29, 116, 31, 46, 39, 40])

inflfn = InflationEnsemble(
    InflationPercentileEq(71.6344), 
    InflationPercentileWeighted(69.5585), 
    InflationTrimmedMeanEq(35.2881, 93.4009), 
    InflationTrimmedMeanWeighted(34.1943, 93), 
    InflationDynamicExclusion(1.03194, 3.42365), 
    infxexc,
    optmai2018_absme
)

##  ----------------------------------------------------------------------------
#   Generación de datos de simulación 
#
#   Generar datos de simulación para algoritmo de combinación de valor absoluto
#   de error medio. 
#   ----------------------------------------------------------------------------

config_absme = Dict(
    :inflfn => [inflfn.functions...], 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => Date(2020,12),
    :nsim => 125_000) |> dict_list

run_batch(gtdata, config_absme, config_savepath)

## Combinación de valor absoluto de error medio 
df_results = collect_results(config_savepath)

@chain df_results begin 
    select(:measure, :absme, :me)
end

# DataFrame de combinación 
combine_df = @chain df_results begin 
    select(:measure, :absme, :me, :inflfn, 
        :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path)
    sort(:absme)
end

## Obtener las trayectorias de los archivos guardados en el directorio tray_infl 
# Genera un arreglo de 3 dimensiones de trayectorias (T, n, K)
tray_infl = mapreduce(hcat, combine_df.tray_path) do path
    load(path, "tray_infl")
end

## Obtener trayectoria paramétrica de inflación 

resamplefn = df_results[1, :resamplefn]
trendfn = df_results[1, :trendfn]
paramfn = df_results[1, :paramfn]
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)


## Algoritmo de combinación 

functions = combine_df.inflfn
components_mask = [!(fn isa InflationFixedExclusionCPI) for fn in functions]
# components_mask = [true for _ in functions]

# Filtro de períodos, optimización de combinación lineal en período dic-2011 - dic-2020
combine_period = EvalPeriod(Date(2011, 12), Date(2020, 12), "combperiod") 
periods_filter = eval_periods(gtdata_eval, combine_period)

# Combinación de estimadores para minimizar el ABSME
a_optim = absme_combination_weights(tray_infl[periods_filter, components_mask, :], tray_infl_pob[periods_filter],
    show_status = true
)

dfweights = DataFrame(
    measure = combine_df.measure[components_mask], 
    weight = a_optim, 
    inflfn = functions[components_mask]
)

# Combinación lineal óptima para valor absoluto de error medio
optabsme2022 = InflationCombination(
    dfweights.inflfn..., infxexc,
    Float32[dfweights.weight..., 0], 
    "Subyacente óptima ABSME 2022"
)

# Guardar función de inflación 
wsave(datadir(config_savepath, "optabsme2022", "optabsme2022.jld2"), "optabsme2022", optabsme2022)
optabsme2022 = wload(datadir(config_savepath, "optabsme2022", "optabsme2022.jld2"), "optabsme2022")


## Evaluación de la combinación lineal a dic-20

a_optim = optabsme2022.weights[1:end-1]

eval_window = periods_filter
tray_infl_opt = sum(tray_infl[eval_window, components_mask, :] .* a_optim', dims=2)
metrics = eval_metrics(tray_infl_opt, tray_infl_pob[eval_window])
combined_results_10 = DataFrame(metrics)
combined_results_10[!, :measure] = [optabsme2022.name]
combined_results_10

eval_window = (:)
tray_infl_opt = sum(tray_infl[eval_window, components_mask, :] .* a_optim', dims=2)
metrics = eval_metrics(tray_infl_opt, tray_infl_pob[eval_window])
historic_df = DataFrame(metrics)
historic_df[!, :measure] = [optabsme2022.name]
historic_df

## DataFrame de resultados

weights_period_results = [
    df_results[:, [:measure, :gt_b10_absme]]; 
    select(combined_results_10, :measure, :absme => :gt_b10_absme)
]

historic_results = [
    df_results[:, [:measure, :absme]]; 
    select(historic_df, :measure, :absme)
]

optabsme_evalresults = innerjoin(historic_results, weights_period_results, on = :measure)
wsave(datadir(config_savepath, "optabsme2022", "optabsme2022_evalresults.jld2"), "optabsme_evalresults", optabsme_evalresults)

## Trayectorias históricas

historic_df = DataFrame(dates = infl_dates(gtdata), 
    optmse2022 = optmse2022(gtdata),
    optabsme2022 = optabsme2022(gtdata)
)
println(historic_df)

## Grafica de trayectorias y comparación con óptima MSE 

p1 = plot(InflationTotalCPI(), gtdata)
plot!(optabsme2022, gtdata)
plot!(optmse2022, gtdata)

p2 = plot(InflationTotalCPI(), gtdata)
plot!(optabsme2022.ensemble, gtdata, legend=false)

plot(p1, p2, layout=(1,2))