using DrWatson
@quickactivate "HEMI"

using HEMI 
using Plots

# Datos hasta dic-19
gtdata_eval = gtdata[Date(2019, 12)]

## Configuración del parámetro de evaluación a dic-19

# Forma manual de configuración del parámetro 
legacy_param = InflationParameter(
    InflationTotalRebaseCPI(36, 2), # Cada 36 meses y hasta 2 cambios de base 
    ResampleScrambleVarMonths(), 
    TrendRandomWalk()
)

# Función de ayuda para construcción automática en InflationEvalTools
legacy_param = ParamTotalCPILegacyRebase()


## Gráfica del parámetro 

tray_infl_param = legacy_param(gtdata_eval)
plot(infl_dates(gtdata_eval), tray_infl_param)
# ylims!(0, 20)


## Realizar evaluación de prueba 

using Distributed
addprocs(4, exeflags="--project")
@everywhere using HEMI

resamplefn = ResampleScrambleVarMonths() 
trendfn = TrendRandomWalk() 

## Evaluación de percentiles con criterios básicos dic-19

dict_percW = Dict(
    :inflfn => InflationPercentileWeighted.(50:52), 
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :nsim => 10_000) |> dict_list

savepath_pw = datadir("results", "PercWeigthed", "scramble")

# El parámetro opcional param_constructor_fn selecciona la función de parámetro
# que se desea utilizar en la evaluación. Hay que pasar la función para
# construir el InflationParameter, en este caso es la de
# ParamTotalCPILegacyRebase
run_batch(gtdata_eval, dict_percW, savepath_pw, 
    param_constructor_fn=ParamTotalCPILegacyRebase, 
    rndseed = 0)

## Evaluación de inflación total con criterios básicos dic-19

config_total = Dict(
    :inflfn => InflationTotalCPI(), 
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :nsim => 125_000) |> dict_list

savepath_total = datadir("results", "TotalCPI", "scramble")

# Hay que pasar la función para construir el InflationParameter, en este caso es
# la de ParamTotalCPILegacyRebase
run_batch(gtdata_eval, config_total, savepath_total, 
    param_constructor_fn=ParamTotalCPILegacyRebase, # esto es nuevo
    rndseed = 314159)



## Ejemplo para revisar función de remuestreo 
t = repeat(1:120, 1, 218)
w = resamplefn(t)

# Acá todos deben estar ordenados de 1 a 12 y cada 12 debe dar 0
w .% 12 

## Evaluación de MSE manual 

tray_infl = pargentrayinfl(InflationTotalCPI(), resamplefn, trendfn, gtdata_eval; K=125_000)
 
m_tray_infl = vec(mean(tray_infl, dims=3))
plot(infl_dates(gtdata_eval), [m_tray_infl tray_infl_param])

mse = mean((tray_infl .- tray_infl_param) .^ 2)
@info "MSE" mse