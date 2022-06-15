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

# Parámetros de configuración general del escenario de evaluación 
genconfig = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 2),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :traindate => Date(2019, 12),
    :nsim => 125_000
)

optconfig = merge(genconfig, Dict(
    # Parámetros para búsqueda iterativa de cuantiles 
    :mainseg => [4,5,10],
    :maimethod => [MaiF, MaiG, MaiFP], 
)) |> dict_list

## Optimización de métodos MAI - búsqueda inicial de percentiles 

K = 100
MAXITER = 1000

for config in optconfig
    optimizemai(config, gtdata; 
        K, 
        savepath, 
        maxiterations = MAXITER, 
        backend = :BlackBoxOptim
    )
end 

## Cargar resultados de búsqueda de cuantiles 
df = collect_results(savepath)
# select(df, :method, :mse, :n, :K, :q)


## Optimizar con mayor número de simulaciones y puntos iniciales previos

prelim_methods = @chain df begin 
    groupby(_, :method)
    combine(_) do gdf 
        # Obtener las dos menores métricas de cada tipo de medida 
        @chain gdf begin 
            sort(:mse)
            first(2)
        end
    end
    select(:method, :n, :mse, :q, 
        :q => ByRow(first), 
        :q => ByRow(last), 
    )
end


# Optimizar con mayor número de simulaciones 
K = 10_000
MAXITER = 30

for r in eachrow(prelim_methods)
    # Crear configuración para optimizar 
    config = merge(genconfig, Dict(
        :mainseg => r.n, 
        :maimethod => eval(Symbol(r.method))
    ))

    # Optimizar las metodologías candidatas con vectores iniciales 
    optimizemai(config, gtdata; 
        K, savepath,
        qstart = r.q, # Vector inicial de búsqueda 
        maxiterations = MAXITER,
        backend = :BlackBoxOptim
    )
end


# Evaluar los mejores métodos utilizando criterios básicos 

df = collect_results(savepath)
best_methods = @chain df begin
    filter(:K => k -> k == K, _) 
    combine(gdf -> gdf[argmin(gdf.mse), :], groupby(_, :method))
    select(:method, :n, :mse, :q)
end

# # Obtener funciones de inflación de mejores métodos MAI
# bestmaifns = map(eachrow(best_methods)) do r 
#     # Obtener método de strings guardados por función optimizemai
#     method = :($(Symbol(r.method))([0, $(r.q)..., 1.0]))
#     InflationCoreMai(eval(method))
# end

# # Diccionarios de configuración para evaluación 
# config_mai = merge(genconfig, Dict(:inflfn => bestmaifns)) |> dict_list

# # Ejecutar evaluaciones finales
# run_batch(gtdata, config_mai, savepath_best; savetrajectories=false)

# df = collect_results(savepath_best)

## Revisión de resultados
# @chain df begin 
#     filter(:K => k -> k == 10_000, _)
#     select(:method,:n, :K, :mse, 
#         :q => ByRow(first),
#         :q => ByRow(last)
#     )
# end


# |───────────── best_methods ─────────────|

# ┌─────────┬────────┬──────────┬───────────────────────────────────────────────────────────────────────────────────────────┐
# │  method │      n │      mse │                                                                                         q │
# │ String? │ Int64? │ Float64? │                                                                          Vector{Float64}? │
# ├─────────┼────────┼──────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
# │   MaiFP │     10 │ 0.392814 │ [0.360567, 0.397599, 0.68922, 0.713652, 0.727603, 0.819748, 0.867997, 0.982136, 0.984127] │
# │    MaiF │      5 │  0.29241 │                                                  [0.198645, 0.402978, 0.584704, 0.848164] │
# │    MaiG │     10 │ 0.578146 │ [0.059114, 0.102718, 0.350532, 0.395329, 0.52006, 0.530597, 0.701939, 0.786804, 0.818811] │
# └─────────┴────────┴──────────┴───────────────────────────────────────────────────────────────────────────────────────────┘

# InflationCoreMaiFP([0.360567, 0.397599, 0.68922, 0.713652, 0.727603, 0.819748, 0.867997, 0.982136, 0.984127])
# InflationCoreMaiF([0.198645, 0.402978, 0.584704, 0.848164])
# InflationCoreMaiG([0.059114, 0.102718, 0.350532, 0.395329, 0.52006, 0.530597, 0.701939, 0.786804, 0.818811])