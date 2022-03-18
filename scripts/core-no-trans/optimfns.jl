# Fronteras para constructores
BOUNDS(::Union{Type{InflationTrimmedMeanEq}, Type{InflationTrimmedMeanWeighted}}) = ([0, 0], [100, 100])
BOUNDS(::Union{Type{InflationPercentileEq}, Type{InflationPercentileWeighted}}) = (0f0, 1f0)
BOUNDS(::Type{InflationDynamicExclusion}) = ([0,0],[5,5])

# Iniciales para constructores
INITIAL(::Union{Type{InflationTrimmedMeanEq}, Type{InflationTrimmedMeanWeighted}}) = [25.0, 75.0]
INITIAL(::Union{Type{InflationPercentileEq}, Type{InflationPercentileWeighted}}) = 0.5f0
INITIAL(::Type{InflationDynamicExclusion}) = [1.0,1.0]


function inside(x, bounds)
    return all(bounds[1] .<= x .<= bounds[2])
end

function eval_config(k, config, data, tray_infl_param; K = 10_000, measure = :mse)

    # Configurar la función de inflación a evaluar
    infl_constructor = config[:infltypefn]
    inflfn = infl_constructor(k)

    # Configuración de remuestreo, tendencia
    resamplefn = config[:resamplefn]
    trendfn = config[:trendfn]

    # obtener los bordes
    bounds = BOUNDS(infl_constructor)

    s = measure == :corr ? -1 : 1 # signo de la métrica
    eval_fn_online = eval(Symbol("eval_", measure, "_online"))

    if inside(k, bounds)
        metric = eval_fn_online(inflfn, 
            resamplefn, trendfn, data, tray_infl_param; 
            K)
        # cuando measure==:corr, se retorna el negativo porque buscamos
        # maximizar la correlacion
        return s * metric
    else
        return 1_000 + sum(abs.(k .- INITIAL(infl_constructor)))
    end
end


function optimize_config(config, data;
    savepath = nothing,
    measure = :mse,
    x_tol=1e-1, 
    f_tol=1e-2,
    g_tol = 1e-4,
    maxiterations = 100
    )

    # Configuración de remuestreo, tendencia y parámetro
    resamplefn = config[:resamplefn]
    trendfn = config[:trendfn]
    paramfn = config[:paramfn]

    # Datos de evaluación 
    evaldata = data[config[:traindate]]

    # Trayectoria paramétrica 
    param = InflationParameter(paramfn, resamplefn, trendfn) 
    tray_infl_param = param(evaldata)

    # Configurar la función de inflación a evaluar
    infl_constructor = config[:infltypefn]

    bounds = BOUNDS(infl_constructor)
    x0     = INITIAL(infl_constructor)

    # Función cerradura 
    f = k -> Float64(eval_config(k, config, evaldata, tray_infl_param; 
        K = config[:nsim], 
        measure))


    if infl_constructor <: Union{InflationPercentileEq, InflationPercentileWeighted}
        @info "Optimizando percentil"
        optres =  optimize(f, first(bounds), last(bounds),
            show_trace = true, 
            iterations = maxiterations,
            abs_tol = f_tol
        )

    elseif infl_constructor <: Union{InflationTrimmedMeanEq, InflationTrimmedMeanWeighted, InflationDynamicExclusion}
        # Optim
        options = Optim.Options(
            iterations=maxiterations, 
            x_tol=x_tol, 
            f_tol=f_tol, 
            g_tol = g_tol,
            show_trace=true
        )
        optres = optimize(f, bounds[1], bounds[2], x0, NelderMead(), options)
        argmin_fn = Optim.minimizer
        min_fn = minimum

        # # BlackBoxOptim      
        # lowerbounds = first(bounds)
        # upperbounds = last(bounds)
        # optres = bboptimize(f, 
        #     SearchRange = [(1.0*lowerbounds[1], 1.0*upperbounds[1]), (1.0*lowerbounds[2], 1.0*upperbounds[2])], 
        #     MaxSteps = maxiterations, 
        #     TraceMode = :verbose
        # )
        # argmin_fn = BlackBoxOptim.best_candidate
        # min_fn = BlackBoxOptim.best_fitness

    end

    s = measure == :corr ? -1 : 1

    # Guardar resultados de optimización
    @info "Resultados de optimización:" optres
    results = Dict(
        # Resultados de optimización 
        "measure" => measure, 
        "minimizer" => argmin_fn(optres),
        "optimal" => s * min_fn(optres),
        "optres" => optres
    )
    
    merge!(results, tostringdict(config))

    # Guardar los resultados de evaluación para collect_results 
    filename = savename(results, "jld2", allowedtypes=(Real, String, Date), digits=4)
    isnothing(savepath) || wsave(joinpath(savepath, filename), tostringdict(results))

    return results 
end
