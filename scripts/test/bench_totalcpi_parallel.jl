using DrWatson
@quickactivate "HEMI"

## TODO 
# Simulación básica en serie con replicación y benchmark vs MATLAB ✔
# Simulación en paralelo con replicación y benchmark vs MATLAB ✔
# Agregar funciones de inflación adicionales ✔
# ... (mucho más)

## Configuración de procesos
using Distributed
addprocs(4, exeflags="--project")

# # O de esta forma
# @everywhere begin 
#     import Pkg; 
#     Pkg.activate(".")
# end

@everywhere begin 
    using Dates, CPIDataBase
    using InflationFunctions
    using InflationEvalTools
end

# Carga de librerías 
using JLD2

# Carga de datos
@load datadir("guatemala", "gtdata32.jld2") gt00 gt10
gtdata = UniformCountryStructure(gt00, gt10)

# Computar inflación de Guatemala
totalfn = InflationTotalCPI()
perk70 = InflationPercentileEq(0.7)
totalfneval = TotalEvalCPI()

## Benchmark de tiempos en paralelo

# Sin control de progreso
@time tray_infl = pargentrayinfl(totalfn, gtdata; K=10_000, showprogress = false);
# 3.141349 seconds (715.95 k allocations: 30.821 MiB, 0.17% compilation time) -- trend application

# Con control de progreso
@time tray_infl = pargentrayinfl(totalfn, gtdata; K=10_000, showprogress = true);   
# 3.349370 seconds (902.64 k allocations: 41.876 MiB, 0.82% gc time, 2.08% compilation time) -- trend application

# Con 125k trayectorias 
@time tray_infl = pargentrayinfl(totalfn, gtdata; K = 125_000); 
# 32.380233 seconds (9.02 M allocations: 384.435 MiB, 0.18% gc time, 0.21% compilation time) con monitor y replicación por trayectoria
# 43.913071 seconds (8.89 M allocations: 381.204 MiB, 0.21% gc time) -- trend application & monitor

@time tray_infl = pargentrayinfl(totalfn, gtdata; K = 125_000, showprogress = false); 
# 43.154932 seconds (8.89 M allocations: 381.561 MiB, 0.13% gc time, 0.11% compilation time) -- trend application & no monitor


@time tray_infl = pargentrayinfl(perk70, gtdata; K=10_000, showprogress = true);   
# 5.156089 seconds (713.45 k allocations: 30.612 MiB)

@time tray_infl = pargentrayinfl(perk70, gtdata; K = 125_000, showprogress = true); 
# 66.563145 seconds (8.90 M allocations: 381.918 MiB, 0.08% gc time) -- trend application & monitor


## Prueba de replicación

tray_infl1 = pargentrayinfl(totalfn, gtdata; K = 10_000, rndseed = 1618)
tray_infl2 = pargentrayinfl(totalfn, gtdata; K = 10_000, rndseed = 1618)

tray_infl1 == tray_infl2

## Prueba con varias medidas
ensfn = EnsembleFunction(InflationTotalCPI(), InflationPercentileEq(0.5))

@time tray_infl = pargentrayinfl(ensfn, gtdata; K=10_000); 

# 5.743212 seconds (2.27 k allocations: 112.828 KiB) sin monitor de progreso
# 6.518575 seconds (864.69 k allocations: 38.997 MiB, 0.29% gc time, 1.74% compilation time) con monitor