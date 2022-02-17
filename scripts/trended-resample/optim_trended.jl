using DrWatson
@quickactivate "HEMI"
using Plots
using DataFrames
using Chain
using PrettyTables
using Optim


## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI


# Fronteras para instancias
BOUNDS(x::Union{InflationTrimmedMeanEq, InflationTrimmedMeanWeighted}) = [[0,0],[100,100]]
BOUNDS(x::Union{InflationPercentileEq, InflationPercentileWeighted}) = [[0], [1]]
BOUNDS(x::InflationDynamicExclusion) = [[0,0],[5,5]]

# Fronteras para constructores
BOUNDS(x::Union{Type{InflationTrimmedMeanEq}, Type{InflationTrimmedMeanWeighted}}) = [[0,0],[100,100]]
BOUNDS(x::Union{Type{InflationPercentileEq}, Type{InflationPercentileWeighted}}) = [[0], [1]]
BOUNDS(x::Type{InflationDynamicExclusion}) = [[0,0],[5,5]]

# Iniciales para instancias
INITIAL(x::Union{InflationTrimmedMeanEq, InflationTrimmedMeanWeighted}) = [25.0, 75.0]
INITIAL(x::Union{InflationPercentileEq, InflationPercentileWeighted}) = [0.5]
INITIAL(x::InflationDynamicExclusion) = [2.0,2.0]

# Iniciales para constructores
INITIAL(x::Union{Type{InflationTrimmedMeanEq}, Type{InflationTrimmedMeanWeighted}}) = [25.0, 75.0]
INITIAL(x::Union{Type{InflationPercentileEq}, Type{InflationPercentileWeighted}}) = [0.5]
INITIAL(x::Type{InflationDynamicExclusion}) = [2.0,2.0]


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
    bounds = BOUNDS(inflfn)

    if inside(k, bounds)
        if measure == :mse
            mse = eval_mse_online(inflfn, 
            resamplefn, trendfn, data, 
            tray_infl_param; K)
            return mse
        elseif measure == :absme
            mse = eval_absme_online(inflfn, 
            resamplefn, trendfn, data, 
            tray_infl_param; K)
            return mse
        elseif measure == :corr
            corr = eval_corr_online(inflfn, 
            resamplefn, trendfn, data, 
            tray_infl_param; K)
            # se retorna el negativo porque buscamos maximizar la correlacion
            return -corr 
        end
    else
        return 1_000 + sum(abs.(k .- INITIAL(inflfn)))
    end
end


function optimize_config(config, data;
    savepath = nothing,
    measure = :mse,
    x_tol=1e-1, 
    f_tol=1e-2,
    maxiterations = 100,
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
    f = k -> eval_config(k, config, evaldata, tray_infl_param; K=config[:nsim], measure)

    if infl_constructor<:Union{InflationPercentileEq, InflationPercentileWeighted}
        # optres =  optimize(f, 0.5f0, 0.8f0, Brent(), Optim.Options(iterations=maxiterations, x_tol= x_tol, f_tol=f_tol))
        optres =  optimize(f, 0.5f0, 0.8f0)

    elseif infl_constructor<:Union{InflationTrimmedMeanEq, InflationTrimmedMeanWeighted, InflationDynamicExclusion}
        optres = optimize(f, bounds[1], bounds[2], x0, NelderMead(), Optim.Options(iterations=maxiterations, x_tol= x_tol, f_tol=f_tol))

    end

    if measure == :mse
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
    elseif measure == :absme
        @info "Resultados de optimización:" min_absme=minimum(optres) minimizer=Optim.minimizer(optres)  iterations=Optim.iterations(optres)
        
        # Guardar resultados de optimización
        results = Dict(
            # Resultados de optimización 
            "k" => Optim.minimizer(optres), 
            "absme" => minimum(optres),
            # Parámetros para evaluación completa 
            "param" => config[:paramfn].period,
            "optres" => optres
        )
    elseif measure == :corr
        @info "Resultados de optimización:" max_corr=-minimum(optres) minimizer=Optim.minimizer(optres)  iterations=Optim.iterations(optres)
        
        # Guardar resultados de optimización
        results = Dict(
            # Resultados de optimización 
            "k" => Optim.minimizer(optres), 
            "corr" => -minimum(optres),
            # Parámetros para evaluación completa 
            "param" => config[:paramfn].period,
            "optres" => optres
        )
    end
    merge!(results, tostringdict(config))

    # Guardar los resultados de evaluación para collect_results 
    filename = savename(results, "jld2", allowedtypes=(Real, String, Date), digits=4)
    isnothing(savepath) || wsave(joinpath(savepath, filename), tostringdict(results))

    return optres 
end



        
D = dict_list(Dict(
    :infltypefn => [InflationPercentileEq, 
                    InflationPercentileWeighted, 
                    #=InflationTrimmedMeanEq, InflationTrimmedMeanWeighted, 
                    InflationDynamicExclusion=#],
    :resamplefn => ResampleScrambleTrended(0.7036687156959144),
    :trendfn => TrendIdentity(),
    :paramfn => InflationTotalRebaseCPI(36,2),
    :nsim => 100,
    :traindate => Date(2018, 12))
)

# M = [:mse, :absme, :corr]
M = [:mse]
L = []

for m in M
    for config in D
        optres = optimize_config(config, GTDATA; measure = m)
        append!(L,[[config[:infltypefn], m, optres.minimizer, optres.minimum]])
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






    


