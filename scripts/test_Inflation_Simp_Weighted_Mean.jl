# #Pruebas de funciones de media simple y media ponderada

#Carga de paquetes
using DrWatson
@quickactivate :HEMI
using InflationFunctions

# ##MEDIA SIMPLE

simplemeanfn = InflationSimpleMean()
simplemeanfn(gtdata)

# ##MEDIA PONDERADA 

weightedmeanfn = InflationWeightedMean()
a=weightedmeanfn(gt10)
t = weightedmeanfn(gtdata)

# ##MEDIA MÓVIL
inflfn = InflationMovingAverage(InflationTotalCPI(), 3)

inflfn(gtdata)

using Plots

all_ma = [InflationMovingAverage(InflationTotalCPI(), i)(gtdata) for i in 1:12] |> 
    x -> hcat(x...)

plot(infl_dates(gtdata), all_ma,
    # xlims=(Date(2001,12), Date(2005,12)),
    legend=false)
plot!(infl_dates(gtdata), InflationTotalCPI()(gtdata), 
    linewidth=3, color=:black) 

# @enter inflfn(gtdata)