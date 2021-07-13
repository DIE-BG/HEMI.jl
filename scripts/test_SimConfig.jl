## 
using DrWatson
@quickactivate HEMI 
##
using HEMI


## Obtener un ejemplo 
# Parámetros de simulación
totalfn = InflationTotalCPI()
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()
ff = Date(2020, 12)
sz = 24

## Crear una configuración de pruebaa 
config = SimConfig(totalfn, resamplefn, trendfn, 10000)
configB = CrossEvalConfig(totalfn, resamplefn, trendfn, 1000, ff, sz)

## Mostrar el nombre generado por la configuración 
savename(config, connector=" | ", equals=" = ")
savename(configB, connector=" | ", equals=" = ")