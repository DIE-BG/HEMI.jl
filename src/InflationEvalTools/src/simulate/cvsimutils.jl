# Funciones de simulación para CrossEvalConfig

# Función para generación de trayectorias y parámetros para el procedimiento de validación cruzada de las combinaciones lineales de medidas de inflación 
function makesim(data::CountryStructure, config::CrossEvalConfig; kwargs...)

    # Obtener parámetro de inflación 
    param = InflationParameter(config.paramfn, config.resamplefn, config.trendfn)
    # Diccionario de resultados 
    cvinputs = Dict{String, Any}()
    cvinputs["config"] = config
    # Opciones extra para pargentrayinfl
    pargenkwargs = filter(e -> first(e) != :K, kwargs)
    
    # Generar datos para cada subperíodo de entrenamiento y validación
    for (i, evalperiod) in enumerate(config.evalperiods)
          
        traindate = evalperiod.startdate - Month(1)
        cvdate = evalperiod.finaldate
        fmt = dateformat"yy"
        @info "Iteración $i de validación cruzada" evalperiod traindate cvdate 
        
        # Generar trayectorias de inflación y trayectoria paramétrica 
        for finaldate in (traindate, cvdate)

            # Obtener las llaves para guardar los resultados El formato es el
            # del prefijo "infl_" o "param_" y los últimos dos años de la fecha
            # final de cada subperíodo de entrenamiento o validación 
            tray_key = "infl_" * Dates.format(finaldate, fmt)
            param_key = "param_" * Dates.format(finaldate, fmt)
            dates_key = "dates_" * Dates.format(finaldate, fmt)
            sliced_data = data[finaldate]

            # Generar trayectorias de inflación 
            if !(tray_key in keys(cvinputs))
                @info "Generando trayectorias de inflación" finaldate
                cvinputs[tray_key] = pargentrayinfl(
                    config.inflfn, 
                    config.resamplefn, 
                    config.trendfn, 
                    sliced_data; 
                    K = config.nsim, pargenkwargs...)
                cvinputs[dates_key] = infl_dates(sliced_data)
            end

            # Generar trayectoria paramétrica 
            if !(param_key in keys(cvinputs)) 
                @info "Generando trayectoria paramétrica" finaldate
                cvinputs[param_key] = param(sliced_data)
            end

        end

    end

    cvinputs
end
