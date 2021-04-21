# Versión experimental con configuración de semilla por iteración
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


# Versión experimental con opción de control de progreso
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


# export pargentrayinfl_pmap
# Versión con pmap es más lenta
function pargentrayinfl_pmap(inflfn::F, csdata::CS; 
    K = 100, rndseed = 161803, showprogress = true) where {F <: InflationFunction, CS <: CountryStructure}

    p = Progress(K, barglyphs=BarGlyphs("[=> ]"), enabled = showprogress)
    
    tray_infl = progress_pmap(1:K, progress=p) do k
        # Configurar la semilla en el proceso
        Random.seed!(LOCAL_RNG, rndseed + k)

        # Muestra de bootstrap de los datos 
        bootsample = deepcopy(csdata)
        scramblevar!(bootsample, LOCAL_RNG)

        # Computar la medida de inflación 
        inflfn(bootsample)
    end

    # Retornar las trayectorias
    # cat(tray_infl...; dims=3)
    tray_infl
end