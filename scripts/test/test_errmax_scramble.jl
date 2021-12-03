using DrWatson
@quickactivate "HEMI"

using HEMI 
using Plots

# Datos hasta dic-19
gtdata_eval = gtdata[Date(2019, 12)]

## Configuración del parámetro de evaluación a dic-19
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk() 

# Forma manual de configuración del parámetro 
legacy_param = InflationParameter(
    InflationTotalRebaseCPI(36, 2), # Cada 36 meses y hasta 2 cambios de base 
    resamplefn, 
    trendfn
)

# Trayectoria paramétrica
tray_infl_pob = legacy_param(gtdata_eval)

## Generar trayectorias 

using Distributed 
addprocs(4, exeflags="--project")
@everywhere using HEMI

# Generar trayectorias de inflación total
tray_infl = pargentrayinfl(InflationTotalCPI(), resamplefn, trendfn, gtdata_eval,
    K = 125_000)


# Error de simulación 

err_dist = vec(tray_infl .- tray_infl_pob)

histogram(err_dist, normalize=:probability)
xlims!(-100, 100)
[minimum(err_dist), quantile(err_dist, 0.25:0.25:0.75), maximum(err_dist)]