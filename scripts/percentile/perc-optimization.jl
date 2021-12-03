## Función de evaluación para optimizador iterativo  
function evalperc(k, config, data, tray_infl_param; K = 10_000, kbounds = [50, 99], metric = :mse)

    # Penalización base y límites de búsqueda
    BP = 100 * one(eltype(data))
    s = metric == :corr ? -1 : 1 # signo para función objetivo
    kbounds[1] <= k <= kbounds[2] || return BP

    # Configurar la función de inflación a evaluar
    infl_constructor = config[:infltypefn]
    inflfn = infl_constructor(k)

    # Configuración de remuestreo, tendencia
    resamplefn = config[:resamplefn]
    trendfn = config[:trendfn]

    # Métrica de evaluación
    tray_infl = pargentrayinfl(inflfn, resamplefn, trendfn, data; K)
    metrics = eval_metrics(tray_infl, tray_infl_param)
    obj = metrics[metric]
    s*obj
end

# Función para optimización automática de percentiles  
function optimizeperc(config, data; 
    savepath = nothing, # Ruta de guardado de resultados de optimización 
    K = config[:nsim], # Número de simulaciones por defecto 
    kbounds = [50, 99], # Límites inferior y superior
    k_abstol = 1e-2, # Precisión del percentil buscado 
    f_abstol = 1e-4, # Precisión en la función objetivo
    maxiterations = 100, 
    metric = :mse
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
    percmse = k -> evalperc(k[1], config, evaldata, tray_infl_param; K, kbounds, metric)

    # Optimización
    optres = optimize(
        percmse, # Función objetivo 
        kinf, ksup, # Límites
        Brent(); 
        abs_tol = f_abstol, # Tolerancia en función objetivo 
        iterations = maxiterations)

    println(optres)
    @info "Resultados de optimización:" minimum=minimum(optres) minimizer=Optim.minimizer(optres)  iterations=Optim.iterations(optres)
    
    # Guardar resultados de optimización
    results = Dict(
        # Resultados de optimización 
        "k" => Optim.minimizer(optres), 
        string(metric) => minimum(optres),
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