## Función para obtener error de validación cruzada utilizando CrossEvalConfig 

# crossvaldata es un diccionario de resultados producido por makesim para un CrossEvalConfig. Se hace de esta forma para que las trayectorias de inflación estén precomputadas, ya que sería muy costoso generarlas al vuelo.
function crossvalidate(crossvaldata::Dict{String}, config::CrossEvalConfig, weightsfunction; 
    show_status = true,
    print_weights = true) 
    # return_weights = false)

    folds = length(config.evalperiods)
    cv_mse = zeros(Float32, folds)

    # Obtener parámetro de inflación 
    for (i, evalperiod) in enumerate(config.evalperiods)
    
        @debug "Ejecutando iteración $i de validación cruzada" evalperiod 

        # Obtener los datos de entrenamiento y validación 
        traindate = evalperiod.startdate - Month(1)
        cvdate = evalperiod.finaldate
        
        train_tray_infl = crossvaldata[_getkey("infl", traindate)]
        train_tray_infl_param = crossvaldata[_getkey("param", traindate)]
        train_dates = crossvaldata[_getkey("dates", traindate)]
        cv_tray_infl = crossvaldata[_getkey("infl", cvdate)]
        cv_tray_infl_param = crossvaldata[_getkey("param", cvdate)]
        cv_dates = crossvaldata[_getkey("dates", cvdate)]

        # Ponderadores 
        a = weightsfunction(train_tray_infl, train_tray_infl_param)

        # Máscara de períodos de evaluación 
        mask = evalperiod.startdate .<= cv_dates .<= evalperiod.finaldate

        # Obtener métrica de evaluación en subperíodo de CV 
        cv_tray_infl_opt = sum(cv_tray_infl .* a', dims=2)
        mse_cv = @views eval_metrics(cv_tray_infl_opt[mask, :, :], cv_tray_infl_param[mask], short=true)[:mse]
        cv_mse[i] = mse_cv
        # test_mse = sum(x -> x^2, (cv_tray_infl .* a') .- cv_tray_infl_param, dims=2)
        # println(test_mse)

        show_status && @info "Evaluación ($i/$folds):" evalperiod traindate mse_cv
        print_weights && println(a)
    
    end

    # return_weights && return cv_mse, a
    
    cv_mse
end


function _getkey(prefix, date) 
    fmt = dateformat"yy" 
    prefix * "_" * Dates.format(date, fmt)
end