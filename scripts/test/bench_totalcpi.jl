using DrWatson
@quickactivate "HEMI"

## TODO 
# Simulación básica en serie con replicación y benchmark vs MATLAB ✔
# Simulación en paralelo con replicación y benchmark vs MATLAB ✔
# Agregar funciones de inflación adicionales
# ... (mucho más)

using Dates, CPIDataBase
using InflationFunctions
using InflationEvalTools
using JLD2

# Carga de datos
@load datadir("guatemala", "gtdata32.jld2") gt00 gt10
gtdata = UniformCountryStructure(gt00, gt10)

# Computar inflación de Guatemala
totalfn = InflationTotalCPI()
perk70 = InflationPercentileEq(0.7)

## Benchmark de tiempos

@time tray_infl = gentrayinfl(totalfn, gtdata; K=10_000);   
# Progress: 100%|██████████████████████████| Time: 0:00:10
#  10.099791 seconds (399.15 k allocations: 4.574 GiB, 1.41% gc time, 0.06% compilation time)
# 10.426991 seconds (335.09 k allocations: 4.574 GiB, 2.44% gc time) type-inference fixed
# 13.854796 seconds (426.75 k allocations: 6.830 GiB, 3.20% gc time) -- trend application

@time tray_infl = gentrayinfl(totalfn, gtdata; K = 125_000); 
# julia> @time tray_infl = gentrayinfl(totalfn, gtdata; K = 125000) 
# 136.687623 seconds (4.87 M allocations: 57.170 GiB, 2.85% gc time)
# 130.347705 seconds (4.19 M allocations: 57.171 GiB, 2.33% gc time) type-inference fixed
# 171.984045 seconds (5.34 M allocations: 85.379 GiB, 3.03% gc time, 0.00% compilation time) -- trend application

## 
@time tray_infl = gentrayinfl(perk70, gtdata; K = 10_000, showprogress=false); 
# 18.171832 seconds (2.79 M allocations: 7.120 GiB, 2.14% gc time) -- trend application 
# 18.244088 seconds (2.79 M allocations: 7.120 GiB, 2.81% gc time, 0.04% compilation time) -- trend application & no monitor
@time tray_infl = gentrayinfl(perk70, gtdata; K = 125_000, showprogress=false); 
# 233.178001 seconds (34.86 M allocations: 88.997 GiB, 2.74% gc time) -- trend application 
# 219.209665 seconds (34.75 M allocations: 88.991 GiB, 1.82% gc time) -- trend application & no monitor


## Con o sin generador propio ? 

# Sin generador propio myrng
@time tray_infl = gentrayinfl(totalfn, gtdata; K = 10000)
# 15.939332 seconds (545.15 k allocations: 4.583 GiB, 1.69% gc time, 0.28% compilation time)

# Con generador myrng interno
@time tray_infl = gentrayinfl(totalfn, gtdata; K = 10000) 
#  10.896991 seconds (545.28 k allocations: 4.583 GiB, 2.55% gc time, 0.44% compilation time)

## Prueba de replicación

tray_infl1 = gentrayinfl(totalfn, gtdata; K = 200, rndseed = 31415)
tray_infl2 = gentrayinfl(totalfn, gtdata; K = 200, rndseed = 31415)

tray_infl1 == tray_infl2

## Estadísticas de prueba

using Statistics
using Plots

m_tray_infl = mean(tray_infl; dims = 3)
plot(m_tray_infl, title = "Trayectoria promedio", label = totalfn.name)