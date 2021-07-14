
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
    mse, std_sim_error, rmse, me#, tray_infl
end

# function makesim(data, SimConfig)
#     # Obtener parámetros de simulación 
    
    
#     # Ejecutar la simulación y obtener los resultados 
#     mse_dist, mse, std_mse, std_sim_error, rmse, me, tray_infl = evalsim(data,SimConfig)

#     # Agregar resultados a diccionario 
#     results = copy(SimConfig)
#     results["mse_dist"] = mse_dist
#     results["mse"] = mse
#     results["std_mse"] = std_mse
#     results["std_sim_error"] = std_sim_error
#     results["rmse"] = rmse
#     results["me"] = me

#     return results, tray_infl 
# end

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