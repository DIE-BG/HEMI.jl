# Script de evaluación de medidas basadas en percentiles equiponderados y
# ponderados de la distribución transversal de variaciones intermensuales de
# índices de precios 
# 
# Escenario D: Evaluación con método de remuestreo de bloques 
# - Datos hasta
#     - dic-19,
#     - dic-20
# - Remuestreo bloques estacionarios
# - Parámetro:
#     - legacy: 2 cambios de base cada 3 años,
#     - cambios de base cada 5 años
# - Tendencia: Random Walk
# - Período completo

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
savepath = datadir("results", "Percentile", "Esc-D", "Optim")
savepath_best = datadir("results", "Percentile", "Esc-D", "BestOptim")

## Funciones de apoyo
includet("perc-optimization.jl")

## Variantes de optimización 

# Diccionario para variantes a optimizar, no representa necesariamente un
# diccionario convertible a SimConfig
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()

# Variantes a optimizar 
variants_dict = dict_list(Dict(
    :infltypefn => [InflationPercentileEq, InflationPercentileWeighted],
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :paramfn => [InflationTotalRebaseCPI(36, 2), InflationTotalRebaseCPI(60)],
    :nsim => 125_000,
    :traindate => [Date(2019, 12), Date(2020, 12)]))

config = variants_dict[1]

## Optimización de percentiles 

MAXITER = 50
for config in variants_dict
    # Optimizar el percentil con parametros en config 
    optimizeperc(config, gtdata; 
        savepath, 
        maxiterations = MAXITER)
end


# Cargar los percentiles óptimos para realizar la evaluación completa 
optim_results = collect_results(savepath)

# Obtener la función de inflación con el percentil óptimo 
optim_results = transform!(optim_results, 
    [:infltypefn, :k] => ByRow((method, k) -> method(k)) => :inflfn)

# Convertir las configuraciones a diccionario de variantes para run_batch
evalconfigs = tosymboldict.(eachrow(optim_results))

# Evaluar percentiles óptimos de cada variante 
run_batch(gtdata, evalconfigs, savepath_best, savetrajectories=true)



nothing 

## 
#=
# CountryStructure con datos hasta diciembre de 2020
# EVALDATE = Date(2019, 12)
# gtdata_eval = gtdata[EVALDATE]

## Percentiles ponderados

measure = "PercentileWeighted"
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()

# Configuración para evaluación de percentiles ponderados y equiponderados 
dict_percW = Dict(
    :inflfn => vcat(InflationPercentileWeighted.(60:80), InflationPercentileEq.(60:80))
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :paramfn => [InflationTotalRebaseCPI(36, 2), InflationTotalRebaseCPI(60)],
    :nsim => 125_000,
    :traindate => [Date(2019, 12), Date(2020, 12)]) |> dict_list 

# Directorios para almacenar los resultados 
savepath_pw = datadir("results", measure, "EscD", Esc)
savepath_plot_pw = joinpath("docs", "src", "eval", "EscD", "images", measure)

run_batch(gtdata_eval, dict_percW, savepath_pw)
=#