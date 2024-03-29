using DrWatson 
@quickactivate :HEMI 

using HEMI 
using StatsBase
using Distributions
using Plots
using PrettyTables

## Path 
plots_savepath = mkpath(plotsdir("paper"))

## Historical data used
gtdata20 = GTDATA[Date(2020, 12)]

## Price change distribution in the period 2001 to 2020

v = vcat(gtdata20[1].v..., gtdata20[2].v...)
dist = Normal(mean(v), std(v))

histogram(v, 
    label = "Actual distribution 2001-2020", 
    xlabel = "Percentual monthly price changes",
    ylabel = "% of distribution",
    bins = -100:0.2:100,
    normalize = :probability, 
    linewidth = 1.5,
    xlims = (-10, 10), 
    guidefontsize = 8, 
    tickfontsize = 6,
    legendfontsize = 7,
    xticks = -10:1:10,
    yticks = (0:0.1:0.4, string.(0:10:40) .* "%"),
    legend = :topleft,
    size = (800, 400),
    left_margin=3*Plots.mm
)

# Generate data from normal with same mean and variance
z = rand(Normal(mean(v), std(v)), 100_000)

# Plot a histogram of how normal data looks
histogram!(z, 
    label = false,
    bins = -10:0.2:10,
    normalize = :probability, 
    xlims = (-10, 10), 
    alpha = 0.25, 
)

# Plot the curve of probability bins with 0.2 width
plot!(-10:0.1:10, x -> pdf(dist, x) / 5, 
    label = "Normal distribution", 
    linewidth = 1.5, 
    color = :red
)


vline!([quantile(v, 0.7)], 
    label="70% percentile", 
    linewidth = 2, 
    linestyle = :dash,
    color = :blue
)

savefig(joinpath(plots_savepath, "price_change_dist.pdf"))

## Descriptive stats used in the plot 
stats_df = DataFrame(
    stat = [
        "Mean",
        "Median", 
        "Mode", 
        "Std. Deviation",
        "Skewness", 
        "Kurtosis",
        "No. Observations",
    ], 
    vstats = [
        mean(v),
        median(v), 
        mode(v), 
        std(v), 
        skewness(v), 
        kurtosis(v) + 3,
        length(v),
    ],
    normal = [
        mean(dist),
        median(dist), 
        mode(dist), 
        std(dist), 
        skewness(dist), 
        kurtosis(dist) + 3,
        length(dist),
    ]
)

pretty_table(
    stats_df, 
    tf=tf_latex_booktabs, 
    formatters=ft_round(2),
)

## Normalized plot, like the one presented in Roger (1997)

v_norm = (v .- mean(v)) / std(v)

histogram(v_norm, 
    label = "Actual distribution 2001-2020", 
    bins = -40:0.1:32,
    normalize = :pdf, 
    linewidth = 1.5,
    xlims = (-3, 3), 
    guidefontsize = 8, 
    tickfontsize = 6,
    legendfontsize = 7,
    xticks = -10:1:10,
    legend = :topleft,
    size = (800, 400)
)

plot!(-3:0.1:3, x -> pdf(Normal(), x),
    label = "Normal distribution", 
    linewidth = 2, 
    color = :red
)

savefig(joinpath(plots_savepath, "price_change_normalized.svg"))


## Resample procedure of estimators and MSE distribution

# Resampling technique, parametric inflation formula and trend function 
paramfn = InflationTotalRebaseCPI(60)
resamplefn = ResampleScrambleVarMonths() 
trendfn = TrendRandomWalk()

# Inflation estimator to show in the diagram
inflfn = InflationTotalCPI() 

# Create plots of realizations for the estimator
for i in 1:10
    plot(inflfn, (trendfn ∘ resamplefn)(gtdata20),
        label = false, 
        linewidth = 3, 
        grid = false, 
        ticks = false
    )

    savefig(joinpath(plots_savepath, "realization_$i.png"))
end

# Get parametric inflation trajectory 
param = InflationParameter(paramfn, resamplefn, trendfn)

dates = infl_dates(gtdata20)
population_traj = param(gtdata20)

plot(dates, population_traj,
    label = false, 
    linewidth = 3, 
    grid = false, 
    ticks = false
)

savefig(joinpath(plots_savepath, "parametric_inflation.png"))


## Population trajectory, with and without stochastic trend 
# Shows the population parameter with and without trend 

# Plot the untrended parametric inflation
untrended_param = InflationParameter(paramfn, resamplefn, TrendIdentity())

untrended_traj = untrended_param(gtdata20)
dates = infl_dates(gtdata20)
date_ticks = first(dates):Month(24):last(dates)
date_str = Dates.format.(date_ticks, dateformat"Y-m")

p1 = plot(dates, untrended_traj, 
    label = "Untrended population\ninflation", 
    ylabel = "% change, year-on-year",
    ylims = (0, 12),
    linewidth = 2, 
    guidefontsize = 8,
    xticks = (date_ticks, date_str),
    xrotation = 45, 
    legend = :bottomleft
)

# Plot the trended parametric inflation
trended_param = InflationParameter(paramfn, resamplefn, trendfn)

trended_traj = trended_param(gtdata20)
p2 = plot(dates, trended_traj, 
    label = "Artificially trended population\ninflation", 
    ylims = (0, 12),
    linewidth = 2, 
    guidefontsize = 8,
    xticks = (date_ticks, date_str),
    xrotation = 45, 
    legend = :bottomleft
)

