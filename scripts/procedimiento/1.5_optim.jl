using DrWatson
@quickactivate "HEMI"

include(scriptsdir("OPTIM","optim.jl"))

savepath = datadir("results","optim")  

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

# OPTIMOS DE 2022 COMO VALOR INICIAL
X0 = [
    [
       0.72,
       0.69,
        [58.0, 83.0],
       [21.0, 95.0],
       [0.31, 1.68]
    ]
,
   [
       0.71,
        0.69,
        [35.0, 93.0],
        [34.0, 93.0],
        [1.00, 3.42]

    ]
,
    [
        0.77,
        0.80,
        [55.0, 92.0],
        [46.0, 98.0],
        [0.46, 4.97]

    ]
]

for i in 1:length(M)
    for j in 1:length(D)
        save_path = joinpath(savepath,string(M[i]))
        optres = optimize_config(D[j], gtdata; measure=M[i], savepath = save_path, x0 = X0[i][j])
        merge!(optres, tostringdict(D[j]))
        optres["minimizer"]= Ref(optres["minimizer"])
        global DF = vcat(DF,DataFrame(optres))
    end
end

# ┌──────────────────────────────┬────────┬──────────────────────────────────────────┐
# │                      measure │ metric │                                minimizer │
# │                       String │ Symbol │                                   String │
# ├──────────────────────────────┼────────┼──────────────────────────────────────────┤
# │        InflationPercentileEq │    mse │                                0.7195656 │
# │  InflationPercentileWeighted │    mse │                               0.69855756 │
# │       InflationTrimmedMeanEq │    mse │   [63.41218886971474, 79.85745657682418] │
# │ InflationTrimmedMeanWeighted │    mse │    [20.51299431324005, 95.9781690120697] │
# │    InflationDynamicExclusion │    mse │ [0.33728042602539066, 1.810945816040039] │
# │        InflationPercentileEq │  absme │                                0.7192383 │
# │  InflationPercentileWeighted │  absme │                                0.7022669 │
# │       InflationTrimmedMeanEq │  absme │    [33.4117166519165, 93.73476219177246] │
# │ InflationTrimmedMeanWeighted │  absme │   [32.16439493456855, 93.25685444604606] │
# │    InflationDynamicExclusion │  absme │    [1.04827364012599, 3.488850908577442] │
# │        InflationPercentileEq │   corr │                               0.80864954 │
# │  InflationPercentileWeighted │   corr │                               0.80995136 │
# │       InflationTrimmedMeanEq │   corr │                             [55.0, 92.0] │
# │ InflationTrimmedMeanWeighted │   corr │              [53.555078125, 96.46796875] │
# │    InflationDynamicExclusion │   corr │                             [0.46, 4.97] │
# └──────────────────────────────┴────────┴──────────────────────────────────────────┘