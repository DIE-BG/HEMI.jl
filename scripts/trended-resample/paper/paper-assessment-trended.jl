using DrWatson 
@quickactivate :HEMI 

## Load parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI

## Helper packages
using DataFrames, Chain, PrettyTables
using Plots

# Results' folder
savepath = datadir("results", "paper-assessment-trended")

## TIMA settings 

# Resampling technique, parametric inflation formula and trend function 
paramfn = InflationTotalRebaseCPI(60)
resamplefn = ResampleScrambleTrended(0.46031723899305166) 
trendfn = TrendIdentity()

# Inflation excluding food & energy: indexes to exclude for every CPI dataset
# Specification in the form of ([CPI 2000 specification], [CPI 2010 specification])
core_specs = (
    vcat(collect(23:41), 104, 159), 
    vcat(collect(22:48), 116, collect(184:186)),
)

# Inflation estimators to assess 
inflfns = [
    InflationTotalCPI(), 
    InflationFixedExclusion(core_specs),
    InflationFixedExclusionCPI(core_specs),
    InflationTrimmedMeanEq(24, 31),
    InflationTrimmedMeanEq(8, 92),
    InflationTrimmedMeanWeighted(24, 31),
    InflationTrimmedMeanWeighted(8, 92),
    InflationTrimmedMeanEq(25, 95),
    InflationTrimmedMeanWeighted(25, 95),
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

run_batch(GTDATA, assessment_config, savepath)


## Analyze the results

df_results = collect_results(savepath)
# prefix = "gt_b10_"
prefix = "" # Empty means metrics over the full historical data

main_results = @chain df_results begin 
    select(:measure, Symbol(prefix, :mse), Symbol(prefix, :mse_std_error))
end

# Additive decomposition of mean square error
mse_decomp = @chain df_results begin 
    select(:measure, Symbol(prefix, :mse_bias), Symbol(prefix, :mse_var), Symbol(prefix, :mse_cov), Symbol(prefix, :mse), Symbol(prefix, :mse_std_error))
end

# Other sensitivity assessment metrics 
sens_metrics = @chain df_results begin 
    select(:measure, Symbol(prefix, :rmse), Symbol(prefix, :me), Symbol(prefix, :mae), Symbol(prefix, :huber), Symbol(prefix, :corr))
end 

# Results tables 
pretty_table(main_results, tf=tf_markdown, formatters=ft_round(4))
pretty_table(mse_decomp, tf=tf_markdown, formatters=ft_round(4))
pretty_table(sens_metrics, tf=tf_markdown, formatters=ft_round(4))

pretty_table(main_results, tf=tf_latex_booktabs, formatters=ft_round(4))
pretty_table(mse_decomp, tf=tf_latex_booktabs, formatters=ft_round(4))
pretty_table(sens_metrics, tf=tf_latex_booktabs, formatters=ft_round(4))

