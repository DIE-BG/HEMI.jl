using DrWatson
@quickactivate :HEMI
using Plots

## Path 
plots_savepath = mkpath(plotsdir("paper"))

## Historical data used
gtdata20 = gtdata[Date(2020, 12)]

dates = FGT10.dates
date_ticks = first(dates):Month(24):last(dates)
date_str = Dates.format.(date_ticks, dateformat"Y-m")

neg_corr = ["Tomate", "Cebolla", ""]

plot(
    dates, 
    FGT10.v[:, 29],
    xticks = (date_ticks, date_str),
    xrotation = 45, 
)