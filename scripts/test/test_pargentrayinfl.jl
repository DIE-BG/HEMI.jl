# # Prueba para generar trayectorias de inflación de simulación

using DrWatson
@quickactivate "HEMI" 

# Se carga el módulo de `Distributed` para computación paralela
using Distributed

# Se agregan procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI 

# ## Generar trayectorias de inflación 
evaldata = gtdata[Date(2019, 12)]

# Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
inflfn = InflationTotalCPI() 
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk() 

# Se generan trayectorias de inflación interanual, con `K=125,000` trayectorias de inflación 
tray_infl = pargentrayinfl(inflfn, resamplefn, trendfn, evaldata; K = 125_000)

# Se genera independientemente otro lote de `K=125,000` trayectorias para verificar la
# reproducibilidad del muestreo 
tray_infl2 = pargentrayinfl(inflfn, resamplefn, trendfn, evaldata; K = 125_000)

# Verificar que las trayectorias generadas sean las mismas
using Test

@test tray_infl == tray_infl2
@test all(tray_infl .== tray_infl2)


# ## Graficar el promedio de la medida de inflación 
using Plots

# Obtener la trayectoria paramétrica de inflación 
param = ParamTotalCPIRebase() 
param_tray_infl = param(evaldata)

# Obtener la trayectoria promedio de inflación en el muestreo
mean_tray_infl = vec(mean(tray_infl, dims=3))

# Graficar las trayectorias 
plot(infl_dates(evaldata), [mean_tray_infl, param_tray_infl], 
    label = ["Trayectoria promedio" "Trayectoria paramétrica"])
