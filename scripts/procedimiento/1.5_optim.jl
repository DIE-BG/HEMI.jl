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
#DF = DataFrame()

for measure in M
    for config in D
        save_path = joinpath(savepath,string(measure))
        optres = optimize_config(config, gtdata; measure, savepath = save_path)
        #merge!(optres, tostringdict(config))
        #optres["minimizer"]= Ref(optres["minimizer"])
        #global DF = vcat(DF,DataFrame(optres))
    end
end

