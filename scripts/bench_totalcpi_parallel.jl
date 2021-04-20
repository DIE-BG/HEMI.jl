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
@time tray_infl = pargentrayinfl(totalfn, gtdata; K=10_000);

# Con control de progreso
@time tray_infl = pargentrayinfl(totalfn, gtdata; K=10_000)  

# Con 125k trayectorias 
@time tray_infl = pargentrayinfl(totalfn, gtdata; K = 125_000); 
# 54.914161 seconds (8.89 M allocations: 381.423 MiB, 0.12% gc time) con monitor de progreso
# 44.023948 seconds (21.67 k allocations: 1.224 MiB, 0.04% compilation time) sin monitor de progreso
# 32.380233 seconds (9.02 M allocations: 384.435 MiB, 0.18% gc time, 0.21% compilation time) con monitor y replicación por trayectoria

## Prueba de replicación

tray_infl1 = pargentrayinfl(totalfn, gtdata; K = 10_000, rndseed = 1618)
tray_infl2 = pargentrayinfl(totalfn, gtdata; K = 10_000, rndseed = 1618)

tray_infl1 == tray_infl2

## Prueba con varias medidas
ensfn = EnsembleFunction(TotalCPI(), Percentil(0.5))

@time tray_infl = pargentrayinfl(ensfn, gtdata; K=10_000); 

# 5.743212 seconds (2.27 k allocations: 112.828 KiB) sin monitor de progreso
# 6.518575 seconds (864.69 k allocations: 38.997 MiB, 0.29% gc time, 1.74% compilation time) con monitor