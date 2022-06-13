using DrWatson 
@quickactivate :HEMI 

using HEMI 
using Distributions
using Plots
using StatsPlots

## Path 
plots_savepath = mkpath(plotsdir("paper"))

## Historical data used
gtdata20 = GTDATA[Date(2020, 12)]

## QQ plots for distribution of monthly price changes in the period 2001-2020

qqdata = Dict(
    "b0010" => vcat(gtdata20[1].v..., gtdata20[2].v...),
    "b00" => [gtdata20[1].v...],
    "b10" => [gtdata20[2].v...],
) 
period_labels = Dict(
    "b0010" => "2001-2020",
    "b00" => "2001-2010",
    "b10" => "2011-2020",
) 

periods = ["b0010", "b00", "b10"]

map(periods) do period
    v = qqdata[period]
    dist = Normal(mean(v), std(v))
    label = period_labels[period]

    qqplot(
        dist, 
        v, 
        # Figure properties
        size = (800, 400),
        guidefontsize = 10, 
        tickfontsize = 10,
        # Line properties
        linecolor=:red,
        linestyle=:dot,
        linewidth=4,
        # Marker properties
        markercolor=1,
        markersize=6, 
        markeralpha=0.10, 
        markerstrokewidth=0,
        # Axes properties
        xlabel="Normal distribution quantiles",
        ylabel="Actual distribution ($label) quantiles",
        # aspectratio=:equal,
        # xlims=(-20, 20),
        # ylims=(-20, 20),
        # Adjustments
        left_margin=3*Plots.mm,
        bottom_margin=3*Plots.mm,
    )
    
    pdf_filename = savename("qqplot_", (period=period,), "pdf")
    png_filename = savename("qqplot_", (period=period,), "png")

    savefig(joinpath(plots_savepath, pdf_filename))
    savefig(joinpath(plots_savepath, png_filename))
end