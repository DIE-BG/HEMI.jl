# # Script de pruebas para funciones de tendencia 
using DrWatson
@quickactivate :HEMI 

using InflationFunctions
using InflationEvalTools
using Plots

# Esta función se utiliza para generar la trayectoria paramétrica de inflación: 
totalfn = InflationTotalRebaseCPI()

# Se genera una función de remuestreo para obtener los datos paramétricos y generar así la trayectoria de inflación paramétrica 
resamplefn = ResampleSBB(36)
paramfn = get_param_function(resamplefn)
param_data = paramfn(gtdata)

# Veamos una gráfica de la trayectoria paramétrica sin aplicación de tendencia:
plot(infl_dates(param_data), totalfn(param_data))


# ## Función de tendencia de caminata aleatoria 
# Para utilizar la función de tendencia de caminata aleatoria, debemos generar
# una instancia de la funcióni `TrendRandomWalk`: 
trendfn = TrendRandomWalk()

# Posteriormente, esta instancia es llamable sobre objetos de tipo
# `CountryStructure`, por lo que, para aplicar la función de tendencia hacemos: 
trended_data = trendfn(param_data)
# Veamos una gráfica de la trayectoria paramétrica utilizando la tendencia de
# caminata aleatoria: 
plot(infl_dates(trended_data), totalfn(trended_data))


# ## Función de tendencia analítica 
trendfn = TrendAnalytical(param_data, t -> 1 + sin(2π*t/12))
trendfn = TrendAnalytical(1:periods(param_data), t -> 1 + sin(2π*t/12))

trended_data = trendfn(param_data)
plot(infl_dates(trended_data), totalfn(trended_data))


# ## Función de tendencia que no aplica tendencia 

trendfn = TrendNoTrend() 

trended_data = trendfn(param_data)
plot(infl_dates(trended_data), totalfn(trended_data))
