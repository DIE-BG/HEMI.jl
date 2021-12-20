using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Other libraries
using DataFrames, Chain
using Plots

## Directorios de resultados 
config_savepath = datadir("results", "corr-combination", "Esc-F")
config_savepath_absme = datadir("results", "absme-combination", "Esc-G")
tray_dir = datadir(config_savepath, "tray_infl")

# Directorios de resultados de combinación MAI 
maioptfn_path = datadir("results", "CoreMai", "Esc-F", "BestOptim", "corr-weights", "maioptfn.jld2")

# CountryStructure con datos hasta período de evaluación 
gtdata_eval = gtdata[Date(2020, 12)]

# Guardar función de inflación 
optabsme2022 = wload(datadir(config_savepath_absme, "optabsme2022", "optabsme2022.jld2"), "optabsme2022")
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
optmai2018_corr = wload(maioptfn_path, "maioptfn")

# Configurar el conjunto de medidas a combinar

# Medida de exclusión fija óptima para minimizar el corr
infxexc = InflationFixedExclusionCPI(
    [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159], 
    [29, 116, 31, 46, 39, 40, 186, 30, 35, 185, 197, 34, 48, 184, 41, 47, 37, 22, 25, 229, 38, 32, 274, 3, 45, 44, 33, 237, 19, 10, 24, 275, 115, 15, 59, 42, 61, 43, 113, 49, 27, 71, 23, 268, 9, 36, 236, 78, 20, 213, 273, 26]
    )

inflfn = InflationEnsemble(
    InflationPercentileEq(0.7725222386666464), 
    InflationPercentileWeighted(0.8095570179714271), 
    InflationTrimmedMeanEq(55.90512060523032, 92.17767125368118), 
    InflationTrimmedMeanWeighted(46.44323324480888, 98.54608364886394), 
    InflationDynamicExclusion(0.46832260901857126, 4.974514492691691), 
    infxexc,
    optmai2018_corr
)

##  ----------------------------------------------------------------------------
#   Generación de datos de simulación 
#
#   Generar datos de simulación para algoritmo de combinación de valor absoluto
#   de error medio. 
#   ----------------------------------------------------------------------------

config_corr = Dict(
    :inflfn => [inflfn.functions...], 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => Date(2020,12),
    :nsim => 125_000) |> dict_list

run_batch(gtdata, config_corr, config_savepath)

## Combinación de correlacion 
df_results = collect_results(config_savepath)

@chain df_results begin 
    select(:measure, :corr, :me)
end

# DataFrame de combinación 
combine_df = @chain df_results begin 
    select(:measure, :corr, :me, :inflfn, 
        :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path)
    sort(:corr)
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

# Combinación de estimadores para minimizar el CORR
c_optim = metric_combination_weights(tray_infl[periods_filter, components_mask, :], tray_infl_pob[periods_filter];
    metric = :corr, 
    w_start = Float32[0.05, 0.05, 0.20, 0.20, 0.25, 0.25]
)

# Al ajustar estas ponderaciones se obtiene prácticamente la misma correlación en la evaluación a dic-20
c_optim[3] = 0
c_optim = c_optim / sum(c_optim)

dfweights = DataFrame(
    measure = combine_df.measure[components_mask], 
    weight = c_optim, 
    inflfn = functions[components_mask]
)

# Combinación lineal óptima para valor absoluto de error medio
optcorr2022 = InflationCombination(
    dfweights.inflfn..., infxexc,
    Float32[dfweights.weight..., 0], 
    "Subyacente óptima CORR 2022"
)

# Guardar función de inflación 
wsave(datadir(config_savepath, "optcorr2022", "optcorr2022.jld2"), "optcorr2022", optcorr2022)
optcorr2022 = wload(datadir(config_savepath, "optcorr2022", "optcorr2022.jld2"), "optcorr2022")


## Evaluación de la combinación lineal a dic-20

eval_window = periods_filter
eval_window_hist = (:)

tray_infl_opt = sum(tray_infl[eval_window, components_mask, :] .* c_optim', dims=2)
metrics = eval_metrics(tray_infl_opt, tray_infl_pob[eval_window], prefix = "gt_b10")

tray_infl_opt_hist = sum(tray_infl[eval_window_hist, components_mask, :] .* c_optim', dims=2)
metrics_hist = eval_metrics(tray_infl_opt_hist, tray_infl_pob[eval_window_hist])

combined_results_10 = DataFrame(metrics)
combined_results_10[!, :measure] = [optcorr2022.name]

historic_df = DataFrame(metrics_hist)
historic_df[!, :measure] = [optcorr2022.name]

weights_period_results = [
    df_results[:, [:measure, :gt_b10_corr]]; 
    select(combined_results_10, :measure, :gt_b10_corr)
]

historic_results = [
    df_results[:, [:measure, :corr]]; 
    select(historic_df, :measure, :corr)
]

optcorr_evalresults = innerjoin(historic_results, weights_period_results, on = :measure)
wsave(datadir(config_savepath, "optcorr2022", "optcorr2022_evalresults.jld2"), "optcorr_evalresults", optcorr_evalresults)

## Trayectorias históricas

historic_df = DataFrame(dates = infl_dates(gtdata), 
    optmse2022 = optmse2022(gtdata),
    optabsme2022 = optabsme2022(gtdata), 
    optcorr2022 = optcorr2022(gtdata),
)



println(historic_df)

## Grafica de trayectorias y comparación con óptima MSE 

p1 = plot(InflationTotalCPI(), gtdata)
plot!(optmse2022, gtdata)
plot!(optabsme2022, gtdata)
plot!(optcorr2022, gtdata)

p2 = plot(InflationTotalCPI(), gtdata)
plot!(optcorr2022.ensemble, gtdata, legend=true)

plotly()
plot(p1, p2, layout=(1,2), size=(1200,800))