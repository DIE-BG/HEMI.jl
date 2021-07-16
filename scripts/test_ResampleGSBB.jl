using DrWatson
@quickactivate "HEMI"

using Distributed
addprocs(4, exeflags="--project")

@everywhere using HEMI 
using Plots


## Obtener función de inflación y remuestreo 
# inflfn = InflationTotalCPI()
# inflfn = InflationTotalRebaseCPI() 
# inflfn = InflationSimpleMean() 
inflfn = InflationPercentileEq(69)

# resamplefn = ResampleGSBB(36)
resamplefn = ResampleSBB(36)
# resamplefn = ResampleScrambleVarMonths() 

# trendfn = TrendIdentity()
trendfn = TrendRandomWalk()

# @info "Función de remuestreo" resamplefn.blocklength resamplefn.seasonality

# Parámetro de inflación 

# param = InflationParameter(inflfn, resamplefn, trendfn)
param = ParamTotalCPIRebase(resamplefn, trendfn)
tray_infl_param = param(gtdata)
plot(infl_dates(gtdata), tray_infl_param, label="Paramétrica")


## Trayectorias de inflación 
tray_infl = pargentrayinfl(inflfn, resamplefn, trendfn, gtdata; K = 25_000)

m_tray_infl = vec(mean(tray_infl, dims=3))

mse = mean((tray_infl .- tray_infl_param) .^ 2)
@info "MSE" mse

plot(infl_dates(gtdata), [m_tray_infl, tray_infl_param], 
    label=["Promedio" "Paramétrica"])
