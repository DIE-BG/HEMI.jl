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
config_savepath = datadir("results", "trended-resample", "exercise-optmse2022")
tray_dir = joinpath(config_savepath, "tray_infl")
plots_savepath = mkpath(plotsdir("trended-resample", "mse-combination"))

# CountryStructure con datos hasta período de evaluación 
FINAL_DATE = Date(2020, 12)
gtdata_eval = GTDATA[FINAL_DATE]

# Medidas que componen las óptima mse 2022
include(scriptsdir("mse-combination", "optmse2022.jl"))

##  ----------------------------------------------------------------------------
#   Configuración de simulación para generación de trayectorias
#   ----------------------------------------------------------------------------

## Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
resamplefn = ResampleScrambleTrended(0.5050245)
trendfn = TrendIdentity() 
paramfn = InflationTotalRebaseCPI(36, 2)

##  ----------------------------------------------------------------------------
#   Generación de datos de simulación 
#   ----------------------------------------------------------------------------

config_ex_optmse2022 = Dict(
    :inflfn => [optmse2022.ensemble.functions...], 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => FINAL_DATE,
    :nsim => 10_000) |> dict_list

run_batch(GTDATA, config_ex_optmse2022, config_savepath)

## Combinación óptima 
df_results = collect_results(config_savepath)

@chain df_results begin 
    select(:measure, :mse, :me)
end

# DataFrame de combinación 
combine_df = @chain df_results begin 
    select(:measure, :mse, :me, :inflfn, 
        :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path)
    sort(:mse)
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
combine_period = EvalPeriod(Date(2011, 12), FINAL_DATE, "combperiod") 
periods_filter = eval_periods(gtdata_eval, combine_period)

# Combinación de estimadores para minimizar el mse
a_optim = share_combination_weights(tray_infl[periods_filter, components_mask, :], tray_infl_pob[periods_filter],
    show_status = true
)

dfweights = DataFrame(
    measure = combine_df.measure[components_mask], 
    weight = a_optim, 
    inflfn = functions[components_mask]
)

# Combinación lineal óptima para valor absoluto de error medio
ex_optmse2022 = InflationCombination(
    dfweights.inflfn..., functions[.!components_mask]...,
    Float32[dfweights.weight..., 0], 
    "Subyacente óptima MSE 2022 (ejercicio)"
)

# Guardar función de inflación 
wsave(datadir(config_savepath, "ex_optmse2022", "ex_optmse2022.jld2"), "ex_optmse2022", ex_optmse2022)
ex_optmse2022 = wload(datadir(config_savepath, "ex_optmse2022", "ex_optmse2022.jld2"), "ex_optmse2022")


## Evaluación de la combinación lineal a dic-20

a_optim = ex_optmse2022.weights[1:end-1]

eval_window = periods_filter
tray_infl_opt = sum(tray_infl[eval_window, components_mask, :] .* a_optim', dims=2)
metrics = eval_metrics(tray_infl_opt, tray_infl_pob[eval_window])
combined_results_10 = DataFrame(metrics)
combined_results_10[!, :measure] = [ex_optmse2022.name]
combined_results_10

eval_window = (:)
tray_infl_opt = sum(tray_infl[eval_window, components_mask, :] .* a_optim', dims=2)
metrics = eval_metrics(tray_infl_opt, tray_infl_pob[eval_window])
historic_df = DataFrame(metrics)
historic_df[!, :measure] = [ex_optmse2022.name]
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
@info "Resultados de evaluación" optmse_evalresults
wsave(datadir(config_savepath, "ex_optmse2022", "ex_optmse2022_evalresults.jld2"), "optmse_evalresults", optmse_evalresults)

## Trayectorias históricas

historic_df = DataFrame(dates = infl_dates(GTDATA), 
    optmse2022 = optmse2022(GTDATA),
    ex_optmse2022 = ex_optmse2022(GTDATA)
)
println(historic_df)

## Grafica de trayectorias y comparación con óptima MSE 

dates = Date(2002):Year(1):Date(2022)
dateticks = Dates.format.(dates, dateformat"yyyy")
p1 = plot(InflationTotalCPI(), GTDATA, 
    xticks=(dates,dateticks), 
    xrotation=45)
plot!(ex_optmse2022, GTDATA)
plot!(optmse2022, GTDATA)

p2 = plot(InflationTotalCPI(), GTDATA,
    xticks=(dates,dateticks), 
    xrotation=45)
plot!(ex_optmse2022.ensemble, GTDATA)

plot(p1, size=(800,600))
savefig(joinpath(plots_savepath, "comp_optmse2022.png"))
plot(p2, size=(800,600))
savefig(joinpath(plots_savepath, "comp_optmse2022_components.png"))

plot(p1, p2, size=(800, 600), layout=(2,1))
savefig(joinpath(plots_savepath, "comp_optmse2022_both.png"))