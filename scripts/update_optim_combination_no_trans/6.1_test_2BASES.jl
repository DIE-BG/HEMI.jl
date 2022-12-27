using DrWatson
@quickactivate "HEMI"

using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI


data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")

########################
#### GTDATA_EVAL #######
########################

gtdata_eval = NOT_GTDATA[Date(2021, 12)]

#########################################################################################
############# DEFINIMOS PARAMETROS ######################################################
#########################################################################################

# PARAMETRO HASTA 2021
param = InflationParameter(
    InflationTotalRebaseCPI(36, 2), 
    ResampleScrambleVarMonths(), 
    TrendRandomWalk()
)

# PARAMETRO HASTA 2019 (para evaluacion en periodo de optimizacion de medidas individuales)
param_2019 = InflationParameter(
    InflationTotalRebaseCPI(36, 2), 
    ResampleScrambleVarMonths(), 
    TrendRandomWalk()
)

# TRAYECOTRIAS DE LOS PARAMETROS 
tray_infl_pob      = param(gtdata_eval)
tray_infl_pob_19   = param_2019(gtdata_eval[Date(2019,12)])

#############################################################################
#############################################################################

a = Date(2011,01)
b = Date(2011,11)

c = Date(2021,01)
d = Date(2021,11)

perc1 = InflationPercentileEq(72)
perc2 = InflationPercentileEq(76)
perc3 = InflationPercentileEq(78)

W = Splice(perc1,perc2, a, b)


############################################

function ramp_up(X::AbstractRange{T}, a::T, b::T) where T 
    A = min(a,b) 
    B = max(a,b)
    [x<A ? 1 : A<=x<=B ? (findfirst( X .== x)-findfirst( X .== A))/(findfirst( X .== B)-findfirst( X .== A)) : 0 for x in X]
end

function ramp_down(X::AbstractRange{T}, a::T, b::T) where T 
    1 .- ramp_up(X::AbstractRange{T}, a::T, b::T)
end

function cpi_dates(cst::CountryStructure) 
    first(cst.base).dates[1]:Month(1):last(cst.base).dates[end]
end

Base.@kwdef struct Splice <: InflationFunction
    f::InflationFunction
    g::InflationFunction
    a::Date
    b::Date
end

function (inflfn::Splice)(cs::CountryStructure, ::CPIVarInterm)
    f = inflfn.f
    g = inflfn.g
    a = inflfn.a
    b = inflfn.b

    X = cpi_dates(cs)
    F = ramp_up(X,a,b)
    G = ramp_down(X,a,b)
    OUT = (f(cs, CPIIndex()) |> varinterm).*F .+ (g(cs, CPIIndex())|> varinterm) .* G 
    OUT 
end

function (inflfn::Splice)(cs::CountryStructure)
    cpi_index = inflfn(cs, CPIIndex())
    varinteran(cpi_index)
end

function (inflfn::Splice)(cs::CountryStructure, ::CPIIndex)
    v_interm = inflfn(cs, CPIVarInterm())
    capitalize!(v_interm, 100) 
    v_interm  
end

function measure_name(inflfn::Splice)
    return measure_name(inflfn.f)*" -> "*measure_name(inflfn.g)
end

function measure_tag(inflfn::Splice)
    return measure_tag(inflfn.f)*" -> "*measure_tag(inflfn.g)
end


# function measure_tag(combfn::CombinationFunction)
#     isnothing(combfn.tag) || return combfn.tag
#     "COMBFN"
# end

# function components(inflfn::EnsembleFunction)
#     DataFrame(measure = measure_name(inflfn))
# end








config = SimConfig(
    inflfn = W,
    resamplefn = ResampleScrambleVarMonths(),
    trendfn = TrendRandomWalk(),
    paramfn = InflationTotalRebaseCPI(36, 2),
    nsim = 100,
    traindate = Date(2021, 12),
)

results, tray_infl = makesim(gtdata_eval, config)



config = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 2),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :traindate => Date(2021, 12),
    :nsim => 100,
    :inflfn => W
)


function run_batch_splice(data, dict_list_params, splice; 
    savetrajectories = true, 
    rndseed = InflationEvalTools.DEFAULT_SEED)
    a = splice.a
    b = splice.b

    X = infl_dates(data)
    F = ff(X,a,b)
    G = ramp_down(X,a,b)

    TRAY = Dict()


    # Ejecutar lote de simulaciones 
    for (i, dict_params) in enumerate(dict_list_params)
        @info "Ejecutando simulación $i de $(length(dict_list_params))..."
        config = dict_config(dict_params)
        results, TRAY[string(i)] = makesim(data, config;
            rndseed = rndseed)
        print("\n\n\n") 
        
        # Guardar los resultados 
        #filename = savename(config, "jld2")
        
        # Resultados de evaluación para collect_results 
        #wsave(joinpath(savepath, filename), tostringdict(results))
        
        # Guardar trayectorias de inflación, directorio tray_infl de la ruta de guardado
        #savetrajectories && wsave(joinpath(savepath, "tray_infl", filename), "tray_infl", tray_infl)
    end

    tray_infl = TRAY["1"] .* F + TRAY["2"] .* G
    tray_infl

end


