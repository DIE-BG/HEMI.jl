using DrWatson
@quickactivate "HEMI"
using Plots
using DataFrames
using Chain
using PrettyTables
using Optim
using BlackBoxOptim

## Cargar el módulo de Distributed para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI

## Optimización de medidas

# Fronteras para constructores
BOUNDS(::Union{Type{InflationTrimmedMeanEq}, Type{InflationTrimmedMeanWeighted}}) = ([0, 0], [100, 100])
BOUNDS(::Union{Type{InflationPercentileEq}, Type{InflationPercentileWeighted}}) = (0f0, 1f0)
BOUNDS(::Type{InflationDynamicExclusion}) = ([0,0],[5,5])

# Iniciales para constructores
INITIAL(::Union{Type{InflationTrimmedMeanEq}, Type{InflationTrimmedMeanWeighted}}) = [15.0, 75.0]
INITIAL(::Union{Type{InflationPercentileEq}, Type{InflationPercentileWeighted}}) = 0.5f0
INITIAL(::Type{InflationDynamicExclusion}) = [2.0,2.0]


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
    f = k -> eval_config(k, config, evaldata, tray_infl_param; 
        K = config[:nsim], 
        measure)


    if infl_constructor <: Union{InflationPercentileEq, InflationPercentileWeighted}
        @info "Optimizando percentil"
        optres =  optimize(f, first(bounds), last(bounds),
            show_trace = true, 
            iterations = maxiterations,
            abs_tol = f_tol
        )

    elseif infl_constructor <: Union{InflationTrimmedMeanEq, InflationTrimmedMeanWeighted, InflationDynamicExclusion}
        options = Optim.Options(
            iterations=maxiterations, 
            x_tol=x_tol, 
            f_tol=f_tol, 
            g_tol = g_tol,
            show_trace=true
        )
        optres = optimize(f, bounds[1], bounds[2], x0, NelderMead(), options)

        # BlackBoxOptim      
        # lowerbounds = first(bounds)
        # upperbounds = last(bounds)
        # optres = bboptimize(f, 
        #     SearchRange = [(1.0*lowerbounds[1], 1.0*upperbounds[1]), (1.0*lowerbounds[2], 1.0*upperbounds[2])], 
        #     MaxSteps = maxiterations, 
        #     TraceMode = :verbose
        # )

    end

    s = measure == :corr ? -1 : 1

    # Guardar resultados de optimización
    # @info "Resultados de optimización:" min_mse=(s*minimum(optres)) minimizer=Optim.minimizer(optres)  iterations=Optim.iterations(optres)
    @info "Resultados de optimización:" optres minimizer=s*Optim.minimizer(optres)
    results = Dict(
        # Resultados de optimización 
        "measure" => measure, 
        "minimizer" => Optim.minimizer(optres), 
        "optimal" => s * minimum(optres),
        "optres" => optres
    )
    
    merge!(results, tostringdict(config))

    # Guardar los resultados de evaluación para collect_results 
    filename = savename(results, "jld2", allowedtypes=(Real, String, Date), digits=4)
    isnothing(savepath) || wsave(joinpath(savepath, filename), tostringdict(results))

    return results 
end



# D = dict_list(Dict(
#     :infltypefn => [
#         InflationPercentileEq, 
#         # InflationPercentileWeighted, 
#         # InflationTrimmedMeanEq, 
#         # InflationTrimmedMeanWeighted, 
#         # InflationDynamicExclusion,
#     ],
#     :resamplefn => ResampleScrambleVarMonths(),
#     :trendfn => TrendRandomWalk(),
#     :paramfn => InflationTotalRebaseCPI(36,2),
#     :nsim => 1_000,
#     :traindate => Date(2018, 12))
# )

# M = [:mse, :absme, :corr]
# M = [:corr]
# L = []

# for measure in M
#     for config in D
#         optres = optimize_config(config, gtdata; measure)
#         append!(L,[[optres["infltypefn"], optres["measure"], optres["minimizer"], optres["optimal"]]])
#     end
# end

# Any[InflationPercentileEq, :mse, [0.7210045547824011], 0.24700935184955597]
# Any[InflationPercentileWeighted, :mse, [0.6998386187981225], 0.4105831980705261]
# Any[InflationTrimmedMeanEq, :mse, [36.72307586669922, 93.14410705566405], 0.2534305155277252]
# Any[InflationTrimmedMeanWeighted, :mse, [19.872332376660154, 96.09916358738384], 0.304605096578598]
# Any[InflationDynamicExclusion, :mse, [0.32419247378859517, 1.7303702375793537], 0.3035299479961395]
# Any[InflationPercentileEq, :absme, [0.7163444234931969], 0.1509493887424469]
# Any[InflationPercentileWeighted, :absme, [0.695585302919685], 0.18557241559028625]
# Any[InflationTrimmedMeanEq, :absme, [35.288126659393306, 93.40091190338134], 0.00016758497804403305]
# Any[InflationTrimmedMeanWeighted, :absme, [34.19426586867722, 92.59037122656505], 7.30506144464016e-8]
# Any[InflationDynamicExclusion, :absme, [1.031949377043252, 3.423655131735717], 1.5308614820241928e-8]
# Any[InflationPercentileEq, :corr, [0.7725222386666464], -0.9840638637542725]
# Any[InflationPercentileWeighted, :corr, [0.8095570179714271], -0.973701536655426]
# Any[InflationTrimmedMeanEq, :corr, [55.90512060523032, 92.17767125368118], -0.9857175350189209]
# Any[InflationTrimmedMeanWeighted, :corr, [46.44323324480888, 98.54608364886394], -0.9776228070259094]
# Any[InflationDynamicExclusion, :corr, [0.46832260901857126, 4.974514492691691], -0.9767531156539917]
