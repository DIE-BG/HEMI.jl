using DrWatson
@quickactivate :HEMI 
using Optim
using BlackBoxOptim

## Cargar el módulo de Distributed para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI


## CountryStructure con datos de no transables 
data_savepath = datadir("results", "core-no-trans", "data", "NOT_data.jld2")
NOT_GTDATA = load(data_savepath, "NOT_GTDATA")

## Funciones de optimización
includet(scriptsdir("core-no-trans", "optimfns.jl"))

## Optimize core measures for non-tradeable
D = dict_list(Dict(
    :infltypefn => [
        InflationPercentileEq, 
        InflationPercentileWeighted, 
        InflationTrimmedMeanEq, 
        InflationTrimmedMeanWeighted, 
        InflationDynamicExclusion,
    ],
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :paramfn => InflationWeightedMean(),
    # :paramfn => InflationTotalRebaseCPI(36,3),
    :nsim => 5_000,
    :traindate => Date(2020, 12))
)

M = [:mse]
L = []

for measure in M
    for config in D
        optres = optimize_config(config, NOT_GTDATA; measure)
        append!(L,[[optres["infltypefn"], optres["measure"], optres["minimizer"], optres["optimal"]]])
    end
end

L
# Any[InflationPercentileEq, :mse, 0.763932f0, 0.07814352f0]
# Any[InflationPercentileWeighted, :mse, 0.7446913f0, 0.16098607f0]
# Any[InflationTrimmedMeanEq, :mse, [24.053515624999996, 97.28046874999998], 0.0535307377576828]
# Any[InflationTrimmedMeanWeighted, :mse, [38.29931976795197, 97.911387014389], 0.08694036304950714]
# Any[InflationDynamicExclusion, :mse, [0.30716660097241405, 2.9402031447738386], 0.1482466459274292]
