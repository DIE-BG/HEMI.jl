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

for measure in M
    for config in D
        save_path = joinpath(savepath,string(measure))
        optres = optimize_config(config, gtdata; measure, savepath = save_path)
        merge!(optres, tostringdict(config))
        optres["minimizer"]= Ref(optres["minimizer"])
        global DF = vcat(DF,DataFrame(optres))
    end
end

# Row │ infltypefn                    measure  minimizer            nsim   optimal     optres                             paramfn                         resamplefn                   traindate   trendfn
#      │ DataType                      Symbol   Any                  Int64  Float64     Optimiza…                          Inflatio…                       ResampleS…                   Date        TrendRan…
# ─────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
#    1 │ InflationPercentileEq         mse      0.719566             10000  0.244727    Results of Optimization Algorith…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32… 
#    2 │ InflationPercentileWeighted   mse      0.698558             10000  0.410158    Results of Optimization Algorith…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32… 
#    3 │ InflationTrimmedMeanEq        mse      [28.4994, 95.155]    10000  0.346451     * Status: success\n\n * Candida…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32… 
#    4 │ InflationTrimmedMeanWeighted  mse      [20.6086, 95.9818]   10000  0.294047     * Status: success\n\n * Candida…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32… 
#    5 │ InflationDynamicExclusion     mse      [0.403394, 2.10774]  10000  0.29371      * Status: success\n\n * Candida…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32… 
#    6 │ InflationPercentileEq         absme    0.719238             10000  0.0577582   Results of Optimization Algorith…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32… 
#    7 │ InflationPercentileWeighted   absme    0.702267             10000  0.0351598   Results of Optimization Algorith…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32… 
#    8 │ InflationTrimmedMeanEq        absme    [22.1844, 96.0049]   10000  0.00145469   * Status: success\n\n * Candida…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32… 
#    9 │ InflationTrimmedMeanWeighted  absme    [25.1724, 95.0275]   10000  3.70805e-5   * Status: success\n\n * Candida…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32… 
#   10 │ InflationDynamicExclusion     absme    [0.995821, 3.39991]  10000  1.36803e-5   * Status: success\n\n * Candida…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32…   
#   11 │ InflationPercentileEq         corr     0.80865              10000  0.985772    Results of Optimization Algorith…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32…   
#   12 │ InflationPercentileWeighted   corr     0.809951             10000  0.975832    Results of Optimization Algorith…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32…   
#   13 │ InflationTrimmedMeanEq        corr     [33.6361, 95.5215]   10000  0.986206     * Status: success\n\n * Candida…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32…   
#   14 │ InflationTrimmedMeanWeighted  corr     [27.6984, 98.4531]   10000  0.978821     * Status: success\n\n * Candida…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32…   
#   15 │ InflationDynamicExclusion     corr     [0.4625, 4.81875]    10000  0.977993     * Status: success\n\n * Candida…  InflationTotalRebaseCPI(36, 2)  ResampleScrambleVarMonths()  2019-12-01  TrendRandomWalk{Float32}(Float32…   