using DrWatson 
# This exports the module HEMI and brings InflationFunctions to scope
@quickactivate :HEMI 

using Plots
using LaTeXStrings
using Printf

## Output folder 
plots_savepath = mkpath(plotsdir("paper", "hes-note"))

## Sample consumer-price data used
FINAL_DATE = Date(2020, 12)
cpidata = GTDATA[FINAL_DATE]

## Configure dates for plotting
dates = infl_dates(cpidata)
date_ticks = first(dates):Month(12):last(dates)
date_str = Dates.format.(date_ticks, dateformat"Y-m")


## Create the core inflation functions 

inflfn1 = InflationEnsemble(
    InflationCoreMaiF(5),
    InflationCoreMaiG(5), 
    InflationCoreMaiFP(5),
)

nseg2 = 10
inflfn2 = InflationEnsemble(
    InflationCoreMaiF(nseg2),
    InflationCoreMaiG(nseg2), 
    InflationCoreMaiFP(nseg2),
)

## Create a plot of the selected HES core methods

# Plot in contrast to the headline CPI inflation measure
bp = plot(
    InflationTotalCPI(), 
    cpidata, 
    label="Headline CPI inflation",
    ylabel = "% change, year-over-year",
    xticks = (date_ticks, date_str),
    xrotation = 45,
    size=(800,400),
    titlefontsize=11,
    legendfontsize=9,
    xlabelfontsize=8,
    ylabelfontsize=8,
)
hline!(bp, [0]; label=false, color=:gray, linealpha=0.5, linestyle=:dash)

p1 = plot!(
    deepcopy(bp),
    inflfn1,     # HES core measures
    cpidata, 
    label=["HES (F,5)" "HES (G,5)" "HES (FG,5)"],
    linewidth=2,
    linestyle=[:solid :solid :dash],
)

p2 = plot!(
    deepcopy(bp),
    inflfn2,     # HES core measures (set with higher volatility)
    cpidata, 
    label=["HES (F,10)" "HES (G,10)" "HES (FG,10)"],
    linewidth=2,
    linestyle=[:solid :solid :dash],
)


## Combined plots for comparison 

plot(p1, p2, 
    layout=(2,1), 
    size=(800,600), 
    xticks=[(date_ticks, ["" for _ in date_ticks]) (date_ticks, date_str)],
    leftmargin=2*Plots.mm,
    # bottommargin=4*Plots.mm,
)

savefig(joinpath(plots_savepath, "hes_example_core_measures.pdf"))


## Plotting the Optimal HES core inflation measure 

include(scriptsdir("mse-combination", "optmse2022.jl"))

plot(
    deepcopy(bp),
    optmai2018.ensemble,
    cpidata;
    label=["HES (F,4,[0.32, 0.70, 0.79])" "HES (FG,4,[0.31, 0.7, 0.82])" "HES (G,5,[0.05, 0.58, 0.75, 0.78])"],
    linewidth=2,
    size=(800, 400),
    leftmargin=2 * Plots.mm,
    bottommargin=4 * Plots.mm,
)

plot!(
    optmai2018,
    cpidata;
    label="Optimal MSE combination of HES core measures",
    linewidth=3,
    linestyle=:dot,
    color=:blue,
)

savefig(joinpath(plots_savepath, "hes_optimal_core_measures.pdf"))