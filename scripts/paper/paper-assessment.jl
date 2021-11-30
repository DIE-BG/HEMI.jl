using DrWatson 
@quickactivate :HEMI 

## Load parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI

## Helper packages
using DataFrames, Chain, PrettyTables


## TIMA settings 

# Resampling technique, parametric inflation formula and trend function 
paramfn = InflationTotalRebaseCPI(60)
resamplefn = ResampleScrambleVarMonths() 
trendfn = TrendRandomWalk()

# Inflation excluding food & energy: indexes to exclude for every CPI dataset
core_spec = (vcat(collect(23:41), 104, 159), vcat(collect(22:48), 116, collect(184:186)))

# Inflation estimators to assess 
inflfns = [
    InflationTotalCPI(), 
    InflationFixedExclusion(core_spec),
    InflationFixedExclusionCPI(core_spec),
    InflationTrimmedMeanEq(24, 31),
    InflationTrimmedMeanEq(8, 92),
    InflationTrimmedMeanWeighted(24, 31),
    InflationTrimmedMeanWeighted(8, 92),
    InflationPercentileEq(50),
    InflationPercentileWeighted(50),
    InflationPercentileEq(70),
    InflationPercentileWeighted(70)
]

# Simulation configuration 
assessment_config = Dict(
    :inflfn => inflfns, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => Date(2020, 12),
    :nsim => 125_000) |> dict_list

println("Configuration has $(length(assessment_config)) entries")


## Run the simulation

savepath = datadir("results", "paper-assessment")
run_batch(gtdata, assessment_config, savepath)


## Analyze the results

df_results = collect_results(savepath)

main_results = @chain df_results begin 
    select(:measure, :mse, :mse_std_error)
end

# Descomposición aditiva del MSE 
mse_decomp = @chain df_results begin 
    select(:measure, :mse, :mse_bias, :mse_var, :mse_cov)
end

# Otras métricas de evaluación 
sens_metrics = @chain df_results begin 
    select(:measure, :rmse, :me, :mae, :huber, :corr)
end 


pretty_table(main_results, tf=tf_markdown, formatters=ft_round(4))
pretty_table(mse_decomp, tf=tf_markdown, formatters=ft_round(4))
pretty_table(sens_metrics, tf=tf_markdown, formatters=ft_round(4))