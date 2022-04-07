using DrWatson 
@quickactivate :HEMI 

using HEMI 
using DataFrames, Chain
using Plots

## Path 
plots_savepath = mkpath(plotsdir("paper", "appendix"))

## Historical data used
data = GTDATA[Date(2021, 12)]

## Load optimal combination measure for Guatemala
include(scriptsdir("mse-combination", "optmse2022.jl"))

## Plot optimal combination measure vs CPI inflation 

dates = infl_dates(data)
date_ticks = first(dates):Month(24):last(dates)
date_str = Dates.format.(date_ticks, dateformat"Y-m")

bp = plot(InflationTotalCPI(), data,
    label = "Headline CPI inflation",
    ylabel = "% change, year-on-year",
    linewidth = 2, 
    guidefontsize = 8,
    xticks = (date_ticks, date_str),
    xrotation = 45
)
p1 = plot(bp, optmse2022, data, 
    label = "Combination of core measures", 
    linewidth = 3,
    palette = :darkrainbow,
) 
hline!(p1, [0], 
    label = false, 
    color = :gray,
    linealpha = 0.5, 
    linestyle = :dash
)

##  Combination components vs CPI inflation 

core_measures = optmse2022.ensemble

# Historically expanded sample

p2 = plot(bp, core_measures, GTDATA, 
    label = ["Percentile 72%" "Weighted Percentile 70%" "Trimmed Mean (58.7%, 83.1%)" "Weighted Trimmed Mean (21%, 96%)" "Std. deviations exclusion (0.3, 1.7)" "Fixed exclusion (14, 14)" "HES Core inflation"],
    linewidth = 2,
    linealpha = 0.9,
    # linestyle = :auto, 
    # linealpha = 0.5
    # palette = palette([:green, :blue], 7),
    # palette = :Dark2_5,
    palette = :darkrainbow,
    xticks = (date_ticks, ["" for _ in date_ticks])
)
hline!(p2, [0], 
    label = false, 
    color = :gray,
    linealpha = 0.5, 
    linestyle = :dash
)



## Combine plots 

plot(p2, p1,
    left_margin=2*Plots.mm,
    layout = (2, 1),
    size = (800, 600)
)

savefig(joinpath(plots_savepath, "mse_core_measures.pdf"))