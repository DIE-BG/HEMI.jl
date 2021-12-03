# # Script de prueba para generar trayectorias de inflación de simulación
using DrWatson
@quickactivate "HEMI" 

# Cargar el módulo de Distributed para computación paralela
using Distributed
addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Cargar datos 

gtdata_eval = gtdata[Date(2019,12)]

# ## Generar trayectorias de inflación 

# Obtener la función de inflación, remuestreo y de tendencia a aplicar
inflfn = InflationTotalCPI() 
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk() 

# Generar trayectorias de inflación interanual 
# tray_infl = pargentrayinfl(inflfn, resamplefn, trendfn, gtdata_eval; K = 10_000)

## Obtener parámetro de evaluación 
param = InflationParameter(
    InflationTotalRebaseCPI(36, 2), 
    resamplefn, 
    trendfn)

tray_infl_param = param(gtdata_eval)

## Evaluar MSE online
# Utilizamos la función `eval_mse_online` con la configuración deseada 
eval_mse_online(inflfn, resamplefn, trendfn, gtdata_eval, tray_infl_param, K=10_000)

## Crear una cerradura con los parámetros

# Podemos crear una cerradura para optimizar sobre los parámetros de la función de inflación: 

function perc_eq_mse(k)
    eval_mse_online(
        InflationPercentileEq(k), # Configurar parámetro variable de la función de inflación  
        resamplefn, trendfn, gtdata_eval, tray_infl_param, K=10_000)
end 

perc_eq_mse(72)