using DrWatson
@quickactivate :HEMI
using Plots

## Path 
plots_savepath = mkpath(plotsdir("paper"))

## Historical data used
FINAL_DATE = Date(2020, 12)
gtdata20 = gtdata[FINAL_DATE]

# FullCPIBase with data until FINAL_DATE
f = FGT10.dates .<= FINAL_DATE
fgt10 = FullCPIBase(
    FGT10.ipc[f, :], 
    FGT10.v[f, :], 
    FGT10.w, 
    FGT10.dates[f], 
    FGT10.baseindex, 
    FGT10.codes, 
    FGT10.names
) 

# Dates and ticks for the plots
dates = fgt10.dates
# date_ticks = first(dates):Month(12):last(dates)
date_ticks = Date(2010,12):Month(24):last(dates)
date_str = Dates.format.(date_ticks, dateformat"Y-m")

# Maximum lags for correlation plots
LAGS = 12
lags_ticks = (0:2:LAGS, string.(0:2:LAGS))
## Negative correlation goods and services

neg_corr = ["Tomate"]
idxs = map(s -> findfirst(==(s), fgt10.names), neg_corr)
tsdata = fgt10.v[:, first(idxs)]

p1 = plot(
    dates, 
    tsdata, 
    label="Tomatoes", 
    linewidth = 2, 
    guidefontsize = 8,
    xticks=(date_ticks, date_str),
    xrotation=45, 
    ylabel="% change, monthly",
)
hline!(
    p1,
    [0],
    linewidth = 2, 
    color = :gray, 
    linestyle = :dash, 
    alpha = 0.5,
    label = false
)


acf(tsdata; lag=LAGS)
p_acf_neg = current()
hline!(p_acf_neg, [0], linewidth=2, color=:gray, alpha=0.5)
xticks!(p_acf_neg, lags_ticks)
ylabel!(p_acf_neg, "Autocorrelation")
xlabel!(p_acf_neg, "Lag")

pacf(tsdata; type="real", lag=LAGS)
p_pacf_neg = current()
hline!(p_pacf_neg, [0], linewidth=2, color=:gray, alpha=0.5)
xticks!(p_pacf_neg, lags_ticks)
ylabel!(p_pacf_neg, "Partial autocorrelation")
xlabel!(p_pacf_neg, "Lag")

p_neg_corr = plot(
    p1, 
    p_acf_neg, 
    p_pacf_neg, 
    layout=(1,3), 
    size=(800,300),
    guidefontsize=8,
    leftmargin=3Plots.mm,
    bottommargin=5Plots.mm,
)

## Positive correlation goods and services

pos_corr = [
    # "Alquiler de vivienda", # *
    # "Servicio de internet residencial", # *
    # "Desayuno consumido fuera del hogar", # *
    "Almuerzo consumido fuera del hogar", # *
    # "Platos preparados para llevar", # *
]

no_trans_2010 = [100,107,108,110,112:114...,155,156,170:177...,187:198...,200:205...,223:229...,231:233...,236:252...,273:279...]
idxs = map(s -> findfirst(==(s), fgt10.names), pos_corr)
tsdata = fgt10.v[:, first(idxs)]
# tsdata = fgt10.v[:, no_trans_2010[i]]
# i += 1
# @show "Desplegando información para el gasto:" no_trans_2010[i] 

p2 = plot(
    dates, 
    tsdata,
    label="Lunch consumed outside",
    # label=pos_corr[j], 
    # label=fgt10.names[no_trans_2010[i]], 
    linewidth = 2, 
    guidefontsize = 8,
    xticks=(date_ticks, date_str),
    xrotation=45, 
    ylabel="% change, monthly"
)
hline!(
    p2,
    [0],
    linewidth = 2, 
    color = :gray, 
    linestyle = :dash, 
    alpha = 0.5,
    label = false,
)

acf(tsdata; lag=LAGS)
p_acf_pos = current()
hline!(p_acf_pos, [0], linewidth=2, color=:gray, alpha=0.5)
xticks!(p_acf_pos, lags_ticks)
ylabel!(p_acf_pos, "Autocorrelation")
xlabel!(p_acf_pos, "Lag")

pacf(tsdata; type="real", lag=LAGS)
p_pacf_pos = current()
hline!(p_pacf_pos, [0], linewidth=2, color=:gray, alpha=0.5)
xticks!(p_pacf_pos, lags_ticks)
# yaxis!(p_pacf_pos, false)
# yticks!(p_pacf_pos, (-0.2:0.1:0.3, ["" for _ in 1:6]))
ylabel!(p_pacf_pos, "Partial autocorrelation")
xlabel!(p_pacf_pos, "Lag")

p_pos_corr = plot(
    p2, 
    p_acf_pos, 
    p_pacf_pos, 
    layout=(1,3), 
    size=(800,300),
    guidefontsize=8,
    leftmargin=3Plots.mm,
    bottommargin=5Plots.mm,
)



## Both plots: negative and extreme acf and pacf and good behaved with positive correlation  

plot(
    p_neg_corr, 
    p_pos_corr, 
    layout=(2,1),
    size=(800,400)
)

savefig(joinpath(plots_savepath, "correlation_goods_services.pdf"))