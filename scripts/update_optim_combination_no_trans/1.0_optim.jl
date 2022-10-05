using DrWatson
@quickactivate "HEMI"

include(scriptsdir("OPTIM","optim.jl"))

savepath = datadir("results","no-trans","optim")  
data_loadpath = datadir("results", "no-trans", "data", "NOT_data.jld2")

# CARGANDO DATOS
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")

D = dict_list(
    Dict(
        :infltypefn => [
            InflationPercentileEq, 
            InflationPercentileWeighted, 
            InflationTrimmedMeanEq, 
            InflationTrimmedMeanWeighted, 
            InflationDynamicExclusion,
        ],
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :paramfn => InflationTotalRebaseCPI(36,2),
    :nsim => 10_000,
    :traindate => Date(2019, 12)
    )
)

M = [:mse, :absme, :corr]
DF = DataFrame()


for i in 1:length(M)
    for j in 1:length(D)
        save_path = joinpath(savepath,string(M[i]))
        optres = optimize_config(D[j], NOT_GTDATA; measure=M[i], savepath = save_path, x0 = INITIAL(D[j][:infltypefn]))
        merge!(optres, tostringdict(D[j]))
        optres["minimizer"]= Ref(optres["minimizer"])
        global DF = vcat(DF,DataFrame(optres))
    end
end


# ┌──────────────────────────────┬────────┬──────────────────────────────────────────┐
# │                      measure │ metric │                                minimizer │
# │                       String │ Symbol │                                   String │
# ├──────────────────────────────┼────────┼──────────────────────────────────────────┤
# │        InflationPercentileEq │    mse │                               0.71844846 │
# │  InflationPercentileWeighted │    mse │                                0.6933576 │
# │       InflationTrimmedMeanEq │    mse │    [24.70892181396485, 96.2772979736328] │
# │ InflationTrimmedMeanWeighted │    mse │  [11.203421074151988, 99.55240076780314] │
# │    InflationDynamicExclusion │    mse │ [0.8061555862426757, 3.7844088554382327] │
# │        InflationPercentileEq │  absme │                               0.72949016 │
# │  InflationPercentileWeighted │  absme │                                0.6988363 │
# │       InflationTrimmedMeanEq │  absme │  [26.106080627441408, 95.60851745605467] │
# │ InflationTrimmedMeanWeighted │  absme │   [20.10801535271694, 98.15560483228873] │
# │    InflationDynamicExclusion │  absme │  [0.7181243896484375, 4.126136779785157] │
# │        InflationPercentileEq │   corr │                                0.7983739 │
# │  InflationPercentileWeighted │   corr │                               0.82199615 │
# │       InflationTrimmedMeanEq │   corr │                  [16.4109375, 98.453125] │
# │ InflationTrimmedMeanWeighted │   corr │  [31.696093749999996, 96.10781249999998] │
# │    InflationDynamicExclusion │   corr │                    [0.846875, 2.3203125] │
# └──────────────────────────────┴────────┴──────────────────────────────────────────┘