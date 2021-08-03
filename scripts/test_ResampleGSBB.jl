using DrWatson
@quickactivate "HEMI"

using Distributed
addprocs(4, exeflags="--project")

@everywhere using HEMI 
using Plots


## Obtener función de inflación y remuestreo 

# inflfn = InflationTotalCPI()
inflfn = InflationTotalRebaseCPI() 
# inflfn = InflationWeightedMean() 
# inflfn = InflationPercentileEq(69)

# resamplefn = ResampleGSBB(36)
# resamplefn = ResampleSBB(36)
resamplefn = ResampleScrambleVarMonths() 

trendfn = TrendIdentity()
# trendfn = TrendRandomWalk()

# @info "Función de remuestreo" resamplefn.blocklength resamplefn.seasonality

# Parámetro de inflación 

param = InflationParameter(inflfn, resamplefn, trendfn)
# param = ParamTotalCPIRebase(resamplefn, trendfn)
tray_infl_param = param(gtdata)
plot(infl_dates(gtdata), tray_infl_param, label="Paramétrica")


## Trayectorias de inflación 

evalinflfn = InflationPercentileEq(71) 

tray_infl = pargentrayinfl(evalinflfn, resamplefn, trendfn, gtdata; K = 25_000, rndseed=0)
 
m_tray_infl = vec(mean(tray_infl, dims=3))

sq_error_dist = (tray_infl .- tray_infl_param) .^ 2
mse = mean(sq_error_dist)
mse_std_error = std(sq_error_dist) / sqrt(size(sq_error_dist, 3))
mse_prom = mean((m_tray_infl - tray_infl_param) .^ 2)
@info "MSE" mse mse_std_error mse_prom


plot(infl_dates(gtdata), [m_tray_infl, tray_infl_param], 
    label=["Promedio" "Paramétrica"])
    
    


## Nube de trayectorias 

plot(infl_dates(gtdata), 
    mapreduce(i -> getindex(tray_infl, :, 1, i), hcat, 1:200), 
    label = :none, alpha=0.3)
plot!(infl_dates(gtdata), tray_infl_param, label="Paramétrica", 
    linewidth = 3, color = :black)



##  Análisis de promedios base 2000 

avgmat = InflationEvalTools.monthavg(gt00.v)
residmat = gt00.v - avgmat

mean(residmat, dims=1)

j = 5 
plot(residmat[:, j])
hline!([mean(residmat[:, j])])


##
historyavg_mat = mean(gt00.v, dims=1)
monthavg_mat = InflationEvalTools.monthavg(gt00.v)
residmat = gt00.v .- monthavg_mat

plot(residmat[:, 1])
hline!([monthavg_mat[1]])