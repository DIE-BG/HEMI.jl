using DrWatson
@quickactivate :HEMI

using HEMI
using Distributions
using StatsPlots
using Plots
using Printf

## Path 
plots_savepath = mkpath(plotsdir("paper", "cross-sectional-distr-ranges"))

## Historical data used
gtdata20 = GTDATA[Date(2020, 12)]

## Price change distribution in the period 2001 to 2020

v = vcat(gtdata20[1].v..., gtdata20[2].v...)
dist = Normal(mean(v), std(v))

fmt(x; digits=1) = string(round(x * 100; digits)) * "%"
fmt(x) = (@sprintf("%0.4f", x * 100)) * "%"

function crosshistplot(
    vdata;
    step=0.2,
    xlims=(-10, 10),
    xticks=-100:1:100,
    plot_normal=true,
    plot_70th=true,
    kwargs...,
)
    bp = histogram(
        vdata;
        label="Actual distribution 2001-2020",
        xlabel="Percentual monthly price changes",
        ylabel="% of distribution",
        bins=-100:step:100,
        normalize=:probability,
        linewidth=1.5,
        xlims=xlims,
        guidefontsize=10,
        tickfontsize=8,
        legendfontsize=10,
        xticks=xticks,
        yticks=(0:0.05:0.4, fmt.(0:0.05:0.4; digits=1)),
        legend=:topleft,
        size=(800, 400),
        left_margin=3 * Plots.mm,
        bottom_margin=3 * Plots.mm,
        kwargs...,
    )

    # Plot the curve of probability bins with 0.2 width
    if plot_normal
        plot!(
            bp,
            -100:step:100,
            x -> pdf(dist, x) * step;
            fillrange=x -> 0,
            fillalpha=0.25,
            label="Normal distribution",
            linewidth=1.5,
            color=:red,
        )
    end

    # Plot the vertical line of 70th percentile
    if plot_70th
        vline!(
            bp,
            [quantile(v, 0.7)];
            label="70th percentile",
            linewidth=2,
            linestyle=:dash,
            color=:blue,
        )
    end

    return bp
end

# a. Range of [-100, 100]
crosshistplot(v; step=0.1, xlims=(-100, 100), xticks=-100:10:100)
savefig(joinpath(plots_savepath, "price_change_dist_b0010_a.png"))

# b. Range of [-5, 5]
crosshistplot(v; step=0.1, xlims=(-5, 5), xticks=-5:0.5:5)
savefig(joinpath(plots_savepath, "price_change_dist_b0010_b.png"))

# c. Range of [-2, 2]
crosshistplot(v; step=0.1, xlims=(-2, 2), xticks=-2:0.25:2)
savefig(joinpath(plots_savepath, "price_change_dist_b0010_c.png"))

# d. Range of [-1, 1]
crosshistplot(v; step=0.1, xlims=(-1, 1), xticks=-1:0.1:1)
savefig(joinpath(plots_savepath, "price_change_dist_b0010_d.png"))

# e. Range of [-0.5, 0.5]
crosshistplot(v; step=0.1, xlims=(-0.5, 0.5), xticks=-1:0.1:1)
savefig(joinpath(plots_savepath, "price_change_dist_b0010_e.png"))

# f. Range of [-100, -10]
vrange = 0:0.000025:0.0002
crosshistplot(
    v;
    step=0.1,
    xlims=(-100, -10),
    xticks=-100:10:-10,
    plot_normal=true,
    plot_70th=false,
    ylims=(minimum(vrange), maximum(vrange)),
    yticks=(vrange, fmt.(vrange, digits=4)),
    linewidth=0,
)
savefig(joinpath(plots_savepath, "price_change_dist_b0010_f.png"))

# g. Range of [-10, -5]
vrange = 0:0.00025:0.002
crosshistplot(
    v;
    step=0.1,
    xlims=(-10, -5),
    xticks=-10:1:-5,
    plot_normal=true,
    plot_70th=false,
    ylims=(minimum(vrange), maximum(vrange)),
    yticks=(vrange, fmt.(vrange, digits=4)),
)
savefig(joinpath(plots_savepath, "price_change_dist_b0010_g.png"))

# h. Range of [-10, 1]
crosshistplot(v; step=0.1, xlims=(-10, 1), xticks=-10:1:1)
savefig(joinpath(plots_savepath, "price_change_dist_b0010_h.png"))

# i. Range of [-5, 5]
crosshistplot(v; step=0.1, xlims=(-5, 5), xticks=-5:0.5:5)
savefig(joinpath(plots_savepath, "price_change_dist_b0010_i.png"))

# j. Range of [5, 10]
vrange = 0:0.00025:0.003
crosshistplot(
    v;
    step=0.1,
    xlims=(5, 10),
    xticks=5:1:10,
    plot_70th=false,
    ylims=(minimum(vrange), maximum(vrange)),
    yticks=(vrange, fmt.(vrange, digits=4)),
    legend=:topright,
)
savefig(joinpath(plots_savepath, "price_change_dist_b0010_j.png"))

# k. Range of [10, 100]
vrange = 0:0.000025:0.0002
crosshistplot(
    v;
    step=0.1,
    xlims=(10, 100),
    xticks=10:10:100,
    plot_70th=false,
    ylims=(minimum(vrange), maximum(vrange)),
    yticks=(vrange, fmt.(vrange, digits=4)),
    linewidth=0,
    legend=:topright,
)
savefig(joinpath(plots_savepath, "price_change_dist_b0010_k.png"))
