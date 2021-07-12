
# Funciones para evaluación

function evalsim(data_eval, SimConfig)
  
    paramfn = get_param_function(resamplefn)
    # Obtener la trayectoria paramétrica de inflación 
    data_param = paramfn(data_eval)
    totalrebasefn = InflationTotalRebaseCPI(period = period)
    tray_infl_pob = totalrebasefn(data_param)

    @info "Evaluación de medida de inflación" inflfn resamplefn k b Ksim

    # Generar las trayectorias de inflación de simulación 
    tray_infl = pargentrayinfl(SimConfig.inflfn, # función de inflación
        data_eval, # datos de evaluación hasta dic-20
        SimConfig.resamplefn, # remuestreo SBB
        SimConfig.trendfn; # sin tendencia 
        rndseed = 0, K=Ksim)
    println()

      # Métricas de evaluación 
     std_sim_error = std((tray_infl .- tray_infl_pob) .^ 2) / sqrt(Ksim)
    mse = mean( (tray_infl .- tray_infl_pob) .^ 2) 
    rmse = mean( sqrt.((tray_infl .- tray_infl_pob) .^ 2))
    me = mean((tray_infl .- tray_infl_pob))
    @info "Métricas de evaluación:" mse std_mse std_sim_error rmse me

    # Devolver estos valores
    mse_dist, mse, std_mse, std_sim_error, rmse, me, tray_infl
end

function makesim(data, SimConfig)
    # Obtener parámetros de simulación 
    
    
    # Ejecutar la simulación y obtener los resultados 
    mse_dist, mse, std_mse, std_sim_error, rmse, me, tray_infl = evalsim(data,SimConfig)

    # Agregar resultados a diccionario 
    results = copy(SimConfig)
    results["mse_dist"] = mse_dist
    results["mse"] = mse
    results["std_mse"] = std_mse
    results["std_sim_error"] = std_sim_error
    results["rmse"] = rmse
    results["me"] = me

    return results, tray_infl 
end

function run_batch(data, SimConfig, savepath, plotspath) 

    # Convertir SimConfig a Diccionario para usarlo en DrWatson (sim_params)

    # Ejecutar lote de simulaciones 
    for (i, params) in enumerate(sim_params)
        @info "Ejecutando simulación $i..."
        results = makesim(data, params, path=plotspath)

        # Guardar los resultados 
        filename = savename("eval", SimConfig, "jld2")
        # Results para collect_results 
        wsave(joinpath(savepath, filename), results)
        # Trayectorias de inflación (ojo con la carpeta)
        wsave(joinpath(savepath, filename), tray_infl)
    end

end 