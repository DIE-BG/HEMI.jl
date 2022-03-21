# eval_mse_online.jl - Generación de MSE de optimización online  

"""
    eval_mse_online(config::SimConfig, csdata::CountryStructure; 
        K = 1000, 
        rndseed = DEFAULT_SEED) -> mse

Función para obtener evaluación de error cuadrático medio utilizando
configuración de evaluación [`SimConfig`](@ref). Se deben proveer los datos de
evaluación en `csdata`, con los cuales se desee computar la trayectoria
paramétrica de comparación. Devuelve el MSE como un escalar.

Esta función se puede utilizar para optimizar los parámetros de diferentes
medidas de inflación y es más eficiente en memoria que [`pargentrayinfl`](@ref). 
"""
function eval_mse_online(config::SimConfig, csdata::CountryStructure; 
    K = 1000, 
    rndseed = DEFAULT_SEED)

    # Crear el parámetro y obtener la trayectoria paramétrica
    param = InflationParameter(config.paramfn, config.resamplefn, config.trendfn)
    tray_infl_param = param(csdata)

    # Desempaquetar la configuración 
    eval_mse_online(config.inflfn, config.resamplefn, config.trendfn, csdata, tray_infl_param; K, rndseed)
end


"""
    eval_mse_online(
        inflfn::InflationFunction,
        resamplefn::ResampleFunction, 
        trendfn::TrendFunction,
        csdata::CountryStructure, 
        tray_infl_param::Vector{<:AbstractFloat}; 
        K = 1000, rndseed = DEFAULT_SEED) -> mse

Función para obtener evaluación de error cuadrático medio (MSE) utilizando la
configuración especificada. Se requiere la trayectoria paramétrica
`tray_infl_param` para evitar su cómputo repetidamente en esta función. Devuelve
el MSE como un escalar.
"""
function eval_mse_online(
    inflfn::InflationFunction,
    resamplefn::ResampleFunction, 
    trendfn::TrendFunction,
    csdata::CountryStructure, 
    tray_infl_param::Vector{<:AbstractFloat}; 
    K = 1000, rndseed = DEFAULT_SEED)

    # Tarea de cómputo de trayectorias
    mse = @showprogress @distributed (OnlineStats.merge) for k in 1:K 
        # Configurar la semilla en el proceso
        Random.seed!(LOCAL_RNG, rndseed + k)

        # Muestra de bootstrap de los datos 
        bootsample = resamplefn(csdata, LOCAL_RNG)
        # Aplicación de la función de tendencia 
        trended_sample = trendfn(bootsample)

        # Computar la medida de inflación y el MSE
        tray_infl = inflfn(trended_sample)
        sq_err = (tray_infl - tray_infl_param) .^ 2
        o = OnlineStats.Mean(eltype(csdata))
        OnlineStats.fit!(o, sq_err)
    end 

    OnlineStats.value(mse)::eltype(csdata)
end
