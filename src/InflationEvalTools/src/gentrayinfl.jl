# Función de generación de trayectorias de inflación
function gentrayinfl(inflfn::F, csdata::CountryStructure; 
    K = 100, rndseed = 161803, showprogress = true) where {F <: InflationFunction}

    # Configurar el generador de números aleatorios
    myrng = MersenneTwister(rndseed)

    # Cubo de trayectorias de salida
    periods = infl_periods(csdata)
    n_measures = num_measures(inflfn)
    tray_infl = zeros(Float32, periods, n_measures, K)

    # Control de progreso
    p = Progress(K; enabled = showprogress)

    # Generar las trayectorias
    for k in 1:K 
        # Muestra de bootstrap de los datos 
        bootsample = deepcopy(csdata)
        scramblevar!(bootsample, myrng)
        trended_sample = apply_trend(bootsample, RWTREND)

        # Computar la medida de inflación 
        tray_infl[:, :, k] = inflfn(trended_sample)
        
        ProgressMeter.next!(p)
    end

    # Retornar las trayectorias
    tray_infl
end