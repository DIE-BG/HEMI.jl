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
INITIAL(::Union{Type{InflationTrimmedMeanEq}, Type{InflationTrimmedMeanWeighted}}) = [25.0, 75.0]
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
    maxiterations = 100, 
    maxtime = 5*60,
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
            show_trace=true,
            time_limit = maxtime,
        )
        optres = optimize(f, bounds[1], bounds[2], x0, NelderMead(), options)
        argmin_fn = Optim.minimizer
        min_fn = minimum

        # # BlackBoxOptim
        # T = eltype(data)
        # lowerbounds = T.(first(bounds))
        # upperbounds = T.(last(bounds))
        # optres = bboptimize(f, 
        #     SearchRange = [
        #         (1.0*lowerbounds[1], 1.0*upperbounds[1]), 
        #         (1.0*lowerbounds[2], 1.0*upperbounds[2])
        #     ], 
        #     MaxSteps = maxiterations, 
        #     MaxTime = 10*60,
        #     TraceMode = :verbose,
        # )
        # argmin_fn = BlackBoxOptim.best_candidate
        # min_fn = BlackBoxOptim.best_fitness

    end

    s = measure == :corr ? -1 : 1

    # Guardar resultados de optimización
    @info "Resultados de optimización:" optres minimizer=argmin_fn(optres)
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


## Optimización de medidas
        
D = dict_list(Dict(
    :infltypefn => [
        # InflationPercentileEq, 
        # InflationPercentileWeighted, 
        # InflationTrimmedMeanEq,
        InflationTrimmedMeanWeighted, 
        # InflationDynamicExclusion
    ],
    :resamplefn => ResampleScrambleTrended(0.46031723899305166),
    :trendfn => TrendIdentity(),
    :paramfn => InflationTotalRebaseCPI(36,2),
    :nsim => 1_000,
    :traindate => Date(2018, 12))
)

M = [:mse]
L = []

for measure in M
    for config in D
        optres = optimize_config(config, gtdata; measure, maxtime=10*60)
        append!(L,[[optres["infltypefn"], optres["measure"], optres["minimizer"], optres["optimal"]]])
    end
end

L

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



# Resultados con ResampleScrambleTrended(0.5050245)
# 5-element Vector{Any}:
#  Any[InflationPercentileEq, :mse, [0.5897810191566328], 6.111946105957031]
#  Any[InflationPercentileWeighted, :mse, [0.6866260109007395], 1.0048913955688477]
#  Any[InflationTrimmedMeanEq, :mse, [33.97898127138615, 92.7937470138073], 0.6995201706886292]
#  Any[InflationTrimmedMeanWeighted, :mse, [16.61674875987502, 96.06609858745875], 0.718515157699585]
#  Any[InflationDynamicExclusion, :mse, [0.6946824711747468, 2.4818083385471237], 0.6820622682571411]

# Resultados con (0.5050245)ResampleScrambleTrended(0.7036687156959144)
# 5-element Vector{Any}:
#  Any[InflationPercentileEq, :mse, 0.7122512f0, 0.90292084f0]
#  Any[InflationPercentileWeighted, :mse, 0.68783885f0, 0.8846867f0]
#  Any[InflationTrimmedMeanEq, :mse, [29.390259825438264, 94.08079745918512], 0.8105813264846802]
#  Any[InflationTrimmedMeanWeighted, :mse, [3.688406795488648, 99.08927255341023], 0.3123916983604431]
#  Any[InflationDynamicExclusion, :mse, [1.5180517760790662, 3.6835528914126927], 0.40942177176475525]

# Repetición de 100 simulaciones de estas familias
# 2-element Vector{Any}:
#  Any[InflationTrimmedMeanWeighted, :mse, [3.7399935508043645, 99.08745445245047], 0.3295079469680786]
#  Any[InflationDynamicExclusion, :mse, [1.2463722449397676, 3.2525567985301906], 0.42266032099723816]

# Repetición de 10000 simulaciones de estas familias
# 2-element Vector{Any}:
#  Any[InflationTrimmedMeanWeighted, :mse, [3.688400731807736, 99.08868544455818], 0.31238046288490295]
#  Any[InflationDynamicExclusion, :mse, [1.5210907535757554, 3.698630036432531], 0.4094146490097046]
    


# 2-element Vector{Any}:
#  Any[InflationPercentileEq, :mse, 0.71637434f0, 0.51337427f0]
#  Any[InflationPercentileWeighted, :mse, 0.69379866f0, 0.6089448f0]

# 2-element Vector{Any}:
#  Any[InflationPercentileEq, :mse, 0.71974313f0, 0.378483f0]
#  Any[InflationPercentileWeighted, :mse, 0.6950942f0, 0.5165965f0]


# ResampleScrambleTrended(0.46031723899305166)
# 2-element Vector{Any}:
#  Any[InflationPercentileEq, :mse, 0.7138397f0, 0.40599346f0]
#  Any[InflationPercentileWeighted, :mse, 0.6966889f0, 0.56284577f0]
#  Any[InflationTrimmedMeanEq, :mse, [29.00802047103643, 94.50130153000353], 0.38142937421798706]
#  Any[InflationTrimmedMeanWeighted, :mse, [4.832434872326092, 98.83889276348492], 0.3057722747325897]
#  Any[InflationDynamicExclusion, :mse, [1.0757467269897463, 3.1653048515319826], 0.31025922298431396]
# 2-element Vector{Any}:
#  Any[InflationPercentileEq, :corr, 0.6357774f0, 0.9378004f0]
#  Any[InflationPercentileWeighted, :corr, 0.749609f0, 0.94391954f0]
# 2-element Vector{Any}:
#  Any[InflationPercentileEq, :absme, 0.7190822f0, 0.06812336f0]
#  Any[InflationPercentileWeighted, :absme, 0.6943178f0, 0.07237616f0]


# ResampleTrended([0.5695731554158409, 0.42360815127381435])
# 2-element Vector{Any}:
#  Any[InflationPercentileEq, :mse, 0.71926844f0, 0.5509473f0]
#  Any[InflationPercentileWeighted, :mse, 0.6948931f0, 0.6439236f0]
# 2-element Vector{Any}:
#  Any[InflationPercentileEq, :corr, 0.52632993f0, 0.92612255f0]
#  Any[InflationPercentileWeighted, :corr, 0.4311385f0, 0.9442619f0]
# 2-element Vector{Any}:
#  Any[InflationPercentileEq, :absme, 0.71043175f0, 0.112166494f0]
#  Any[InflationPercentileWeighted, :absme, 0.69290245f0, 0.068588465f0]