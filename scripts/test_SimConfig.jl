## 
using DrWatson
# @quickactivate HEMI 
##
# using HEMI


## Obtener un ejemplo 
# Parámetros de simulación
totalfn = InflationTotalCPI()
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()
ff = Date(2020, 12)
sz = 24
# Exclusión Fija
excOpt00 = [35,30,190,36,37,40,31,104,162,32,33,159,193,161]
excOpt10 = [29,31,116,39,46,40,30,35,186,47,197,41,22,48,185,34,184]
fxEx = InflationFixedExclusionCPI(excOpt00, excOpt10)

## Crear una configuración de pruebaa 
configA = SimConfig(totalfn, resamplefn, trendfn, 10000)
configB = CrossEvalConfig(totalfn, resamplefn, trendfn, 1000, ff, sz)
configC = SimConfig(fxEx, resamplefn, trendfn, 10000)
## Mostrar el nombre generado por la configuración 
savename(configA, connector=" | ", equals=" = ")
savename(configB, connector=" | ", equals=" = ")
savename(configC, connector=" | ", equals=" = ")

## Conversión de AbstractConfig a Diccionario

dic_a = convert_dict(configA)
dic_b = convert_dict(configB)
dic_c = convert_dict(configC)

# Función evalsim 
gtdata_eval = gtdata[Date(2020, 12)]

evalsim(gtdata_eval, configA)