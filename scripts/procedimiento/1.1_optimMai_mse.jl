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
savepath = datadir("results", "optim", "mse", "CoreMAI")
savepath_best = datadir("results", "optim", "mse")

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
        backend = :BlackBoxOptim,
        maxtime = 7_200,
        init = :uniform
    )
end 

## Cargar resultados de búsqueda de cuantiles 
df = collect_results(savepath)
# select(df, :method, :mse, :n, :K, :q)


## Optimizar con mayor número de simulaciones y puntos iniciales previos

# prelim_methods = @chain df begin 
#     groupby(_, :method)
#     combine(_) do gdf 
#         # Obtener las dos menores métricas de cada tipo de medida 
#         @chain gdf begin 
#             sort(:mse)
#             first(2)
#         end
#     end
#     select(:method, :n, :mse, :q, 
#         :q => ByRow(first), 
#         :q => ByRow(last), 
#     )
# end


# # Optimizar con mayor número de simulaciones 
# K = 10_000
# MAXITER = 300

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
#         maxtime = 3_600
#     )
# end


# Evaluar los mejores métodos utilizando criterios básicos 

# df = collect_results(savepath)
# best_methods = @chain df begin
#     filter(:K => k -> k == K, _) 
#     combine(gdf -> gdf[argmin(gdf.mse), :], groupby(_, :method))
#     select(:method, :n, :mse, :q)
# end

# maifns = map(eachrow(df)) do r
#     method = :($(Symbol(r.method))([0, $(r.q)..., 1.0]))
#     InflationCoreMai(eval(method))
# end

# ┌─────────┬────────┬───────────────────────────────────────────┬──────────┐
# │  method │      n │                                         q │      mse │
# │ String? │ Int64? │                          Vector{Float64}? │ Float64? │
# ├─────────┼────────┼───────────────────────────────────────────┼──────────┤
# │   MaiFP │      4 │            [0.276032, 0.718878, 0.757874] │ 0.277311 │
# │    MaiF │      4 │             [0.382601, 0.667259, 0.82893] │ 0.284195 │
# │    MaiG │      5 │ [0.0588968, 0.271835, 0.742957, 0.771684] │ 0.594854 │
# └─────────┴────────┴───────────────────────────────────────────┴──────────┘
