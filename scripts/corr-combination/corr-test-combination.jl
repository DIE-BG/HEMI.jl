##  ----------------------------------------------------------------------------
#   Evaluación de variantes de combinación de óptimas del escenario E (hasta
#   diciembre de 2018), utilizando los ponderadores de mínimos cuadrados
#   ----------------------------------------------------------------------------
using DrWatson
@quickactivate "HEMI" 

using HEMI 
using Plots
using DataFrames, Chain, PrettyTables

## Directorios de resultados 
config_savepath = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI")
cv_savepath = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI", "cvdata")
test_savepath = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI", "testdata")
results_path = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI", "results")
plots_path = mkpath(plotsdir("mse-combination", "Esc-E-Scramble-OptMAI", "ls"))

##  ----------------------------------------------------------------------------
#   Cargar los datos de validación y prueba producidos con generate_cv_data.jl
#   ----------------------------------------------------------------------------
cvconfig, testconfig = wload(
    joinpath(config_savepath, "cv_test_config.jld2"), 
    "cvconfig", "testconfig"
)
    
testdata = wload(joinpath(test_savepath, savename(testconfig)))
tray_infl = testdata["infl_20"]
tray_param = testdata["param_20"]


## Función de combinación para correlación 

gtdata_20 = gtdata[Date(2020, 12)]
weights_period = GT_EVAL_B10
periods_mask = eval_periods(gtdata_20, weights_period)
mask = [!(fn isa InflationFixedExclusionCPI) for fn in testconfig.inflfn.functions]

## Ponderadores de correlación 
t1 = metric_combination_weights(tray_infl[periods_mask, mask, :], tray_param[periods_mask], max_iterations = 250, metric = :corr)
t2 = metric_combination_weights(tray_infl[periods_mask, :, :], tray_param[periods_mask], max_iterations = 250, metric = :corr)

combination_metrics(tray_infl[periods_mask, mask, :], tray_param[periods_mask], t1)[:corr]
combination_metrics(tray_infl[periods_mask, :, :], tray_param[periods_mask], t2)[:corr]


## Ponderadores de absme
t1 = metric_combination_weights(tray_infl[periods_mask, mask, :], tray_param[periods_mask], max_iterations = 250, metric = :absme)
t2 = metric_combination_weights(tray_infl[periods_mask, :, :], tray_param[periods_mask], max_iterations = 1000, metric = :absme, sum_abstol = 1f-4)

combination_metrics(tray_infl[periods_mask, mask, :], tray_param[periods_mask], t1)[:absme]
combination_metrics(tray_infl[periods_mask, :, :], tray_param[periods_mask], t2)[:absme]

