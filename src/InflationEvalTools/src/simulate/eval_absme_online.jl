# eval_absme_online.jl - Generación de ABSME de optimización online  

"""
    function eval_absme_online(config::SimConfig, tray_infl_param; 
        K = 1000, rnsdeed = DEFAULT_SEED) -> absme

Función para obtener evaluación de valor absoluto de error medio utilizando
configuración de evaluación [`SimConfig`](@ref). Se debe proveer la trayectoria
paramétrica de comparación en `tray_infl_param`, esto para evitar su cómputo
repetido en esta función. Devuelve el ABSME como un escalar.

Esta función se puede utilizar para optimizar los parámetros de diferentes
medidas de inflación y es más eficiente en memoria que [`pargentrayinfl`](@ref). 
"""
function eval_absme_online(config::SimConfig, csdata::CountryStructure, tray_infl_param; 
    K = 1000, rnsdeed = DEFAULT_SEED)
    # Desempaquetar la configuración 
    eval_absme_online(config.inflfn, config.resamplefn, config.trendfn, csdata, tray_infl_param; K)
end


"""
    function eval_absme_online(inflfn::InflationFunction,
        resamplefn::ResampleFunction, trendfn::TrendFunction,
        csdata::CountryStructure, tray_infl_param; K = 100, rndseed = DEFAULT_SEED) -> absme

Función para obtener evaluación de valor absoluto de error medio (ABSME) utilizando las
funciones especificadas. Devuelve el ABSME como un escalar.
"""
function eval_absme_online(inflfn::InflationFunction,
    resamplefn::ResampleFunction, trendfn::TrendFunction,
    csdata::CountryStructure, tray_infl_param; K = 100, rndseed = DEFAULT_SEED)

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
