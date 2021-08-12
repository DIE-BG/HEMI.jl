# # Script de evaluación de variantes de inflación subyacente MAI
using DrWatson
@quickactivate "HEMI"

using HEMI 
using Optim 
using CSV, DataFrames, Chain 

## Datos de evaluación 
const EVALDATE = Date(2019,12)
gtdata_eval = gtdata[EVALDATE]

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


## Generar optimización de variantes 

savepath = datadir("results", "CoreMai", "Esc-A", "Optim")
K = 10_000
MAXITER = 50

## Optimización de métodos MAI - búsqueda inicial de percentiles 

# Optimización de métodos MAI-F
optimizemai(3, MaiF, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath, 
    maxiterations = MAXITER)
optimizemai(4, MaiF, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath, 
    maxiterations = MAXITER)
optimizemai(5, MaiF, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath, 
    maxiterations = MAXITER)
optimizemai(10, MaiF, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath, 
    maxiterations = MAXITER)

# Optimización de métodos MAI-G
optimizemai(3, MaiG, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath, 
    maxiterations = MAXITER)
optimizemai(4, MaiG, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath, 
    maxiterations = MAXITER)
optimizemai(5, MaiG, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath, 
    maxiterations = MAXITER)
optimizemai(10, MaiG, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath, 
    maxiterations = MAXITER)

# Optimización de métodos MAI-FP
optimizemai(3, MaiFP, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath, 
    maxiterations = MAXITER)
optimizemai(4, MaiFP, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath, 
    maxiterations = MAXITER)
optimizemai(5, MaiFP, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath, 
    maxiterations = MAXITER)
optimizemai(10, MaiFP, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath, 
    maxiterations = MAXITER)


## Cargar resultados de búsqueda de cuantiles 
df = collect_results(savepath)
select(df, :method, :mse, :n, :K, :q)

# Obtener los mejores métodos de cada tipo 
best_methods = @chain df begin 
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

savepath_best = datadir("results", "CoreMai", "Esc-A", "bestOptim")
run_batch(gtdata, config_mai, savepath_best, savetrajectories=true)