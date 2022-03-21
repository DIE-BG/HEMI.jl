# eval_absme_online.jl - Generación de ABSME de optimización online  

"""
    eval_absme_online(config::SimConfig, csdata::CountryStructure; 
        K = 1000, 
        rndseed = DEFAULT_SEED) -> absme

Función para obtener evaluación del valor absoluto de error medio utilizando
configuración de evaluación [`SimConfig`](@ref). Se deben proveer los datos de
evaluación en `csdata`, con los cuales se desee computar la trayectoria
paramétrica de comparación. Devuelve la métrica de valor absoluto como un
escalar.

Esta función se puede utilizar para optimizar los parámetros de diferentes
medidas de inflación y es más eficiente en memoria que [`pargentrayinfl`](@ref). 
"""
function eval_absme_online(config::SimConfig, csdata::CountryStructure; 
    K = 1000, 
    rndseed = DEFAULT_SEED)

    # Crear el parámetro y obtener la trayectoria paramétrica
    param = InflationParameter(config.paramfn, config.resamplefn, config.trendfn)
    tray_infl_param = param(csdata)

    # Desempaquetar la configuración 
    eval_absme_online(config.inflfn, config.resamplefn, config.trendfn, csdata, tray_infl_param; K, rndseed)
end


"""
    eval_absme_online(
        inflfn::InflationFunction,
        resamplefn::ResampleFunction, 
        trendfn::TrendFunction,
        csdata::CountryStructure, 
        tray_infl_param::Vector{<:AbstractFloat}; 
        K = 1000, rndseed = DEFAULT_SEED) -> absme

Función para obtener evaluación de valor absoluto de error medio (ABSME)
utilizando la configuración especificada. Se requiere la trayectoria paramétrica
`tray_infl_param` para evitar su cómputo repetidamente en esta función. Devuelve
el ABSME como un escalar.
"""
function eval_absme_online(
    inflfn::InflationFunction,
    resamplefn::ResampleFunction, 
    trendfn::TrendFunction,
    csdata::CountryStructure, 
    tray_infl_param::Vector{<:AbstractFloat}; 
    K = 1000, rndseed = DEFAULT_SEED)

    # Tarea de cómputo de trayectorias
    me = @showprogress @distributed (OnlineStats.merge) for k in 1:K 
        # Configurar la semilla en el proceso
        Random.seed!(LOCAL_RNG, rndseed + k)

        # Muestra de bootstrap de los datos 
        bootsample = resamplefn(csdata, LOCAL_RNG)
        # Aplicación de la función de tendencia 
        trended_sample = trendfn(bootsample)

        # Computar la medida de inflación y el ABSME
        tray_infl = inflfn(trended_sample)
        err = (tray_infl - tray_infl_param) 
        o = OnlineStats.Mean(eltype(csdata))
        OnlineStats.fit!(o, err)
    end 

    abs(OnlineStats.value(me))::eltype(csdata)
end
