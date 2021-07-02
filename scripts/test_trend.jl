# Script de pruebas para funciones de tendencia 
using DrWatson
@quickactivate :HEMI 

using InflationEvalTools
using Plots

totalfn = InflationTotalCPI() 
resamplefn = ResampleSBB(36)

paramfn = get_param_function(resamplefn)
param_data = paramfn(gtdata)

## Función de tendencia de caminata aleatoria 
trendfn = TrendRandomWalk()

trended_data = trendfn(paramdata)
# plot(infl_dates(trended_data), totalfn(param_data))
plot(infl_dates(trended_data), totalfn(trended_data))

## Función de tendencia analítica 
trendfn = TrendAnalytical(t -> 0.25t)

trended_data = trendfn(gtdata)
plot(infl_dates(trended_data), totalfn(trended_data))