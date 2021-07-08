# # 

using DrWatson 
@quickactivate :HEMI

using InflationFunctions

# Crear una instancia de la función de inflación 

# Ponderado
percfn = InflationPercentileWeighted(70)

version_aw = percfn(gt00)

version_w = percfn(gt00)

version_aw == version_w #true

percfn(gtdata)

# Equiponderado

percEqfn = InflationPercentileEq(72)

percEqfn(gtdata)
