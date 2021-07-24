# sbb_gsbb_eval.jl - Script de comparación de evaluación con los métodos de
# remuestreo de Stationary Block Bootstrap y Generalized Stational Block
# Bootstrap

using DrWatson
@quickactivate "bootstrap_dev"

## Cargar datos 
using HEMI
@load projectdir("..", "..", "data", "guatemala", "gtdata32.jld2") gt00 gt10
gtdata = UniformCountryStructure(gt00, gt10)

using Distributed
addprocs(4, exeflags="--project")

# Cargar paquetes de remuestreo y evaluación 
@everywhere begin
    using Dates, CPIDataBase
    using InflationEvalTools
    using InflationFunctions
end 

# Datos hasta dic-20
gtdata_eval = gtdata[Date(2020, 12)]

# Obtener medida de inflación total 
totalfn = InflationTotalCPI()

percfn = InflationPercentileEq(64)

# Función de remuestreo Stationary BB
resample_sbb = ResampleSBB(36)

# Función de remuestreo Generalized Stational Block Bootstrap 
resample_gsbb = ResampleGSBBMod()

# Función de inflación para trayectoria paramétrica 
totalrebasefn = InflationTotalRebaseCPI()

## Evaluación de inflación total con remuestreo Stationary Block Bootstrap

tray_infl_sbb = pargentrayinfl(percfn, # función de inflación
    gtdata_eval, # datos de evaluación hasta dic-20
    resample_sbb, # remuestreo SBB
    SNTREND; # sin tendencia 
    rndseed = 0, K=125_000);

# Cómputo del parámetro 
gtdata_param_sbb = param_sbb(gtdata_eval)
tray_infl_pob_sbb = totalrebasefn(gtdata_param_sbb)

# Distribución del error cuadrático medio de evaluación 
mse_dist = vec(mean((tray_infl_sbb .- tray_infl_pob_sbb) .^ 2; dims=1))

# Métricas de evaluación 
mse = mean( (tray_infl_sbb .- tray_infl_pob_sbb) .^ 2) 
rmse = mean( sqrt.((tray_infl_sbb .- tray_infl_pob_sbb) .^ 2))
me = mean((tray_infl_sbb .- tray_infl_pob_sbb))
@info "Métricas de evaluación:" mse rmse me

# Evaluación con expected_l = 12
# ┌ Info: Métricas de evaluación:
# │   mse = 6.9420505f0
# │   rmse = 1.9298557f0
# └   me = 0.7039684f0

# Evaluación con expected_l = 25
# MSE = 6.5470576f0
# RMSE = 1.9015286f0
# ME = 0.6036617f0

# Evaluación con expected_l = 36
# ┌ Info: Métricas de evaluación:
# │   mse = 6.3761406f0
# │   rmse = 1.8824773f0
# └   me = 0.55467004f0

# Evaluación percentil 72 con expected_l = 36
# ┌ Info: Métricas de evaluación:
# │   mse = 2.98542f0
# │   rmse = 1.2623894f0
# └   me = 0.9757914f0

# Evaluación percentil 74 con expected_l = 36
# ┌ Info: Métricas de evaluación:
# │   mse = 4.687037f0
# │   rmse = 1.6568773f0
# └   me = 1.521031f0

# Evaluación percentil 70 con expected_l = 36
# ┌ Info: Métricas de evaluación:
# │   mse = 2.026146f0
# │   rmse = 1.0252029f0
# └   me = 0.49060473f0

# Evaluación percentil 68 con expected_l = 36
# ┌ Info: Métricas de evaluación:
# │   mse = 1.6019855f0
# │   rmse = 0.95422924f0
# └   me = 0.055560794f0

# Evaluación percentil 66 con expected_l = 36
# ┌ Info: Métricas de evaluación:
# │   mse = 1.5745925f0
# │   rmse = 1.0072765f0
# └   me = -0.3463791f0

# Evaluación percentil 64 con expected_l = 36
# ┌ Info: Métricas de evaluación:
# │   mse = 1.8621913f0
# │   rmse = 1.1359489f0
# └   me = -0.72067845f0



## Evaluación de inflación total con remuestreo Generalized Stational Block Bootstrap (GSBB) modificado a 300 períodos y tamaño de bloque = 25

tray_infl_gsbb = pargentrayinfl(totalfn, 
    gtdata_eval, 
    resample_gsbb, # remuestreo GSBB
    SNTREND; # sin tendencia 
    rndseed = 0, K=125_000);

# Cómputo del parámetro 
gtdata_param_gsbb = param_gsbb_mod(gtdata_eval)
tray_infl_pob_gsbb = totalrebasefn(gtdata_param_gsbb)

# Distribución del error cuadrático medio de evaluación 
mse_dist = vec(mean((tray_infl_gsbb .- tray_infl_pob_gsbb) .^ 2; dims=1))

# Métricas de evaluación 
mse = mean( (tray_infl_gsbb .- tray_infl_pob_gsbb) .^ 2) 
rmse = mean( sqrt.((tray_infl_gsbb .- tray_infl_pob_gsbb) .^ 2))
me = mean((tray_infl_gsbb .- tray_infl_pob_gsbb))
@info "Métricas de evaluación:" mse rmse me

# MSE = 162.04018f0
# RMSE = 7.7451987f0
# ME = 6.754988f0
