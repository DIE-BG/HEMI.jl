# Script de pruebas para funciones de tendencia 
using DrWatson
@quickactivate :HEMI 

using InflationEvalTools
using Plots

totalfn = InflationTotalCPI() 
resamplefn = ResampleSBB(36)

paramfn = get_param_function(resamplefn)
param_data = paramfn(gtdata)

# Gráfica original sin aplicación de tendencia
plot(infl_dates(param_data), totalfn(param_data))


## Función de tendencia de caminata aleatoria 
trendfn = TrendRandomWalk()

trended_data = trendfn(param_data)
plot(infl_dates(trended_data), totalfn(trended_data))


## Función de tendencia analítica 
trendfn = TrendAnalytical(param_data, t -> 1 + sin(2π*t/12))
trendfn = TrendAnalytical(1:periods(param_data), t -> 1 + sin(2π*t/12))

trended_data = trendfn(param_data)
plot(infl_dates(trended_data), totalfn(trended_data))


## Función de tendencia que no aplica tendencia 

trendfn = TrendNoTrend() 

trended_data = trendfn(param_data)
plot(infl_dates(trended_data), totalfn(trended_data))
