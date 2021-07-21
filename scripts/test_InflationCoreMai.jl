using DrWatson
@quickactivate "HEMI"

using HEMI
using InflationFunctions
# using StatsBase
# using Plots


## Distribuciones de largo plazo
glp00 = WeightsDistr(gt00, V)
mean(glp00)
glp10 = WeightsDistr(gt10, V)
mean(glp10)

flp00 = ObservationsDistr(gt00, V)
mean(flp00)
flp10 = ObservationsDistr(gt10, V)
mean(flp10)

flp = flp00 + flp10
sum(flp), mean(flp)
glp = glp00 + glp10
sum(glp), mean(glp)


## Función de inflación 
inflfn = InflationCoreMai(V, MaiG(10))

mai_m = inflfn(gtdata, CPIVarInterm())

mai_tray_infl = inflfn(gtdata)

using BenchmarkTools

@btime inflfn($gtdata);

## Función de inflación 
inflfn = InflationCoreMai(V, MaiF(5))

mai_m = inflfn(gtdata, CPIVarInterm())
@profview inflfn(gtdata, CPIVarInterm())

mai_tray_infl = inflfn(gtdata)

