## Función de evaluación para optimizador iterativo  
function evalperc(k, config, data, tray_infl_param; K = 10_000, kbounds = [50, 90])

    # Penalización base y límites de búsqueda
    BP = 100 * one(eltype(data))
    kbounds[1] <= k <= kbounds[2] || return BP

    # Configurar la función de inflación a evaluar
    infl_constructor = config[:infltypefn]
    inflfn = infl_constructor(k)

    # Configuración de remuestreo, tendencia
    resamplefn = config[:resamplefn]
    trendfn = config[:trendfn]

    # Métrica de evaluación, MSE 
    mse = eval_mse_online(inflfn, 
        resamplefn, trendfn, data, 
        tray_infl_param; K)
    mse
end

# Función para optimización automática de percentiles  
function optimizeperc(config, data; 
    savepath = nothing, # Ruta de guardado de resultados de optimización 
    K = config[:nsim], # Número de simulaciones por defecto 
    kbounds = [50, 90], # Límites inferior y superior
    k_abstol = 1e-2, # Precisión del percentil buscado 
    f_abstol = 1e-4, # Precisión en el MSE
    maxiterations = 100
    )

    # Límites inferior y superior
    kinf, ksup = kbounds

    # Configuración de remuestreo, tendencia y parámetro
    resamplefn = config[:resamplefn]
    trendfn = config[:trendfn]
    paramfn = config[:paramfn]

    # Datos de evaluación 
    evaldata = data[config[:traindate]]

    # Trayectoria paramétrica 
    param = InflationParameter(paramfn, resamplefn, trendfn) 
    tray_infl_param = param(evaldata)

    # Función cerradura 
    percmse = k -> evalperc(k[1], config, evaldata, tray_infl_param; K, kbounds)
    # @info percmse(50)

    # Optimización
    optres = optimize(
        percmse, # Función objetivo 
        kinf, ksup, # Límites
        Brent(); 
            abs_tol = f_abstol, # Tolerancia en función objetivo 
            iterations = maxiterations 
        )

    println(optres)
    @info "Resultados de optimización:" min_mse=minimum(optres) minimizer=Optim.minimizer(optres)  iterations=Optim.iterations(optres)
    
    # Guardar resultados de optimización
    results = Dict(
        # Resultados de optimización 
        "k" => Optim.minimizer(optres), 
        "mse" => minimum(optres),
        # Parámetros para evaluación completa 
        "param" => config[:paramfn].period,
        "optres" => optres
    )
    merge!(results, tostringdict(config))

    # Guardar los resultados de evaluación para collect_results 
    filename = savename(results, "jld2", allowedtypes=(Real, String, Date), digits=4)
    isnothing(savepath) || wsave(joinpath(savepath, filename), tostringdict(results))

    optres 
end