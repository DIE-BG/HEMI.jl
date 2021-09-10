# # Pruebas de funciones de percentiles ponderados y equiponderados

using DrWatson 
@quickactivate :HEMI

# Cargar las funciones de inflación 
using InflationFunctions

# ## Equiponderado

# Crear una instancia de la función de inflación 
# para el percentil 72 de la distribución de variaciones 
# intermensuales de precios equiponderdas

percEqfn = InflationPercentileEq(72)

# Posteriormente, esta instancia es llamable sobre objetos de tipo
# `CountryStructure`, por lo que, se aplica la función de la siguiente manera: 

percEqfn(gtdata)

# Finalmente se obtiene la trayectoria de inflación interanual dada por el percententil equiponderado 72 de las variaciones intermensuales del IPC. 

# ## Ponderado

# Crear una instancia de la función de inflación 
# para el percentil 70 de la distribución de variaciones 
# intermensuales de precios ponderadas por su peso en el IPC

percfn = InflationPercentileWeighted(70)

# Esta función de inflación utiliza la función de StatsBase `aweights(base.w)` para especificar que se tratan pesos del tipo `AnalyticWeights`.

# Posteriormente, esta instancia es llamable sobre objetos de tipo
# `CountryStructure`, por lo que, se aplica la función de la siguiente manera:

percfn(gtdata)

# Finalmente se obtiene la trayectoria de inflación interanual dada por el percententil ponderado 70 de las variaciones intermensuales del IPC. 
