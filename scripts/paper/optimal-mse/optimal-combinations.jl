using DrWatson
@quickactivate :HEMI

using DataFrames
using Chain
using PrettyTables
using CSV
using Plots
using StatsPlots

# Load Distributed package to use parallel computing capabilities 
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Path 
comp_results_savepath = datadir("results", "mse-combination", "optmse2022-components")
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
df_results = collect_results(joinpath(comp_results_savepath))
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


## Boxplots and other plots 

# Add inflation trajectories from optimal combinations 
all_tray_infl = cat(tray_infl, rest_tray_infl, unrest_tray_infl; dims=2)

measures = [
    "Trimmed Mean (58.7%, 83.1%)",
    "72th Percentile",                    
    "Historically Expanded Sample Core",
    "Std. Deviations exclusion (0.3, 1.7)",
    "Weighted Trimmed Mean (21%, 96%)",
    "70th Weighted Percentile",
    "Fixed exclusion (14, 14)",
    "Restricted optimal MSE combination",
    "Unrestricted optimal MSE combination",
]

## Mean error boxplot

err_dist = (all_tray_infl .- trend_infl) |> x -> vcat(eachslice(x, dims=3)...)

err_p = boxplot(permutedims(string.('A':'I')), err_dist, 
    label=permutedims(string.('A':'I') .* " - " .* measures),
    ylabel="Simulation error distribution",
    legend=true,
    legendposition=:topleft,
    size=(800,500),
    dpi=400,
    linewidth=1,
    marker=(stroke(0)),
    markeralpha=0.4,
    leftmargin=3*Plots.mm,
    guidefontsize=10,
    titlefontsize=11,
    xlabelfontsize=10,
    ylabelfontsize=10,
    legendfontsize=8,
)

# savefig(joinpath(plots_savepath, "error_boxplot.pdf"))
savefig(joinpath(plots_savepath, "error_boxplot.png"))

## Squared errors boxplot

sq_err_dist = (tray_infl .- trend_infl) .^ 2 |> x -> vcat(eachslice(x, dims=3)...)
# sq_err_dist = sq_err_dist[1:10_000, :]

sqerr_p = boxplot(permutedims(string.('A':'I')), sq_err_dist, 
    label=permutedims(string.('A':'I') .* " - " .* measures),
    legend=false,
    size=(800,400),
    dpi=100,
    linewidth=1,
    marker=(stroke(0)),
    markeralpha=0.3,
    leftmargin=3*Plots.mm,
    guidefontsize=10,
    titlefontsize=11,
    xlabelfontsize=10,
    ylabelfontsize=10,
    legendfontsize=8,
)

zoom_sqerr_p = plot(
    sqerr_p, 
    ylabel="Simulation quadratic error distribution",
    ylims=(0,16),
    legend=true,
    legendposition=:topleft,
)

plot(sqerr_p, zoom_sqerr_p, 
    layout=grid(2,1, heights=[0.25, 0.75]),
    size=(800, 600),
    dpi=400,
    titlefontsize=11,
    xlabelfontsize=10,
    ylabelfontsize=10,
)

# savefig(joinpath(plots_savepath, "sqerror_boxplot.pdf"))
savefig(joinpath(plots_savepath, "sqerror_boxplot.png"))

## Plot of average squared error over time periods

mse_dist = mean(x -> x^2, tray_infl .- trend_infl, dims=1) |> x -> vcat(eachslice(x, dims=3)...)

boxplot(permutedims(string.('A':'I')), mse_dist, 
    label=permutedims(string.('A':'I') .* " - " .* measures),
    ylabel="Mean squared error",
    legendposition=:topleft,
    size=(800,400),
    linewidth=1,
    marker=(stroke(0)),
    markeralpha=0.4,
    leftmargin=3*Plots.mm,
    guidefontsize=10,
    titlefontsize=11,
    xlabelfontsize=10,
    ylabelfontsize=10,
    legendfontsize=8,
)

savefig(joinpath(plots_savepath, "mse_overtime_boxplot.pdf"))


