using DrWatson 
@quickactivate :HEMI 

using HEMI 
using StatsBase
using StatsPlots
using Distributions
using Plots
using PrettyTables

## Path 
plots_savepath = mkpath(plotsdir("paper"))

## Historical data used
gtdata20 = GTDATA[Date(2020, 12)]

# Step for bins in histogram
STEP = 0.2

## Price change distribution in the period 2001 to 2020

v = vcat(gtdata20[1].v..., gtdata20[2].v...)
dist = Normal(mean(v), std(v))

histogram(v, 
    label = "Actual distribution 2001-2020", 
    xlabel = "Percentual monthly price changes",
    ylabel = "% of distribution",
    bins = -100:STEP:100,
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


# Plot the curve of probability bins with 0.2 width
plot!(
    -10:0.1:10, 
    x -> pdf(dist, x) * STEP, 
    fillrange = x -> 0, 
    fillalpha = 0.25, 
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

savefig(joinpath(plots_savepath, "price_change_dist_b0010.pdf"))
savefig(joinpath(plots_savepath, "price_change_dist_b0010.png"))

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
    tf=tf_markdown, 
    formatters=ft_round(4),
)


## Price change distribution in the period of the CPI 2000 dataset: 2001 to 2010

v = [gtdata20[1].v...]
dist = Normal(mean(v), std(v))

histogram(v, 
    label = "Actual distribution 2001-2010", 
    xlabel = "Percentual monthly price changes",
    ylabel = "% of distribution",
    bins = -100:STEP:100,
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


# Plot the curve of probability bins with 0.2 width
plot!(
    -10:0.1:10, 
    x -> pdf(dist, x) * STEP, 
    fillrange = x -> 0, 
    fillalpha = 0.25, 
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

savefig(joinpath(plots_savepath, "price_change_dist_b00.pdf"))
savefig(joinpath(plots_savepath, "price_change_dist_b00.png"))

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
    tf=tf_markdown, 
    formatters=ft_round(4),
)


## Price change distribution in the period of the CPI 2010 dataset: 2010 to 2020

v = [gtdata20[2].v...]
dist = Normal(mean(v), std(v))

histogram(v, 
    label = "Actual distribution 2011-2020", 
    xlabel = "Percentual monthly price changes",
    ylabel = "% of distribution",
    bins = -100:STEP:100,
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


# Plot the curve of probability bins with 0.2 width
plot!(
    -10:0.1:10, 
    x -> pdf(dist, x) * STEP, 
    fillrange = x -> 0, 
    fillalpha = 0.25, 
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

savefig(joinpath(plots_savepath, "price_change_dist_b10.pdf"))
savefig(joinpath(plots_savepath, "price_change_dist_b10.png"))

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
    tf=tf_markdown, 
    formatters=ft_round(4),
)