factor_period = Date(2001, 1):Month(1):Date(2020, 12)
factor = log.(trendfn.trend[1:length(factor_period)])
p3 = plot(factor_period, factor,
    label = "Random walk process $(L"\rho_{t}")", 
    # ylabel = "",
    ylims = (-1, 1),
    linewidth = 2, 
    guidefontsize = 8,
    xticks = (date_ticks, date_str),
    xrotation = 45, 
    legend = :bottomleft
)
hline!([0],
    linewidth = 2, 
    color = :gray, 
    linestyle = :dash, 
    alpha = 0.5,
    label = false
)

# Make comparison plot
plot(p3, p1, p2, 
    size = (800, 400),
    layout = (1, 3),
    bottommargin = 4*Plots.mm, 
)

savefig(joinpath(plots_savepath, "stochastic_trend.pdf"))


## Comparison of inflation estimator formulas to apply to the population CPI data 


# Evaluate the parametric inflation for the next inflation formulas
formulas = [paramfn, InflationTotalCPI()]
label_formulas = ["CPI inflation with synthetic rebasing" "CPI inflation"]
# formulas = [paramfn, InflationTotalCPI(), InflationWeightedMean()]
# label_formulas = ["CPI inflation w/ synthetic rebase" "CPI inflation" "Weighted average"]

# For this comparison, use this trend function 
trendfn_comp = TrendIdentity() 

param_traj_formulas = mapreduce(hcat, formulas) do fn 
    param = InflationParameter(fn, resamplefn, trendfn_comp)
    param(gtdata20)
end

# Get the trended formulas with the Random Walk function
param_traj_trended_formulas = mapreduce(hcat, formulas) do fn 
    param = InflationParameter(fn, resamplefn, trendfn)
    param(gtdata20)
end

actual_rebase = [Date(2010, 12)]
synthetic_rebase = [Date(2005, 12), Date(2015, 12)]

# Untrended formulas

p1 = plot(dates, param_traj_formulas,
    label = label_formulas, 
    ylabel = "% change, year-on-year",
    ylims = (1, 15),
    linewidth = 2, 
    guidefontsize = 8,
    xticks = (date_ticks, date_str),
    xrotation = 45, 
    legend = :topright,
)

vline!(p1, actual_rebase, 
    linewidth = 2, 
    color = :black, 
    alpha = 0.5,
    label = "Actual CPI rebase"
)

vline!(p1, synthetic_rebase, 
    linewidth = 1.5, #[1.5 1.5], 
    color = :black, #[:blue :blue], 
    linestyle = :dash, #[:dash :dash], 
    alpha = 0.5, #[0.5 0.5],
    label = "Synthetic CPI rebase"
)

# Trended formulas
p2 = plot(dates, param_traj_trended_formulas,
    label = label_formulas, 
    ylims = (1, 15),
    linewidth = 2, 
    guidefontsize = 8,
    xticks = (date_ticks, date_str),
    xrotation = 45, 
    legend = false
)

vline!(p2, actual_rebase, 
    linewidth = 2, 
    color = :black, 
    alpha = 0.5,
    label = "Actual CPI rebase"
)

vline!(p2, synthetic_rebase, 
    linewidth = 1.5, #[1.5 1.5], 
    color = :black, #[:blue :blue], 
    linestyle = :dash, #[:dash :dash], 
    alpha = 0.5, #[0.5 0.5],
    label = "Synthetic CPI rebase"
)


# Make comparison plot
l = @layout [
    a{0.5w, 0.975h} b{0.5w}
]

plot(p1, p2, 
    left_margin=2*Plots.mm,
    size = (800, 400),
    layout = (1, 2),
    legend = [:topleft false], 
    leftmargin = 3*Plots.mm, 
    bottommargin = 5*Plots.mm, 
)

savefig(joinpath(plots_savepath, "inflation_formulas.pdf"))

plot(p1, 
    size = (800, 350),
    bottommargin = 5*Plots.mm, 
    leftmargin = 3*Plots.mm, 
)

savefig(joinpath(plots_savepath, "inflation_formulas_1.pdf"))

plot(p2, 
    ylabel = "% change, year-on-year",
    size = (800, 350),
    bottommargin = 5*Plots.mm, 
    leftmargin = 3*Plots.mm, 
    legend = true,
)

savefig(joinpath(plots_savepath, "inflation_formulas_2.pdf"))
## Plot historic trajectories 

# Load assessment results from paper-assessment.jl
data_savepath = datadir("results", "paper-assessment")
df_results = collect_results(data_savepath)

# We create an Ensemble of inflation estimators
obsfn = InflationEnsemble(df_results.inflfn...)
obsfn(gtdata)

# Plot historic series of core inflation measures
plot(obsfn, gtdata)

## Load realizations of inflation estimators 

transform!(df_results, 
    :path => ByRow(p -> joinpath(dirname(p), "tray_infl", basename(p))) => :tray_path
)

traj_infl = mapreduce(p -> load(p, "tray_infl"), hcat, df_results.tray_path)    


## Compute MSE distribution 

# mask = [(fn isa InflationPercentileEq && fn.k == 0.5f0) for fn in df_results.inflfn]
mask = [(fn isa InflationTotalCPI) for fn in df_results.inflfn]
mse_dist = mean(x -> x^2, traj_infl[:, mask, :] .- population_traj, dims=1) |> vec

histogram(mse_dist, 
    bins = 0:0.1:15,
    xlim = (0, 15), 
    label = false, 
    ticks = false, 
    grid = false
)

vline!([mean(mse_dist[mse_dist .< 15])], 
    label = false, 
    color = :red, 
    linewidth = 3
)

savefig(joinpath(plots_savepath, "mse_distribution.png"))