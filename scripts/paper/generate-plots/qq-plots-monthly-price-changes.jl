using DrWatson 
@quickactivate :HEMI 

using HEMI 
using Distributions
using Plots
using StatsPlots
using LaTeXStrings

## Path 
plots_savepath = mkpath(plotsdir("paper", "qqplots"))

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
    # period = periods[1]
    v = qqdata[period]
    dist = Normal(mean(v), std(v))
    label = period_labels[period]

    qqplot(
        dist, 
        v, 
        label="Empirical distribution", 
        # Figure properties
        size = (1200, 800),
        guidefontsize = 12, 
        tickfontsize = 12,
        legendfontsize = 12,
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
        xlims=(-12, 12),
        ylims=(-60, 60),
        # Adjustments
        left_margin=5*Plots.mm,
        bottom_margin=5*Plots.mm,
    )

    median_theo = median(dist)
    median_emp = median(v)
    scatter!([median_theo], [median_emp], label="Median", ms=8, c=:blue, legend_position=:bottomright)

    annotate!([(median_theo+15, median_emp-5, 
        L"( %$(round(median_theo,digits=4)), %$(round(median_emp,digits=4)) )")])

    
    pdf_filename = savename("qqplot_", (period=period,), "pdf")
    png_filename = savename("qqplot_", (period=period,), "png")

    savefig(joinpath(plots_savepath, pdf_filename))
    savefig(joinpath(plots_savepath, png_filename))
end


## Plots with equal aspect ratio

qq_plots = []

map(periods) do period
    v = qqdata[period]
    dist = Normal(mean(v), std(v))
    label = period_labels[period]

    qqplot(
        dist, 
        v, 
        label="Empirical distribution", 
        # Figure properties
        size = (1200, 800),
        guidefontsize = 12, 
        tickfontsize = 12,
        legendfontsize = 12,
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
        xticks=-60:20:60,
        yticks=-60:20:60,
        aspectratio=:equal,
        # Adjustments
        left_margin=5*Plots.mm,
        bottom_margin=5*Plots.mm,
    )

    median_theo = median(dist)
    median_emp = median(v)
    scatter!([median_theo], [median_emp], label="Median", ms=8, c=:blue, legend_position=:bottomright)

    annotate!([(median_theo+10, median_emp-5, 
        L"( %$(round(median_theo,digits=4)), %$(round(median_emp,digits=4)) )")])

    
    pdf_filename = savename("qqplot_equal", (period=period,), "pdf")
    png_filename = savename("qqplot_equal", (period=period,), "png")

    savefig(joinpath(plots_savepath, pdf_filename))
    savefig(joinpath(plots_savepath, png_filename))

    global qq_plots
    push!(qq_plots, current())
end


## All QQ-plots in the same plot

plot(qq_plots..., 
    layout=(1, 3),
    legend_position=[:topleft false false],
    title=["CPI 2000 & 2010 dataset (2001-2020)" "CPI 2000 dataset (2001-2010)" "CPI 2010 dataset (2011-2020)"],
    plot_title="QQ-plots for Guatemalan monthly price changes",
)


pdf_filename = savename("all_qqplots_equal", (period="all",), "pdf")
png_filename = savename("all_qqplots_equal", (period="all",), "png")

savefig(joinpath(plots_savepath, pdf_filename))
savefig(joinpath(plots_savepath, png_filename))