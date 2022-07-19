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
savepath = datadir("results", "optim", "corr", "CoreMAI")
savepath_best = datadir("results", "optim", "corr")

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

K = 200
MAXITER = 1000

for config in optconfig
    optimizemai(config, gtdata; 
        K, 
        savepath, 
        maxiterations = MAXITER, 
        metric = :corr,
        backend = :BlackBoxOptim,
        maxtime = 3*3_600,
        init = :uniform
    )
end 

## Cargar resultados de búsqueda de cuantiles 
df = collect_results(savepath)
# select(df, :method, :corr, :n, :K, :q)


## Optimizar con mayor número de simulaciones y puntos iniciales previos

prelim_methods = @chain df begin 
    groupby(_, :method)
    combine(_) do gdf 
        # Obtener las dos menores métricas de cada tipo de medida 
        @chain gdf begin 
            sort(:corr)
            first(2)
        end
    end
    select(:method, :n, :corr, :q, 
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
        backend = :BlackBoxOptim,
        metric = :corr
    )
end


# Evaluar los mejores métodos utilizando criterios básicos 

# df = collect_results(savepath)
best_methods = @chain df begin
    filter(:K => k -> k == K, _) 
    combine(gdf -> gdf[argmin(gdf.corr), :], groupby(_, :method))
    select(:method, :n, :corr, :q)
end

# Obtener funciones de inflación de mejores métodos MAI
bestmaifns = map(eachrow(best_methods)) do r 
    # Obtener método de strings guardados por función optimizemai
    method = :($(Symbol(r.method))([0, $(r.q)..., 1.0]))
    #InflationCoreMai(eval(method))
    eval(method)

end

# # Diccionarios de configuración para evaluación 
# config_mai = merge(genconfig, Dict(:inflfn => bestmaifns)) |> dict_list

# # Ejecutar evaluaciones finales
# run_batch(gtdata, config_mai, savepath_best; savetrajectories=false)

#df = collect_results(savepath_best)

## Revisión de resultados
# @chain df begin 
#     filter(:K => k -> k == 10_000, _)
#     select(:method,:n, :K, :corr, 
#         :q => ByRow(first),
#         :q => ByRow(last)
#     )
# end

# |───────────── best_methods ─────────────|

# ┌─────────┬────────┬───────────┬──────────────────────────────────────────┐
# │  method │      n │      corr │                                        q │
# │ String? │ Int64? │  Float64? │                         Vector{Float64}? │
# ├─────────┼────────┼───────────┼──────────────────────────────────────────┤
# │   MaiFP │      5 │ -0.896492 │ [0.0216123, 0.117179, 0.373563, 0.60367] │
# │    MaiF │      4 │ -0.920613 │            [0.13028, 0.243783, 0.798061] │
# │    MaiG │      5 │ -0.931304 │ [0.298485, 0.349466, 0.521438, 0.676048] │
# └─────────┴────────┴───────────┴──────────────────────────────────────────┘

#InflationCoreMaiFP([0.0, 0.021612318552344485, 0.11717926074998711, 0.3735633911222566, 0.6036701050826221, 1.0])
#InflationCoreMaiF([0.0, 0.13028029096326826, 0.24378253597139465, 0.7980612656474481, 1.0])
#InflationCoreMaiG([0.0, 0.29848511600662586, 0.34946612460586646, 0.521438495546345, 0.676048253095212, 1.0])