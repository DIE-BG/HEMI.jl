using DrWatson
@quickactivate :HEMI

using DataFrames
using Chain
using PrettyTables
using CSV
using Plots

## Path 
comp_results_savepath = datadir("results", "mse-combination", "optmse2022-components")
mai_results_savepath = datadir("results", "mse-combination", "optmse2022-mai-components")
plots_savepath = mkpath(plotsdir("paper", "mse-combination"))

# Load optimal linear combination of inflation measures
#     exports optmai2018 and optmse2022
include(scriptsdir("mse-combination", "optmse2022.jl"))

## TIMA settings 

# Here we use synthetic base changes every 36 months, because this is the population trend 
# inflation time series used in the optimization of the Optimal Linear MSE Combination 2022

# Resampling technique, parametric inflation formula and trend function 
paramfn = InflationTotalRebaseCPI(36, 2)
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()

# CPI data
data = GTDATA[Date(2020, 12)]
dates = infl_dates(data)
date_ticks = first(dates):Month(24):last(dates)
date_str = Dates.format.(date_ticks, dateformat"Y-m")

# Population trend inflation series
param = InflationParameter(paramfn, resamplefn, trendfn)
trend_infl = param(data)

## Collect results os assessment
df_results = collect_results(joinpath(results_savepath))
sort!(df_results, :mse)

@chain df_results begin
    select(:measure, :mse_bias, :mse_var, :mse_cov, :mse, :mse_std_error)
end

# Get the cube of trajectories to combine and obtain weights
tray_infl = mapreduce(hcat, df_results.path) do path
    # Load array of trajectories for each measure
    tray_path = joinpath(dirname(path), "tray_infl", basename(path))
    @info "Loading trajectories file" tray_path
    load(tray_path, "tray_infl")
end

## Get unrestricted optimal weights, excluding fixed-exclusion method

# Mask for the combination weight in the period Dec-11 to Dec-20
combination_period = EvalPeriod(Date(2011, 12), Date(2020, 12), "combperiod")
# combination_period = CompletePeriod() 
periods_mask = eval_periods(data, combination_period)

# Mask to exclude fixed-exclusion method
components_mask = [!(fn isa InflationFixedExclusionCPI) for fn in df_results.inflfn]

unrestricted_weights = combination_weights(
    tray_infl[periods_mask, components_mask, :], 
    trend_infl[periods_mask]
)

unrestricted_combination = InflationCombination(
    [df_results.inflfn[components_mask]..., df_results.inflfn[.!components_mask]...]...,
    [unrestricted_weights..., 0],
    "Unrestricted linear MSE combination",
    "UNCOMBMSE",
)

restricted_weights = share_combination_weights(
    tray_infl[periods_mask, components_mask, :], 
    trend_infl[periods_mask]
)

restricted_combination = InflationCombination(
    [df_results.inflfn[components_mask]..., df_results.inflfn[.!components_mask]...]...,
    [restricted_weights..., 0],
    "Restricted linear MSE combination",
    "RESTCOMBMSE",
)

## Compute evaluation results for the unrestricted combination

unrest_tray_infl = sum(tray_infl .* [unrestricted_weights..., 0]'; dims=2)
unrest_eval = eval_metrics(unrest_tray_infl[periods_mask, :, :], trend_infl[periods_mask])
unrest_eval = eval_metrics(unrest_tray_infl, trend_infl)

@chain unrest_eval begin 
    DataFrame
    select(:mse_bias, :mse_var, :mse_cov, :mse, :mse_std_error)
end

## Compute evaluation results for the restricted combination

rest_tray_infl = sum(tray_infl .* [restricted_weights..., 0]'; dims=2)
rest_eval = eval_metrics(rest_tray_infl[periods_mask, :, :], trend_infl[periods_mask])
rest_eval = eval_metrics(rest_tray_infl, trend_infl)

@chain rest_eval begin 
    DataFrame
    select(:mse_bias, :mse_var, :mse_cov, :mse, :mse_std_error)
end


## Compare trajectories of combination of core inflation measures

plot(InflationTotalCPI(), data; 
    label="Headline CPI inflation", 
    ylabel="% change, year-over-year",
    size = (800, 500),
    xticks = (date_ticks, date_str),
    xrotation = 45,
    bottom_margin=2*Plots.mm,
    left_margin=2*Plots.mm,
)
plot!(restricted_combination, data,
    linewidth=4,
    color=:blue,
)
plot!(unrestricted_combination, data,
    linewidth=2,
    linestyle=:dash, 
    color=2,
)

savefig(joinpath(plots_savepath, "rest_unrest_mse_combination.pdf"))