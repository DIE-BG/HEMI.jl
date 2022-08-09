function evalmai(q::Vector{T}, 
    maimethod, resamplefn, trendfn, evaldata, tray_infl_param; 
    K::Int = 10_000, 
    metric::Symbol = :mse, 
    lambda::Real = T(0.1)) where {T <: AbstractFloat}

    # Penalización base 
    s = metric == :corr ? -1 : 1 # signo para métrica objetivo
    bp = 10 * one(T)
    penalty = zero(T)

    # Penalización para que el vector de cuantiles se encuentre en el interior
    # de [0, 1]
    if !all(0 .< q .< 1) 
        penalty += bp + 2*sum(q .< 0) + 2*sum(q .> 1)
    end

    # Imponer restricciones de orden con penalizaciones si se viola el orden de
    # los cuantiles 
    for i in 1:length(q)-1
        # Si cuantil i es mayor al i+1 se impone penalización 
        if q[i] >= q[i+1] 
            penalty += bp + 5(q[i] - q[i+1])
        end
    end 
    # Si se violan las restricciones en este punto, devolver únicamente la penalización
    penalty != 0 && return penalty 

    # Ahora se imponen algunas condiciones de regularización
        
    # Penalización por quantiles demasiado juntos
    n = length(q) + 1
    q_dist = n < 10 ? T(0.025) : T(0.01)
    for i in 1:length(q)-1
        # Si la diferencia es menor a q_dist se impone penalización 
        if abs(q[i+1] - q[i]) < q_dist
            penalty += 5 * abs(q[i+1] - q[i])
        end
    end

    # Imponer una penalización más pequeña por alejarse demasiado de la
    # distribución uniforme de cuantiles. lambda controla la relación entre la
    # penalización y la función objetivo. Si lambda → ∞, la solución debería ser
    # la distribución uniforme
    unif_q = 1/n:1/n:(n-1)/n
    penalty += T(lambda * sqrt(sum(x->x^2, unif_q - q)))

    # Imponer una penalización por el primer cuantil muy pequeño y el último
    # cuantil muy grande
    penalty += T(lambda * (abs(0.5 - first(q)) + abs(last(q) - 0.5)) / 2)

    # Crear configuración de evaluación
    inflfn = InflationCoreMai(maimethod(T[0, q..., 1]))

    # Evaluar la medida y obtener métrica de evaluación 
    tray_infl = pargentrayinfl(inflfn, resamplefn, trendfn, evaldata; K)
    metrics = eval_metrics(tray_infl, tray_infl_param)
    obj = metrics[metric]
    s*obj + penalty
end

# Función para optimización de método en `method` con n segmentos 
function optimizemai(n, method, resamplefn, trendfn, dataeval, tray_infl_param; 
    savepath = nothing, # Ruta de guardado de resultados de optimización 
    K = 10_000, # Número de simulaciones por defecto 
    qstart = nothing, # Puntos iniciales, por defecto distribución uniforme 
    init = :random, # ignorado si qstart !== nothing
    backend = :Optim,
    x_abstol = 1e-4, 
    f_abstol = 1e-4, 
    g_tol = 1e-4,
    maxiterations = 100, 
    maxtime = 60*5, # ignorado con backend == :Optim 
    metric = :mse, 
    lambda = 0.1
    )

    T = backend == :Optim ? eltype(dataeval) : Float64

    # Puntos iniciales de búsqueda 
    if isnothing(qstart)
        if init == :uniform 
            q0 = collect(T, 1/n:1/n:(n-1)/n)
        elseif init == :random 
            q0 = rand(T, n-1) 
        else
            error("El argumento init debe ser :uniform o :random")
        end
        @info "Punto inicial: " q0
    else
        q0 = convert.(T, qstart)
    end

    # Función cerradura 
    maifn = q -> evalmai(q, method, resamplefn, trendfn, dataeval, 
        tray_infl_param; K, metric, lambda)

    if backend == :Optim 

        # Se dejan los límites entre 0 y 1 y las restricciones de orden e
        # interioridad se delegan a evalmai
        qinf, qsup = zeros(T, n), ones(T, n)

        # Optim
        optres = optimize(
            maifn, # Función objetivo 
            qinf, qsup, # Límites
            q0, # Punto inicial
            NelderMead(), # Método
            Optim.Options(
                x_abstol = x_abstol, f_abstol = f_abstol, g_tol = g_tol, 
                show_trace = true, extended_trace=true, 
                iterations = maxiterations, time_limit=maxtime))

        argmin_fn = Optim.minimizer
        min_fn = minimum

    elseif backend == :BlackBoxOptim

        T = Float64

        # BlackBoxOptim
        optres = bboptimize(
            maifn, # Función objetivo 
            q0; # Punto inicial
            SearchRange = (0., 1.), 
            NumDimensions = n-1, 
            TraceMode = :verbose, 
            MaxSteps = maxiterations,
            MaxTime = maxtime
        )

        argmin_fn = BlackBoxOptim.best_candidate
        min_fn = BlackBoxOptim.best_fitness
    else 
        error("El argumento backend debe ser :Optim o :BlackBoxOptim")
    end

    @info "Resultados de optimización:" optres
    
    results = Dict(
        "method" => string(method), 
        "n" => n, 
        "q" => argmin_fn(optres), 
        string(metric) => min_fn(optres),
        "K" => K,
        "optres" => optres
    )

    # Guardar los resultados 
    if !isnothing(savepath)
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

    optimizemai(config[:mainseg], config[:maimethod], 
        resamplefn, trendfn, dataeval, tray_infl_param; options...)

end
