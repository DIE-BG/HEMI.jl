using DrWatson
@quickactivate "HEMI" 

using Plots
using DataFrames

## Se carga el módulo de `Distributed` para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Datos de entrenamiento 
TRAIN_DATE = Date(2016,12)
gtdata_eval = gtdata[TRAIN_DATE]

## Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk() 

inflfn = EnsembleFunction(
    InflationPercentileEq(71.43), 
    InflationPercentileWeighted(69.04), 
    InflationTrimmedMeanEq(43.78, 90), 
    InflationTrimmedMeanWeighted(17.63, 96.2), 
    InflationDynamicExclusion(0.5695, 2.6672), 
    InflationCoreMai(MaiFP([0, 0.29, 0.81, 0.98, 1])), 
    InflationCoreMai(MaiF([0, 0.29, 0.78, 0.98, 1])), 
    InflationCoreMai(MaiG([0, 0.28, 0.39, 0.98, 1])), 
)

# Trayectorias de entrenamiento 
tray_infl = pargentrayinfl(inflfn, resamplefn, trendfn, gtdata_eval; K = 1_000)

# Obtener la trayectoria paramétrica de inflación 
param = InflationParameter(InflationTotalRebaseCPI(60), resamplefn, trendfn)
tray_infl_param = param(gtdata_eval)

# Obtener ponderaciones para conjunto de entrenamiento 
a_ls = combination_weights(tray_infl, tray_infl_param)
a_ridge = ridge_combination_weights(tray_infl, tray_infl_param, 0.75) 
a_lasso, _ = lasso_combination_weights(tray_infl, tray_infl_param, 0.5)


## Configurar períodos de evaluación para período de validación cruzada

cvperiod = EvalPeriod(Date(2017, 1), Date(2018, 12), "cv1718")

CV_DATE = Date(2018, 12)
gtdata_cv = gtdata[CV_DATE]

# Trayectorias y e inflación paramétrica para el período de validación cruzada 
tray_infl_eval = pargentrayinfl(inflfn, resamplefn, trendfn, gtdata_cv; K = 1_000)
tray_infl_param_eval = param(gtdata_cv)

# Máscara de períodos de evaluación 
mask = eval_periods(gtdata_cv, cvperiod)

# Obtener trayectorias combinadas para evaluación 
tray_infl_opt_ls = sum(tray_infl_eval .* a_ls', dims=2)
tray_infl_opt_ridge = sum(tray_infl_eval .* a_ridge', dims=2)
tray_infl_opt_lasso = sum(tray_infl_eval .* a_lasso', dims=2)

# Evaluación en período de validación cruzada 
mse_cv_ls = eval_metrics(tray_infl_opt_ls[mask, :, :], tray_infl_param_eval[mask], short=true)[:mse] #1.5332
mse_cv_ridge = eval_metrics(tray_infl_opt_ridge[mask, :, :], tray_infl_param_eval[mask], short=true)[:mse] # 1.4072
mse_cv_lasso = eval_metrics(tray_infl_opt_lasso[mask, :, :], tray_infl_param_eval[mask], short=true)[:mse] # 1.2477


## Evaluación en período de prueba 

TEST_DATE = Date(2020, 12)
gtdata_test = gtdata[TEST_DATE]

# Trayectorias y e inflación paramétrica para el período de validación cruzada 
tray_infl_test = pargentrayinfl(inflfn, resamplefn, trendfn, gtdata_test; K = 1_000)
tray_infl_param_test = param(gtdata_test)

# Máscara de períodos de evaluación 
testperiod = EvalPeriod(Date(2019, 1), Date(2020, 12), "test1920")
mask = eval_periods(gtdata_test, testperiod)

# Obtener trayectorias combinadas para evaluación 
tray_infl_opt_test_ls = sum(tray_infl_test .* a_ls', dims=2)
tray_infl_opt_test_ridge = sum(tray_infl_test .* a_ridge', dims=2)
tray_infl_opt_test_lasso = sum(tray_infl_test .* a_lasso', dims=2)

# Evaluación en período de validación cruzada 
mse_cv_ls = eval_metrics(tray_infl_opt_test_ls[mask, :, :], tray_infl_param_test[mask], short=true)[:mse] #0.9066
mse_cv_ridge = eval_metrics(tray_infl_opt_test_ridge[mask, :, :], tray_infl_param_test[mask], short=true)[:mse] # 0.7835
mse_cv_lasso = eval_metrics(tray_infl_opt_test_lasso[mask, :, :], tray_infl_param_test[mask], short=true)[:mse] # 0.8556

# El mejor método fuera de muestra parece ser el de Ridge, sin embargo, Lasso también es mejor que la solución de mínimos cuadrados. 
weightsdf = DataFrame(ls = a_ls, ridge = a_ridge, lasso = a_lasso)