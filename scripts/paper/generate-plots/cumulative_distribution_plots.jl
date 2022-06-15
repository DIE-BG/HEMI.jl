using DrWatson
@quickactivate :HEMI

using HEMI 
using StatsBase
using Distributions
using Plots
using StatsPlots
using LaTeXStrings
using QuadGK

## Path 
plots_savepath = mkpath(plotsdir("paper", "cumulative-distribution"))

## Historical data used
gtdata20 = GTDATA[Date(2020, 12)]

## Empirical CDF of monthly price changes 
vdata = vcat(gtdata20[1].v..., gtdata20[2].v...)
v_cdf = StatsBase.ecdf(vdata)

# Normal distribution with same mean and variance
normal_dist = Normal(Float64(mean(vdata)), Float64(std(vdata)))
normal_cdf = x -> cdf(normal_dist, x)

## Plots of cumulative distribution functions
plot(
    v_cdf, 
    label="Monthly price changes empirical CDF " * L"(GLP)",
    xlims=(-30, 30),
    xlabel="Monthly price changes",
    ylabel="Cumulative distribution function (CDF)",
    size=(800,600),
    legend=:topleft,
    guidefontsize=10,
    legendfontsize=8,
)
plot!(normal_cdf, label="Normal CDF " * L"(\Phi)")

savefig(joinpath(plots_savepath, "cumulative-distribution-functions.png"))


## Testing Second-order Stochastic dominance

# Area under the curve of empirical CDF of monthly price changes
function area_vcdf(x; v_cdf=v_cdf)
    if x < 0 
        return first(quadgk(v_cdf, -100, x))
    end
    # Integrating over two ranges, for discontinuity of 0
    first(quadgk(v_cdf, -100, 0, x))
end

# Area under the curve of theoretical normal
area_normal = x -> (quadgk(normal_cdf, -100, x) |> first)

## Plot accumulated area under CDFs

r_ = -100:0.1:100
int_vcdf = map(area_vcdf, r_)
int_normal = map(area_normal, r_)

plot(r_, int_vcdf,
    label="Monthly price changes empirical CDF" * L"\quad\int_{-\infty}^{x}GLP(v)\mathrm{d}v",
    xlims=(-10, 10),
    ylims=(0, 10),
    xlabel=L"x",
    # ylabel=L"\textrm{\sffamily Cumulative CDF}",
    ylabel="Area under CDF",
    legend=:topleft,
    size=(800,600),
    guidefontsize=10,
    legendfontsize=10,
)
plot!(r_, int_normal,
    label="Normal distribution CDF" * L"\int_{-\infty}^{x}\Phi(v)\mathrm{d}v",
)

savefig(joinpath(plots_savepath, "second-order-stochastic-dominance.png"))

## Plot difference between accumulated area under CDFs

plot(r_, int_vcdf - int_normal,
    label="Difference in areas under CDFs\n" * L"\int_{-\infty}^{x}\left[GLP(v) - \Phi(v)\right]\mathrm{d}v",
    xlabel="Monthly price changes",
    size=(800,600),
    guidefontsize=10,
    legendfontsize=8,
    legend=:bottomright,
)

savefig(joinpath(plots_savepath, "second-order-stochastic-dominance-difference.png"))