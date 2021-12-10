using DrWatson 
@quickactivate :HEMI 

using HEMI 
using Distributions
using Plots

## Path 
plots_savepath = mkpath(plotsdir("paper"))

## Historical data used
gtdata20 = gtdata[Date(2020, 12)]

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
    legend = :topleft,
    size = (800, 400)
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

population_traj = param(gtdata20)
plot(infl_dates(gtdata20), population_traj,
    label = false, 
    linewidth = 3, 
    grid = false, 
    ticks = false
)

savefig(joinpath(plots_savepath, "parametric_inflation.png"))


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