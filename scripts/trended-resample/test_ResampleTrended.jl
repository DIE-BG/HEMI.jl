using DrWatson
@quickactivate :HEMI 
using InflationEvalTools
using Test 
using Plots

## Procesos de computación
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Pruebas con dos bases
resamplefn = ResampleTrended([0.5, 1])
resdata = resamplefn(GTDATA)

@test !all(resdata[1].v .== GTDATA[1].v)
@test all(resdata[2].v .== GTDATA[2].v)

resamplefn = ResampleTrended([1., 0.5])
resdata = resamplefn(GTDATA)
@test all(resdata[1].v .== GTDATA[1].v)
@test !all(resdata[2].v .== GTDATA[2].v)

resamplefn = ResampleTrended([1., 1.])
resdata = resamplefn(GTDATA)
@test all(resdata[1].v .== GTDATA[1].v)
@test all(resdata[2].v .== GTDATA[2].v)

param = InflationParameter(InflationTotalCPI(), resamplefn, TrendIdentity())
tray_infl_param = param(GTDATA)
tray_infl = InflationTotalCPI()(GTDATA)
@test tray_infl_param == tray_infl


## Graficar parámetro y trayectorias alrededor del parámetro

resamplefn = ResampleTrended([0.5695731554158409, 0.42360815127381435])
# resamplefn = ResampleTrended(0.46031723899305166)
paramfn = InflationTotalRebaseCPI(36, 3)
param = InflationParameter(paramfn, resamplefn, TrendIdentity())
tray_infl_param = param(GTDATA)
dates = infl_dates(GTDATA)

tray_infl = pargentrayinfl(paramfn, resamplefn, TrendIdentity(), GTDATA; K = 1000)
plot(dates, reshape(tray_infl, size(tray_infl, 1), size(tray_infl, 3)), 
    label = false, 
    alpha = 0.1, 
    color = :gray
)

plot!(dates, tray_infl_param, 
    label = "Trayectoria paramétrica",
    color = :blue, 
    linewidth = 2, 
)