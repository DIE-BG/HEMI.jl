using DrWatson 
@quickactivate :HEMI 

using HEMI 
using DataFrames, Chain
using Plots

## Path 
plots_savepath = mkpath(plotsdir("paper", "appendix"))

## Helper functions 
include("appendix-helpers.jl")

## Historical data used
data = GTDATA[Date(2021, 12)]

## Load optimal combination measure for Guatemala
include(scriptsdir("mse-combination", "optmse2022.jl"))

## Plot optimal combination measure vs CPI inflation 

dates = infl_dates(data)
date_ticks = first(dates):Month(24):last(dates)
date_str = Dates.format.(date_ticks, dateformat"Y-m")

# DataFrame for index, monthly price-index change and 12-month change rate for optimal inflation estimator
df_obs_optmse = DataFrame(
    dates = dates[1] - Month(11): Month(1) : dates[end],
    i_optmse = optmse2022(data, CPIIndex()), 
    m_optmse = optmse2022(data, CPIVarInterm()), 
    a_optmse = vcat(fill(missing, 11), optmse2022(data))
)

# Compute confidence interval limits with quantiles from the simulation error distribution
df_obs_optmse_ci = get_ci(df_obs_optmse, optmse2022_ci)


## Create a base plot with headline CPI inflation
bp = plot(InflationTotalCPI(), data,
    label = "Headline CPI inflation",
    ylabel = "% change, year-on-year",
    linewidth = 2, 
    guidefontsize = 8,
    xticks = (date_ticks, date_str),
    xrotation = 45
)

## Create the optimal combination plot

p1 = plot(bp, optmse2022, data, 
    label = "Combination of core measures", 
    linewidth = 3,
    palette = :darkrainbow,
) 

# Plot confidence intervals
plot!(
    p1, 
    df_obs_optmse.dates[12:end], 
    df_obs_optmse_ci.inf_limit[12:end], # 97.5% CI lower limit
    label = "97.5% Confidence interval for trend inflation",
    linestyle = :dot, 
    linewidth = 2, 
    color = :blue, 
    alpha = 0.8,
)

plot!(
    p1, 
    df_obs_optmse.dates[12:end], 
    df_obs_optmse_ci.sup_limit[12:end], # 97.5% CI upper limit
    label = false,
    linestyle = :dot, 
    linewidth = 2, 
    color = :blue, 
    alpha = 0.8,
)

hline!(p1, [0], 
    label = false, 
    color = :gray,
    linealpha = 0.5, 
    linestyle = :dash
)

##  Combination components vs CPI inflation 

nonfx = [!(inflfn isa InflationFixedExclusionCPI) for inflfn in optmse2022.ensemble.functions]
core_measures = InflationEnsemble(optmse2022.ensemble.functions[nonfx])

# Historically expanded sample

p2 = plot(bp, core_measures, GTDATA, 
    label = ["Percentile 72%" "Weighted Percentile 70%" "Trimmed Mean (58.7%, 83.1%)" "Weighted Trimmed Mean (21%, 96%)" "Std. deviations exclusion (0.3, 1.7)" "HES Core inflation"], # "Fixed exclusion (14, 14)" 
    linewidth = 2,
    linealpha = 0.9,
    # linestyle = :auto, 
    # linealpha = 0.5
    # palette = palette([:green, :blue], 7),
    # palette = :Dark2_5,
    palette = :darkrainbow,
    xticks = (date_ticks, ["" for _ in date_ticks])
)
hline!(p2, [0], 
    label = false, 
    color = :gray,
    linealpha = 0.5, 
    linestyle = :dash
)



## Combine plots 

plot(p2, p1,
    left_margin=2*Plots.mm,
    layout = (2, 1),
    size = (800, 600)
)

savefig(joinpath(plots_savepath, "mse_core_measures.pdf"))