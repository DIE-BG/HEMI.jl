# eval_corr_online.jl - Generación de CORR de optimización online  

"""
    eval_corr_online(config::SimConfig, csdata::CountryStructure;
        K = 1000, 
        rndseed = DEFAULT_SEED) -> corr

Función para obtener evaluación de correlación media (corr) utilizando
configuración de evaluación [`SimConfig`](@ref). Se deben proveer los datos de
evaluación en `csdata`, con los cuales se desee computar la trayectoria
paramétrica de comparación. Devuelve la correlación media (corr) como un
escalar.

Esta función se puede utilizar para optimizar los parámetros de diferentes
medidas de inflación y es más eficiente en memoria que [`pargentrayinfl`](@ref). 
"""
function eval_corr_online(config::SimConfig, csdata::CountryStructure; 
    K = 1000, 
    rndseed = DEFAULT_SEED)
    
    # Crear el parámetro y obtener la trayectoria paramétrica
    param = InflationParameter(config.paramfn, config.resamplefn, config.trendfn)
    tray_infl_param = param(csdata)

    # Desempaquetar la configuración 
    eval_corr_online(config.inflfn, config.resamplefn, config.trendfn, csdata, tray_infl_param; K, rndseed)
end


"""
    eval_corr_online(
        inflfn::InflationFunction,
        resamplefn::ResampleFunction, 
        trendfn::TrendFunction,
        csdata::CountryStructure, 
        tray_infl_param::Vector{<:AbstractFloat};
        K = 1000, rndseed = DEFAULT_SEED) -> corr

Función para obtener evaluación de correlación media (corr) utilizando la
configuración especificada. Se requiere la trayectoria paramétrica
`tray_infl_param` para evitar su cómputo repetidamente en esta función. Devuelve
la correlación media (corr) como un escalar.
"""
function eval_corr_online(
    inflfn::InflationFunction,
    resamplefn::ResampleFunction, 
    trendfn::TrendFunction,
    csdata::CountryStructure, 
    tray_infl_param::Vector{<:AbstractFloat}; 
    K = 1000, rndseed = DEFAULT_SEED)

    # Tarea de cómputo de trayectorias
    mean_corr = @showprogress @distributed (OnlineStats.merge) for k in 1:K 
        # Configurar la semilla en el proceso
        Random.seed!(LOCAL_RNG, rndseed + k)

        # Muestra de bootstrap de los datos 
        bootsample = resamplefn(csdata, LOCAL_RNG)
        # Aplicación de la función de tendencia 
        trended_sample = trendfn(bootsample)

        # Computar la medida de inflación y CORR
        tray_infl = inflfn(trended_sample)
        corr = cor(tray_infl, tray_infl_param) 
        o = OnlineStats.Mean(eltype(csdata))
        OnlineStats.fit!(o, corr)
    end 

    OnlineStats.value(mean_corr)::eltype(csdata)
end
