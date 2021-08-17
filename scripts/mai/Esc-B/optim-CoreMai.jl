# # Script de evaluación de variantes de inflación subyacente MAI
using DrWatson
@quickactivate "HEMI"

using HEMI 
using Optim 
using CSV, DataFrames, Chain 

## Datos de evaluación 
const EVALDATE = Date(2020,12)
gtdata_eval = gtdata[EVALDATE]

# Directorios de resultados 
savepath = datadir("results", "CoreMai", "Esc-B", "Optim")
savepath_best = datadir("results", "CoreMai", "Esc-B", "bestOptim")

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

## Funciones de apoyo para optimización iterativa de cuantiles 
includet(scriptsdir("mai", "mai-optimization.jl"))

## Configuración para simulaciones
# Funciones de remuestreo y tendencia
paramfn = InflationTotalRebaseCPI(36, 2)
resamplefn = ResampleScrambleVarMonths() 
trendfn = TrendRandomWalk()

## Trayectoria paramétrica
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_param = param(gtdata_eval)


## Optimización de métodos MAI - búsqueda inicial de percentiles 

K = 100
MAXITER = 1000

methods = [MaiF, MaiG, MaiFP]
segments = [3,4,5,10]

for method in methods, n in segments
    optimizemai(n, method, resamplefn, trendfn, gtdata_eval, tray_infl_param; 
        K, savepath, 
        maxiterations = MAXITER)
end 

## Cargar resultados de búsqueda de cuantiles 
df = collect_results(savepath)
select(df, :method, :mse, :n, :K, :q)

# @chain df begin 
#     select(:method, :mse, :n, :K, :q)
#     sort(:mse)
#     vscodedisplay
# end 

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
    select(:method, :n, :mse, :q)
end


# Optimizar con mayor número de simulaciones 
K = 10_000
MAXITER = 25

for r in eachrow(prelim_methods)
    # Obtener método de strings guardados por función optimizemai
    method = :($(Symbol(r.method))([0, $(r.q)..., 1.0]))
    inflfn = InflationCoreMai(eval(method))

    # Optimizar las metodologías candidatas con vectores iniciales 
    optimizemai(r.n, eval(Symbol(r.method)), resamplefn, trendfn, gtdata_eval, tray_infl_param; 
        K, savepath,
        qstart = r.q, # Vector inicial de búsqueda 
        maxiterations = MAXITER)
end

## Obtener los mejores métodos de cada tipo 
df = collect_results(savepath)
best_methods = @chain df begin
    filter(:K => k -> k == K, _) 
    combine(gdf -> gdf[argmin(gdf.mse), :], groupby(_, :method))
    select(:method, :n, :mse, :q)
end

## Evaluar los mejores métodos uitlizando criterios básicos 

bestmaifns = map(eachrow(best_methods)) do r 
    # Obtener método de strings guardados por función optimizemai
    method = :($(Symbol(r.method))([0, $(r.q)..., 1.0]))
    InflationCoreMai(eval(method))
end

config_mai = Dict(
    :inflfn => bestmaifns, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => EVALDATE,
    :nsim => 125000) |> dict_list

run_batch(gtdata, config_mai, savepath_best, savetrajectories=true)
