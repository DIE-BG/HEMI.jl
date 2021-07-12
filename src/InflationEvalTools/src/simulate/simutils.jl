


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