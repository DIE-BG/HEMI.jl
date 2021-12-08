# Script de evaluación de medidas basadas en percentiles equiponderados y
# ponderados de la distribución transversal de variaciones intermensuales de
# índices de precios para correlación 

using DrWatson
@quickactivate "HEMI"

using DataFrames, Chain, PrettyTables
using Optim 
using Plots

## Cargar el módulo de Distributed para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI

## Directorios de resultados
savepath = datadir("results", "Percentile", "Esc-F", "Optim")
savepath_best = datadir("results", "Percentile", "Esc-F", "BestOptim")
savepath_plots = mkpath(plotsdir("Percentile", "Esc-F"))

## Funciones de apoyo
includet(scriptsdir("percentile", "perc-optimization.jl"))

## Opciones para optimización 
metric = :corr
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()

# Variantes a optimizar 
variants_dict = dict_list(Dict(
    :infltypefn => [InflationPercentileEq, InflationPercentileWeighted],
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :paramfn => InflationTotalRebaseCPI(36, 2),
    :nsim => 10_000,
    :traindate => Date(2018, 12)))


## Optimización de percentiles 

MAXITER = 10
for config in variants_dict
    # Optimizar el percentil con parametros en config 
    optimizeperc(config, gtdata; 
        savepath, 
        maxiterations = MAXITER, 
        metric)
end


## Cargar los percentiles óptimos para realizar la evaluación completa 
optim_results = collect_results(savepath)

# Obtener la función de inflación con el percentil óptimo 
optim_results = transform!(optim_results, 
    [:infltypefn, :k] => ByRow((method, k) -> method(k)) => :inflfn)

# Convertir las configuraciones a diccionario de variantes para run_batch
evalconfigs = tosymboldict.(eachrow(optim_results))

# Evaluar percentiles óptimos de cada variante 
run_batch(gtdata, evalconfigs, savepath_best, savetrajectories=true)


## Documentación de resultados

results = @chain collect_results(savepath_best) begin 
    transform(:paramfn => ByRow(fn -> fn.period) => :paramperiod)
end


## Compilación de resultados con parámetro con periodicidad de cambio de base 
# PARAM_PERIOD y fecha final de simulación EVALDATE
PARAM_PERIOD = 36
EVALDATE = Date(2018,12)

# Agregar :nseg y :maitype para filtrar y ordenar resultados 
scenario_results = @chain results begin 
    filter([:traindate, :paramperiod] => (d, p) -> d == EVALDATE && p == PARAM_PERIOD, _)
end

# Tabla de resultados principales del escenario 
main_results = @chain scenario_results begin 
    select(:measure, :mse, :mse_std_error)
end

# Descomposición aditiva del MSE 
mse_decomp = @chain scenario_results begin 
    select(:measure, :mse, r"^mse_[bvc]")
    select(:measure, :mse, :mse_bias, :mse_var, :mse_cov)
end

# Otras métricas de evaluación 
sens_metrics = @chain scenario_results begin 
    select(:measure, :rmse, :me, :mae, :huber, :corr)
end 


pretty_table(main_results, tf=tf_markdown, formatters=ft_round(4))
pretty_table(mse_decomp, tf=tf_markdown, formatters=ft_round(4))
pretty_table(sens_metrics, tf=tf_markdown, formatters=ft_round(4))


# Gráficas de percentiles óptimos 
inflfns = scenario_results.inflfn
plot(InflationTotalCPI(), gtdata)
plot!(inflfns[1], gtdata)
plot!(inflfns[2], gtdata)

savefig(joinpath(savepath_plots, savename("Optim-Percentile", (@dict EVALDATE PARAM_PERIOD), "svg")))
