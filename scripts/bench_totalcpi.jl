using DrWatson
@quickactivate "HEMI"

## TODO 
# Simulación básica en serie con replicación y benchmark vs MATLAB ✔
# Simulación en paralelo con replicación y benchmark vs MATLAB
# Agregar funciones de inflación adicionales
# ... (mucho más)

using Dates, CPIDataBase
using JLD2
using CPIDataBase.Resample

# Carga de datos
@load datadir("guatemala", "gtdata32.jld2") gt00 gt10
const gtdata = CountryStructure(gt00, gt10)

# Computar inflación de Guatemala
totalfn = TotalCPI()
tray_infl_gt = totalfn(gtdata)

## Definición de función de simulación

using Random
import CPIDataBase: InflationFunction
using ProgressMeter

function gentrayinfl(inflfn::InflationFunction, csdata::CountryStructure; 
    K = 100, rndseed = 161803, showprogress = true)

    # Configurar el generador de números aleatorios
    myrng = MersenneTwister(rndseed)

    # Matriz de trayectorias de salida
    T = sum(size(gtdata[i].v, 1) for i in 1:length(gtdata.base)) - 11
    tray_infl = zeros(Float32, T, K)

    # Control de progreso
    p = Progress(K; enabled = showprogress)

    # Generar las trayectorias
    for k in 1:K 
        # Muestra de bootstrap de los datos 
        bootsample = deepcopy(csdata)
        scramblevar!(bootsample, myrng)

        # Computar la medida de inflación 
        tray_infl[:, k] = inflfn(bootsample)
        
        ProgressMeter.next!(p)
    end

    # Retornar las trayectorias
    tray_infl
end

## Benchmark de tiempos

@time tray_infl = gentrayinfl(totalfn, gtdata; K=10_000)  
# Progress: 100%|██████████████████████████| Time: 0:00:10
#  10.099791 seconds (399.15 k allocations: 4.574 GiB, 1.41% gc time, 0.06% compilation time)

@time tray_infl = gentrayinfl(totalfn, gtdata; K = 125_000)
# julia> @time tray_infl = gentrayinfl(totalfn, gtdata; K = 125000) 
# 136.687623 seconds (4.87 M allocations: 57.170 GiB, 2.85% gc time)

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

m_tray_infl = mean(tray_infl; dims = 2)
plot(m_tray_infl, title = "Trayectoria promedio", label = totalfn.name)