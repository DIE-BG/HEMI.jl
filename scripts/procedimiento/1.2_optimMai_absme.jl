using DrWatson
@quickactivate "HEMI"

include(scriptsdir("OPTIM","optim.jl"))
include(scriptsdir("OPTIM","mai-optim-functions.jl"))


# # Script de evaluación de variantes de inflación subyacente MAI
using DrWatson
@quickactivate "HEMI"

using HEMI 
using Optim 
using CSV, DataFrames, Chain 

# Directorios de resultados 
savepath = datadir("results", "optim", "absme", "CoreMAI")
savepath_best = datadir("results", "optim", "absme")

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI


## Configuración para simulaciones

optconfig = merge(genconfig, Dict(
    # Parámetros para búsqueda iterativa de cuantiles 
    :mainseg => [4,5,6],
    :maimethod => [MaiF, MaiG, MaiFP], 
)) |> dict_list

## Optimización de métodos MAI - búsqueda inicial de percentiles 

K = 200
MAXITER = 1000

for config in optconfig
    optimizemai(config, gtdata; 
        K, 
        savepath, 
        maxiterations = MAXITER, 
        metric = :me,
        backend = :BlackBoxOptim,
        maxtime = 3*3_600,
        init = :uniform
    )
end 

## Cargar resultados de búsqueda de cuantiles 
df = collect_results(savepath)
# select(df, :method, :me, :n, :K, :q)


## Optimizar con mayor número de simulaciones y puntos iniciales previos

# prelim_methods = @chain df begin 
#     groupby(_, :method)
#     combine(_) do gdf 
#         # Obtener las dos menores métricas de cada tipo de medida 
#         @chain gdf begin 
#             sort(:me)
#             first(2)
#         end
#     end
#     select(:method, :n, :me, :q, 
#         :q => ByRow(first), 
#         :q => ByRow(last), 
#     )
# end


# # Optimizar con mayor número de simulaciones 
# K = 10_000
# MAXITER = 30

# for r in eachrow(prelim_methods)
#     # Crear configuración para optimizar 
#     config = merge(genconfig, Dict(
#         :mainseg => r.n, 
#         :maimethod => eval(Symbol(r.method))
#     ))

#     # Optimizar las metodologías candidatas con vectores iniciales 
#     optimizemai(config, gtdata; 
#         K, savepath,
#         qstart = r.q, # Vector inicial de búsqueda 
#         maxiterations = MAXITER,
#         backend = :BlackBoxOptim,
#         metric = :me
#     )
# end


# # Evaluar los mejores métodos utilizando criterios básicos 

# df = collect_results(savepath)
# best_methods = @chain df begin
#     filter(:K => k -> k == K, _) 
#     combine(gdf -> gdf[argmin(gdf.me), :], groupby(_, :method))
#     select(:method, :n, :me, :q)
# end

# # Obtener funciones de inflación de mejores métodos MAI
# bestmaifns = map(eachrow(best_methods)) do r 
#     # Obtener método de strings guardados por función optimizemai
#     method = :($(Symbol(r.method))([0, $(r.q)..., 1.0]))
#     InflationCoreMai(eval(method))
# end

# # Diccionarios de configuración para evaluación 
# config_mai = merge(genconfig, Dict(:inflfn => bestmaifns)) |> dict_list

# # Ejecutar evaluaciones finales
# run_batch(gtdata, config_mai, savepath_best, savetrajectories=true)

# df = collect_results(savepath_best)

## Revisión de resultados
# @chain df begin 
#     filter(:K => k -> k == 10_000, _)
#     select(:method,:n, :K, :me, 
#         :q => ByRow(first),
#         :q => ByRow(last)
#     )
# end

# |───────────── best_methods ─────────────|

# ┌─────────┬────────┬───────────┬─────────────────────────────────────────────────────────────────────────────────────────────┐
# │  method │      n │        me │                                                                                           q │
# │ String? │ Int64? │  Float64? │                                                                            Vector{Float64}? │
# ├─────────┼────────┼───────────┼─────────────────────────────────────────────────────────────────────────────────────────────┤
# │   MaiFP │     10 │ -0.759592 │  [0.0584298, 0.0954737, 0.245661, 0.291486, 0.33868, 0.478096, 0.846356, 0.97829, 0.999177] │
# │    MaiF │     10 │ -0.199985 │  [0.0958119, 0.155845, 0.485898, 0.719933, 0.795759, 0.869557, 0.898225, 0.99026, 0.990358] │
# │    MaiG │     10 │ -0.858168 │ [0.00474738, 0.23966, 0.253779, 0.339322, 0.443259, 0.476159, 0.499084, 0.736747, 0.999839] │
# └─────────┴────────┴───────────┴─────────────────────────────────────────────────────────────────────────────────────────────┘

# InflationCoreMaiFP([0.0584298, 0.0954737, 0.245661, 0.291486, 0.33868, 0.478096, 0.846356, 0.97829, 0.999177])
# InflationCoreMaiF([0.0958119, 0.155845, 0.485898, 0.719933, 0.795759, 0.869557, 0.898225, 0.99026, 0.990358])
# InflationCoreMaiG([0.00474738, 0.23966, 0.253779, 0.339322, 0.443259, 0.476159, 0.499084, 0.736747, 0.999839])