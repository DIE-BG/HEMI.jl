
## Funciones de evaluación de variantes MAI para optimización de cuantiles del algoritmo de renormalización 

using CSV, DataFrames

## Función de evaluación para optimizador 
function evalmai(q, 
    maimethod, resamplefn, trendfn, evaldata, tray_infl_param; 
    K::Int = 10_000, 
    metric::Symbol = :mse)

    # Penalización base 
    s = metric == :corr ? -1 : 1 # signo para métrica objetivo
    bp = 10 * one(eltype(q))
    penalty = zero(eltype(q))

    # Penalización para que el vector de cuantiles se encuentre en el interior
    # de [0, 1]
    if !all(0 .< q .< 1) 
        penalty += bp + 2*sum(q .< 0) + 2*sum(q .> 1)
    end

    # Imponer restricciones de orden con penalizaciones si se viola el orden de
    # los cuantiles 
    for i in 1:length(q)-1
        if q[i] > q[i+1] 
            penalty += bp + 2(q[i] - q[i+1])
        end
    end 
    penalty != 0 && return penalty 

    # Crear configuración de evaluación
    inflfn = InflationCoreMai(maimethod(Float64[0, q..., 1]))

    # Evaluar la medida y obtener métrica de evaluación 
    tray_infl = pargentrayinfl(inflfn, resamplefn, trendfn, evaldata; K)
    metrics = eval_metrics(tray_infl, tray_infl_param)
    obj = metrics[metric]
    s*obj + penalty 
end


# Función para optimización de método en `method` con n segmentos 
function optimizemai(n, method, resamplefn, trendfn, dataeval, tray_infl_param; 
    savepath, # Ruta de guardado de resultados de optimización 
    K = 10_000, # Número de simulaciones por defecto 
    qstart = nothing, # Puntos iniciales, por defecto distribución uniforme 
    x_abstol = 1e-4, 
    f_abstol = 1e-4, 
    maxiterations = 100, 
    metric = :mse
    )

    # Puntos iniciales de búsqueda 
    if isnothing(qstart)
        q0 = collect(1/n:1/n:(n-1)/n) 
    else
        q0 = qstart
    end

    # Se dejan los límites entre 0 y 1 y las restricciones de orden e
    # interioridad se delegan a evalmai
    qinf, qsup = zeros(n), ones(n)

    # Función cerradura 
    maifn = q -> evalmai(q, method, resamplefn, trendfn, dataeval, 
        tray_infl_param; K, metric)
        
    # Optimización
    optres = optimize(
        maifn, # Función objetivo 
        qinf, qsup, # Límites
        q0, # Punto inicial
        NelderMead(), # Método
        Optim.Options(
            x_abstol = x_abstol, f_abstol = f_abstol, 
            show_trace = true, extended_trace=true, 
            iterations = maxiterations))

    println(optres)
    @info "Resultados de optimización:" minimum=minimum(optres) minimizer=Optim.minimizer(optres)  iterations=Optim.iterations(optres)
    
    # Guardar resultados
    results = Dict(
        "method" => string(method), 
        "n" => n, 
        "q" => Optim.minimizer(optres), 
        string(metric) => minimum(optres),
        "K" => K,
        "optres" => optres
    )

    # Guardar los resultados 
    if Sys.iswindows() && Sys.windows_version() < v"10"
        # Guardar resultados en CSV para optimización en equipo servidor 
        filename = savename(results, "csv", allowedtypes=(Real, String), digits=6)
        CSV.write(filename, DataFrame(results))
    else 
        # Resultados de evaluación para collect_results 
        filename = savename(results, "jld2", allowedtypes=(Real, String), digits=6)
        wsave(joinpath(savepath, filename), tostringdict(results))
    end

    optres 
end


# Función para optimización MAI de método en `method` con n segmentos utilizando
# diccionario de configuración 
# function optimizemai(n, method, resamplefn, trendfn, dataeval, tray_infl_param; 
function optimizemai(config, data; options...)
    # Datos de evaluación 
    dataeval = data[config[:traindate]]
    
    # Configuración de simulación 
    resamplefn = config[:resamplefn]
    trendfn = config[:trendfn]
    paramfn = config[:paramfn]
    # Parámetro de inflación 
    param = InflationParameter(paramfn, resamplefn, trendfn)
    tray_infl_param = param(dataeval)

    optimizemai(config[:mai_nseg], config[:mai_method], 
        resamplefn, trendfn, dataeval, tray_infl_param; options...)

end
