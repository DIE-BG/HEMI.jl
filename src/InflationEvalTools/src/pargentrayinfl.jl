const LOCAL_RNG = Random.MersenneTwister(0)

# Función para configurar semilla de los workers 
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

# Función para generación de trayectorias con computación paralela y replicación 
# con la misma cantidad de workers
function pargentrayinfl(inflfn::F, csdata::CountryStructure; 
    K = 100, rndseed = 0, showprogress = true) where {F <: InflationFunction}

    # Cubo de trayectorias de salida
    periods = infl_periods(csdata)
    n_measures = num_measures(inflfn)
    tray_infl = SharedArray{Float32}(periods, n_measures, K)

    # Control de progreso
    progress= Progress(K, enabled=showprogress)
    channel = RemoteChannel(()->Channel{Bool}(K), 1)

    # Tarea asíncrona para actualizar el progreso
    @async while take!(channel)
        next!(progress)
    end
        
    # Tarea de cómputo de trayectorias
    @sync @distributed for k in 1:K 
        # Configurar la semilla en el proceso
        Random.seed!(LOCAL_RNG, rndseed + k)
        
        # Muestra de bootstrap de los datos 
        bootsample = deepcopy(csdata)
        scramblevar!(bootsample, LOCAL_RNG)
        trended_sample = apply_trend(bootsample, RWTREND)

        # Computar la medida de inflación 
        tray_infl[:, :, k] = inflfn(trended_sample)

        put!(channel, true)
    end 
    put!(channel, false)

    # Retornar las trayectorias
    sdata(tray_infl)
end


