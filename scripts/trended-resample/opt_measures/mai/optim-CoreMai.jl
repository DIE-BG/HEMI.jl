# # Script de evaluación de variantes de inflación subyacente MAI
using DrWatson
@quickactivate "HEMI"

using HEMI 
using Optim 
using BlackBoxOptim
using CSV, DataFrames, Chain 

# Directorios de resultados 
savepath = datadir("results", "trended-resample", "CoreMai", "Optim")
savepath_best = datadir("results", "trended-resample", "CoreMai", "BestOptim")

## Cargar el módulo de Distributed para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI

## Funciones de apoyo para optimización iterativa de cuantiles 
includet(scriptsdir("OPTIM", "mai-optim-functions.jl"))

## Configuración para simulaciones

# Parámetros de configuración general del escenario de evaluación 
genconfig = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 2),
    :resamplefn => ResampleScrambleTrended(0.46031723899305166),
    :trendfn => TrendIdentity(),
    :traindate => Date(2018, 12),
    :nsim => 125_000
)

optconfig = merge(genconfig, Dict(
    # Parámetros para búsqueda iterativa de cuantiles 
    :mainseg => [3,4,5,10],
    :maimethod => [MaiF, MaiG, MaiFP], 
)) |> dict_list

## Optimización de métodos MAI - búsqueda inicial de percentiles 

K = 100
MAXITER = 1000
MAXTIME = 5*60

for config in optconfig
    optimizemai(config, GTDATA; K, savepath, 
        maxiterations = MAXITER,
        maxtime = MAXTIME, 
        init = :random,
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
MAXTIME = 20*60

for r in eachrow(prelim_methods)
    # Crear configuración para optimizar 
    config = merge(genconfig, Dict(
        :mainseg => r.n, 
        :maimethod => eval(Symbol(r.method))
    ))

    # Optimizar las metodologías candidatas con vectores iniciales 
    optimizemai(config, GTDATA; 
        K, savepath,
        qstart = r.q, # Vector inicial de búsqueda 
        maxiterations = MAXITER, 
        maxtime = MAXTIME, 
        backend = :Optim, 
    )
end


# Evaluar los mejores métodos utilizando criterios básicos 

df = collect_results(savepath)
best_methods = @chain df begin
    filter(:K => k -> k == K, _) 
    combine(gdf -> gdf[argmin(gdf.mse), :], groupby(_, :method))
    select(:method, :n, :mse, :q)
end

# Obtener funciones de inflación de mejores métodos MAI
bestmaifns = map(eachrow(best_methods)) do r 
    # Obtener método de strings guardados por función optimizemai
    method = :($(Symbol(r.method))([0, $(r.q)..., 1.0]))
    InflationCoreMai(eval(method))
end

# Diccionarios de configuración para evaluación 
config_mai = merge(genconfig, Dict(:inflfn => bestmaifns)) |> dict_list

# Ejecutar evaluaciones finales
run_batch(gtdata, config_mai, savepath_best, savetrajectories=true)
 

## Revisión de resultados
@chain df begin 
    filter(:K => k -> k == 10_000, _)
    select(:method,:n, :K, :mse, 
        :q => ByRow(first),
        :q => ByRow(last)
    )
end