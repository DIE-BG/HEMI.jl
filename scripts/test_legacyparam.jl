using DrWatson
@quickactivate "HEMI"

using HEMI 
using Plots

# Datos hasta dic-19
gtdata_eval = gtdata[Date(2019, 12)]

## Realizar evaluación de prueba 

using Distributed
addprocs(4, exeflags="--project")
@everywhere using HEMI

resamplefn = ResampleScrambleVarMonths() 
trendfn = TrendRandomWalk() 
paramfn = InflationTotalRebaseCPI(36, 2)

## Evaluación de percentiles con criterios básicos dic-19

dict_percW = Dict(
    :inflfn => InflationPercentileWeighted.(69:71), 
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :paramfn => paramfn, # Esta configuración es nueva  
    :nsim => 10_000) |> dict_list

savepath_pw = datadir("results", "PercWeigthed", "scramble")

# El parámetro opcional param_constructor_fn selecciona la función de parámetro
# que se desea utilizar en la evaluación. Hay que pasar la función para
# construir el InflationParameter, en este caso es la de
# ParamTotalCPILegacyRebase
run_batch(gtdata_eval, dict_percW, savepath_pw, savetrajectories=false)



## Evaluación de inflación total con criterios básicos dic-19

config_total = Dict(
    :inflfn => InflationTotalCPI(), 
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :nsim => 125_000) |> dict_list

savepath_total = datadir("results", "TotalCPI", "scramble")

# Hay que pasar la función para construir el InflationParameter, en este caso es
# la de ParamTotalCPILegacyRebase
run_batch(gtdata_eval, config_total, savepath_total; savetrajectories=false) 



## Ejemplo de evaluación de MSE manual 

# Forma manual de configuración del parámetro 
legacy_param = InflationParameter(
    InflationTotalRebaseCPI(36, 2), # Cada 36 meses y hasta 2 cambios de base 
    ResampleScrambleVarMonths(),  # función de remuestreo 
    TrendRandomWalk() # función de tendencia
)

# Computar trayectorias de inflación 
tray_infl = pargentrayinfl(InflationTotalCPI(), resamplefn, trendfn, gtdata_eval; K=125_000)

# Computar la trayectoria paramétrica 
tray_infl_param = legacy_param(gtdata_eval)

# Evaluar el MSE
mse = mean((tray_infl .- tray_infl_param) .^ 2)
@info "MSE" mse


## Gráfica del parámetro 
plot(infl_dates(gtdata_eval), tray_infl_param)

## Gráfica de trayectorias promedio 
m_tray_infl = vec(mean(tray_infl, dims=3))
plot(infl_dates(gtdata_eval), [m_tray_infl tray_infl_param])