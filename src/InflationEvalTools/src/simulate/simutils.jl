
# Funciones para evaluación

function evalsim(data_eval::CountryStructure, config::AbstractConfig, period=36)
  
    # Obtener la trayectoria paramétrica de inflación 
    param = ParamTotalCPIRebase(config.resamplefn, config.trendfn)
    tray_infl_pob = param(data_eval)

    @info "Evaluación de medida de inflación" measure_name(config.inflfn) method_name(config.resamplefn) method_name(config.trendfn) config.nsim 

    # Generar las trayectorias de inflación de simulación 
    tray_infl = pargentrayinfl(config.inflfn, # función de inflación
        config.resamplefn, # función de remuestreo
        config.trendfn, # función de tendencia
        data_eval, # datos de evaluación 
        rndseed = 0, K=config.nsim)
    println()

    # Métricas de evaluación 
    println()
    std_sim_error = std((tray_infl .- tray_infl_pob) .^ 2) / sqrt(config.nsim)
    mse = mean( (tray_infl .- tray_infl_pob) .^ 2) 
    rmse = mean( sqrt.((tray_infl .- tray_infl_pob) .^ 2))
    me = mean((tray_infl .- tray_infl_pob))
    @info "Métricas de evaluación:" mse std_sim_error rmse me

    # Devolver estos valores
    mse, std_sim_error, rmse, me, tray_infl
end

function makesim(data, params::Dict)
     # Obtener parámetros de simulación 
    config = dict_config(params) 
    
     # Ejecutar la simulación y obtener los resultados 
    mse, std_sim_error, rmse, me, tray_infl = evalsim(data, config)

    # Agregar resultados a diccionario 
    results = copy(params)
    results[:mse] = mse
    results[:std_sim_error] = std_sim_error
    results[:rmse] = rmse
    results[:me] = me

    return results, tray_infl 
end

# function run_batch(data, SimConfig, savepath, plotspath) 

#     # Convertir SimConfig a Diccionario para usarlo en DrWatson (sim_params)
#         params = convert(SimConfig)
#     # Ejecutar lote de simulaciones 
#     for (i, params) in enumerate(sim_params)
#         @info "Ejecutando simulación $i..."
#         results = makesim(data, params, path=plotspath)

#         # Guardar los resultados 
#         filename = savename("eval", SimConfig, "jld2")
#         # Results para collect_results 
#         wsave(joinpath(savepath, filename), results)
#         # Trayectorias de inflación (ojo con la carpeta)
#         wsave(joinpath(savepath, filename), tray_infl)
#     end

# end


## Función para convertir diccionario a AbstractConfig

function dict_config(params::Dict)
    # configD = SimConfig(dict_prueba[:inflfn], dict_prueba[:resamplefn], dict_prueba[:trendfn], dict_prueba[:nsim])
    if length(params) == 4
        config = SimConfig(params[:inflfn], params[:resamplefn], params[:trendfn], params[:nsim])
    else
        config = CrossEvalConfig(params[:inflfn], params[:resamplefn], params[:trendfn], params[:nsim], params[:train_date], params[:eval_size])        
    end
end