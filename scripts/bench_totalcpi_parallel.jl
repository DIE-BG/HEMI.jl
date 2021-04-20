using DrWatson
@quickactivate "HEMI"

## TODO 
# Simulación básica en serie con replicación y benchmark vs MATLAB ✔
# Simulación en paralelo con replicación y benchmark vs MATLAB ✔
# Agregar funciones de inflación adicionales ✔
# ... (mucho más)

## Configuración de procesos
using Distributed
addprocs(4)

@everywhere begin 
    import Pkg; 
    Pkg.activate(".")
end

@everywhere begin 
    using Dates, CPIDataBase
    using InflationFunctions
    using InflationEvalTools
end

# Carga de librerías 
using JLD2

# Carga de datos
@load datadir("guatemala", "gtdata32.jld2") gt00 gt10
const gtdata = UniformCountryStructure(gt00, gt10)

# Computar inflación de Guatemala
const totalfn = TotalCPI()
const perk70 = Percentil(0.7)
const totalfneval = TotalEvalCPI()

## Benchmark de tiempos en paralelo

# Sin control de progreso
@time tray_infl = pargentrayinfl(totalfneval, gtdata; K=10_000)  
# 3.543101 seconds (227.32 k allocations: 13.874 MiB, 0.33% gc time, 2.63% compilation time)

# Con control de progreso
@time tray_infl = pargentrayinfl(totalfn, gtdata; K=10_000)  
# Progress: 100%|██████████████████████████| Time: 0:00:04
#   4.217471 seconds (717.27 k allocations: 30.780 MiB, 0.10% compilation time)

# Tiempo en serie 
# @time tray_infl = gentrayinfl(totalfn, gtdata; K=10_000)  
# Progress: 100%|██████████████████████████| Time: 0:00:10
#  10.099791 seconds (399.15 k allocations: 4.574 GiB, 1.41% gc time, 0.06% compilation time)

# Con 125k trayectorias 
@time tray_infl = pargentrayinfl(totalfn, gtdata; K = 125_000); 
# 54.914161 seconds (8.89 M allocations: 381.423 MiB, 0.12% gc time) con monitor de progreso
# 44.023948 seconds (21.67 k allocations: 1.224 MiB, 0.04% compilation time) sin monitor de progreso

## Prueba de replicación

tray_infl1 = pargentrayinfl(totalfn, gtdata; K = 10_000, rndseed = 1618)
tray_infl2 = pargentrayinfl(totalfn, gtdata; K = 10_000, rndseed = 1618)

tray_infl1 == tray_infl2

# # Prueba con otra forma de replicación
# @time tray_infl1 = pargentrayinfl_seed(totalfn, gtdata; K = 10_000, rndseed = 1618)
# # 4.083454 seconds (722.34 k allocations: 30.604 MiB, 0.24% gc time)
# @time tray_infl2 = pargentrayinfl_seed(totalfn, gtdata; K = 10_000, rndseed = 1618)
# # 4.226844 seconds (722.41 k allocations: 30.605 MiB, 0.23% gc time)
# tray_infl1 == tray_infl2


## Prueba con varias medidas
ensfn = EnsembleFunction(TotalCPI(), Percentil(0.5))

@time tray_infl = pargentrayinfl(ensfn, gtdata; K=10_000); 

# 5.743212 seconds (2.27 k allocations: 112.828 KiB) sin monitor de progreso
# 6.518575 seconds (864.69 k allocations: 38.997 MiB, 0.29% gc time, 1.74% compilation time) con monitor