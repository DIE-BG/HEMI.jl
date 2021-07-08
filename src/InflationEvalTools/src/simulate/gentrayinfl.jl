# Función de generación de trayectorias de inflación sin computación paralela

"""
    gentrayinfl(inflfn::F, resamplefn::R, trendfn::T, csdata::CountryStructure; K = 100, rndseed = 0, showprogress = true)

Computa `K` trayectorias de inflación utilizando la función de inflación
`inflfn::`[`InflationFunction`](@ref), la función de remuestreo
`resamplefn::`[`TrendFunction`](@ref) y la función de tendencia
`trendfn::`[`TrendFunction`](@ref) especificada. Se utilizan los datos en el
`CountryStructure` dado en `csdata`.

A diferencia de la función [`pargentrayinfl`](@ref), esta función no realiza el
cómputo de forma  distribuida. 

Para lograr la reproducibilidad entre diferentes corridas de la función, y de
esta forma, generar trayectorias de inflación con diferentes metodologías
utilizando los mismos remuestreos, se fija la semilla de generación de acuerdo
con el número de iteración en la simulación. Para controlar el inicio de la
generación de trayectorias se utiliza como parámetro de desplazamiento el valor
`rndseed`. 
"""
function gentrayinfl(inflfn::F, resamplefn::R, trendfn::T, 
    csdata::CountryStructure; 
    K = 100, 
    rndseed = 0, 
    showprogress = true) where {F <: InflationFunction, R <: ResampleFunction, T <: TrendFunction}

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
        bootsample = resamplefn(csdata, myrng)
        # Aplicación de la función de tendencia 
        trended_sample = trendfn(bootsample)

        # Computar la medida de inflación 
        tray_infl[:, :, k] = inflfn(trended_sample)
        
        ProgressMeter.next!(p)
    end

    # Retornar las trayectorias
    tray_infl
end