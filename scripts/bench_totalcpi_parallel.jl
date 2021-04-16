using DrWatson
@quickactivate "HEMI"

## TODO 
# Simulación básica en serie con replicación y benchmark vs MATLAB ✔
# Simulación en paralelo con replicación y benchmark vs MATLAB ✔
# Agregar funciones de inflación adicionales
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
    using CPIDataBase.Resample
    using SharedArrays, Random
    using ProgressMeter
end

# Carga de librerías 
using JLD2

# Carga de datos
@load datadir("guatemala", "gtdata32.jld2") gt00 gt10
const gtdata = CountryStructure(gt00, gt10)

# Computar inflación de Guatemala
totalfn = TotalCPI()

## Definición de función de simulación

import CPIDataBase: InflationFunction

function remote_seed(rndseed)
	ids=SharedArray{Int}(nworkers())
    #now I assume that all workers will be used once:
	@sync @distributed for i in 1:nworkers()
		ids[i]=myid()
    end
	# println(ids)
	for i in 1:length(sort(ids))
		remotecall(Random.seed!, ids[i], rndseed + i)
    end
end


function pargentrayinfl(inflfn::InflationFunction, csdata::CountryStructure; 
    K = 100, rndseed = 161803, showprogress = true)

    # Configurar la semilla en workers
    remote_seed(rndseed)

    # Matriz de trayectorias de salida
    T = sum(size(gtdata[i].v, 1) for i in 1:length(gtdata.base)) - 11
    tray_infl = SharedArray{Float32}(T, K)

    # Control de progreso
    # p = Progress(K; enabled = showprogress)

    # Generar las trayectorias
    @sync @showprogress @distributed for k in 1:K 
        # Muestra de bootstrap de los datos 
        bootsample = deepcopy(csdata)
        scramblevar!(bootsample)

        # Computar la medida de inflación 
        tray_infl[:, k] = inflfn(bootsample)
        
        # ProgressMeter.next!(p)
    end

    # Retornar las trayectorias
    sdata(tray_infl)
end


function pargentrayinfl_seed(inflfn::InflationFunction, csdata::CountryStructure; 
    K = 100, rndseed = 161803, showprogress = true)

    # Matriz de trayectorias de salida
    T = sum(size(gtdata[i].v, 1) for i in 1:length(gtdata.base)) - 11
    tray_infl = SharedArray{Float32}(T, K)

    # Generar las trayectorias
    @sync @showprogress @distributed for k in 1:K 
        
        # Replicación simulación por simulación
        Random.seed!(rndseed + k)
        
        # Muestra de bootstrap de los datos 
        bootsample = deepcopy(csdata)
        scramblevar!(bootsample)

        # Computar la medida de inflación 
        tray_infl[:, k] = inflfn(bootsample)
    end

    # Retornar las trayectorias
    sdata(tray_infl)
end


function pargentrayinfl_prog(inflfn::InflationFunction, csdata::CountryStructure; 
    K = 100, rndseed = 161803, showprogress = true)

    # Configurar la semilla en workers
    remote_seed(rndseed)

    # Matriz de trayectorias de salida
    T = sum(size(gtdata[i].v, 1) for i in 1:length(gtdata.base)) - 11
    tray_infl = SharedArray{Float32}(T, K)

    # Control de progreso
    p = Progress(K; enabled = true)
    channel = RemoteChannel(() -> Channel{Bool}(K), 1)

    @sync begin 
        # this task prints the progress bar
        @async while take!(channel)
            next!(p)
        end
    
        # Esta tarea genera las trayectorias
        @async begin 
            @distributed for k in 1:K 
                # Muestra de bootstrap de los datos 
                bootsample = deepcopy(csdata)
                scramblevar!(bootsample)

                # Computar la medida de inflación 
                tray_infl[:, k] = inflfn(bootsample)
                
                # ProgressMeter
                put!(channel, true)
            end
            put!(channel, false) # esto avisa a la tarea que se terminó
        end
    end
    # Retornar las trayectorias
    sdata(tray_infl)
end


## Benchmark de tiempos en paralelo

# Sin control de progreso
@time tray_infl = pargentrayinfl(totalfn, gtdata; K=10_000)  
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
@time tray_infl = pargentrayinfl(totalfn, gtdata; K = 125_000)

# Sin monitor de progreso: 
# julia> @time tray_infl = pargentrayinfl(totalfn, gtdata; K = 125000) 
# 43.825443 seconds (195.28 k allocations: 11.898 MiB, 0.14% compilation time)

# Con monitor de progreso: 
# julia> @time tray_infl = pargentrayinfl(totalfn, gtdata; K = 125000) 
# 51.085785 seconds (9.16 M allocations: 395.958 MiB, 0.13% gc time, 0.25% compilation time)


## Prueba de replicación

tray_infl1 = pargentrayinfl(totalfn, gtdata; K = 10_000, rndseed = 1618)
tray_infl2 = pargentrayinfl(totalfn, gtdata; K = 10_000, rndseed = 1618)

tray_infl1 == tray_infl2


@time tray_infl1 = pargentrayinfl_seed(totalfn, gtdata; K = 10_000, rndseed = 1618)
# 4.083454 seconds (722.34 k allocations: 30.604 MiB, 0.24% gc time)
@time tray_infl2 = pargentrayinfl_seed(totalfn, gtdata; K = 10_000, rndseed = 1618)
# 4.226844 seconds (722.41 k allocations: 30.605 MiB, 0.23% gc time)

tray_infl1 == tray_infl2



## Estadísticas de prueba

using Statistics
using Plots

m_tray_infl = mean(tray_infl; dims = 2)
plot(m_tray_infl, title = "Trayectoria promedio", label = totalfn.name)