
# Funciones para evaluación

"""
    evalsim(data_eval::CountryStructure, config::SimConfig)

Esta función genera trayectorias de simulación utilizando la configuración `SimConfig` y obteniendo métricas de evaluación en el período completo de simulación. Devuelve una tupla de métricas y trayectorias de inflación en la última posición.
"""
function evalsim(data_eval::CountryStructure, config::SimConfig)
  
    # Obtener la trayectoria paramétrica de inflación 
    param = ParamTotalCPIRebase(config.resamplefn, config.trendfn)
    tray_infl_pob = param(data_eval)

    @info "Evaluación de medida de inflación" medida=measure_name(config.inflfn) remuestreo=method_name(config.resamplefn) tendencia=method_name(config.trendfn) simulaciones=config.nsim 

    # Generar las trayectorias de inflación de simulación 
    tray_infl = pargentrayinfl(config.inflfn, # función de inflación
        config.resamplefn, # función de remuestreo
        config.trendfn, # función de tendencia
        data_eval, # datos de evaluación 
        rndseed = 0, K=config.nsim)
    println()

    # Métricas de evaluación 
    err_dist = tray_infl .- tray_infl_pob
    sq_err_dist = err_dist .^ 2
    mse = mean(sq_err_dist) 
    std_sim_error = std(sq_err_dist) / sqrt(config.nsim)
    rmse = mean(sqrt.(sq_err_dist))
    mae = mean(abs.(err_dist))
    me = mean(err_dist)
    # correlación, to-do...
    @info "Métricas de evaluación:" mse std_sim_error rmse me mae

    # Devolver estos valores
    mse, std_sim_error, rmse, me, mae, tray_infl
end

# Función para obtener diccionario de resultados y trayectorias a partir de un
# AbstractConfig
function makesim(data, config::AbstractConfig)
        
     # Ejecutar la simulación y obtener los resultados 
    mse, std_sim_error, rmse, me, mae, tray_infl = evalsim(data, config)

    # Agregar resultados a diccionario 
    results = struct2dict(config)
    results[:mse] = mse
    results[:std_sim_error] = std_sim_error
    results[:rmse] = rmse
    results[:me] = me
    results[:mae] = mae
    results[:measure] = CPIDataBase.measure_name(config.inflfn)
    results[:params] = CPIDataBase.params(config.inflfn)

    return results, tray_infl 
end


# Función para ejecutar lote de simulaciones 
function run_batch(data, dict_list_params, savepath; savetrajectories = true)

    # Ejecutar lote de simulaciones 
    for (i, dict_params) in enumerate(dict_list_params)
        @info "Ejecutando simulación $i..."
        config = dict_config(dict_params) 
        results, tray_infl = makesim(data, config)

        # Guardar los resultados 
        filename = savename(config, "jld2", connector= " - ", equals=" = ")
        
        # Resultados de evaluación para collect_results 
        wsave(joinpath(savepath, filename), tostringdict(results))
        
        # Guardar trayectorias de inflación, directorio tray_infl de la ruta de guardado
        savetrajectories && wsave(joinpath(savepath, "tray_infl", filename), "tray_infl", tray_infl)
    end

end


# Funciones de ayuda 
"""
    dict_config(params::Dict)

Función para convertir diccionario a `AbstractConfig`.
"""
function dict_config(params::Dict)
    # configD = SimConfig(dict_prueba[:inflfn], dict_prueba[:resamplefn], dict_prueba[:trendfn], dict_prueba[:nsim])
    if length(params) == 4
        config = SimConfig(params[:inflfn], params[:resamplefn], params[:trendfn], params[:nsim])
    else
        config = CrossEvalConfig(params[:inflfn], params[:resamplefn], params[:trendfn], params[:nsim], params[:train_date], params[:eval_size])        
    end
end