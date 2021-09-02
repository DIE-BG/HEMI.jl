using DrWatson
@quickactivate "HEMI" 

using DataFrames

## Se carga el módulo de `Distributed` para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Directorios de resultados 
cv_savepath = datadir("results", "mse-combination", "Esc-E", "cvdata")
test_savepath = datadir("results", "mse-combination", "Esc-E", "testdata")

## Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk() 
paramfn = InflationTotalRebaseCPI(60)

inflfn = EnsembleFunction(
    InflationPercentileEq(71.43), 
    InflationPercentileWeighted(69.04), 
    InflationTrimmedMeanEq(43.78, 90), 
    InflationTrimmedMeanWeighted(17.63, 96.2), 
    InflationDynamicExclusion(0.5695, 2.6672), 
    InflationFixedExclusionCPI(
        [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 
        21, 163, 3, 4, 97, 2, 27, 1, 191, 188], [29, 46, 39, 31, 116]),
    InflationCoreMai(MaiFP([0, 0.2878, 0.8092, 0.9827, 1])), 
    InflationCoreMai(MaiF([0, 0.2917, 0.7782, 0.9817, 1])), 
    InflationCoreMai(MaiG([0, 0.2836, 0.3892, 0.9845, 1])), 
)

CV_PERIODS = (
    EvalPeriod(Date(2013, 1), Date(2014, 12), "cv1314"),
    EvalPeriod(Date(2014, 1), Date(2015, 12), "cv1415"),
    EvalPeriod(Date(2015, 1), Date(2016, 12), "cv1516"),
    EvalPeriod(Date(2016, 1), Date(2017, 12), "cv1617"),
    EvalPeriod(Date(2017, 1), Date(2018, 12), "cv1718")
)

TEST_PERIOD = EvalPeriod(Date(2019, 1), Date(2020, 12), "test1920")

cvconfig = CrossEvalConfig(
    inflfn, 
    resamplefn, 
    trendfn, 
    paramfn, 
    10_000, 
    CV_PERIODS
)

testconfig = CrossEvalConfig(
    inflfn, 
    resamplefn, 
    trendfn, 
    paramfn, 
    10_000, 
    TEST_PERIOD
)

## Generar datos de simulación para algoritmo de validación cruzada
# La función makesim genera un diccionario con trayectorias de inflación y trayectorias paramétricas generadas datos en diferentes subperíodos. 

# cvdata = makesim(gtdata, cvconfig)
cvdata, _ = produce_or_load(cv_savepath, cvconfig, c -> makesim(gtdata, c))
testdata, _ = produce_or_load(test_savepath, testconfig, c -> makesim(gtdata, c))

## Datos de entrenamiento 
TRAIN_DATE = Date(2018,12)
gtdata_train = gtdata[TRAIN_DATE]

## Función para obtener error de validación cruzada utilizando CrossEvalConfig 

function crossvalidate(crossvaldata::Dict{String}, config::CrossEvalConfig, weightsfunction)

    function getkey(prefix, date) 
        fmt = dateformat"yy" 
        prefix * "_" * Dates.format(date, fmt)
    end

    cv_mse = zeros(Float32, length(config.evalperiods))

    # Obtener parámetro de inflación 
    for (i, evalperiod) in enumerate(config.evalperiods)
    
        @info "Ejecutando iteración $i de validación cruzada" evalperiod 

        # Obtener los datos de entrenamiento y validación 
        traindate = evalperiod.startdate - Month(1)
        cvdate = evalperiod.finaldate
        
        train_tray_infl = crossvaldata[getkey("infl", traindate)]
        train_tray_infl_param = crossvaldata[getkey("param", traindate)]
        train_dates = crossvaldata[getkey("dates", traindate)]
        cv_tray_infl = crossvaldata[getkey("infl", cvdate)]
        cv_tray_infl_param = crossvaldata[getkey("param", cvdate)]
        cv_dates = crossvaldata[getkey("dates", cvdate)]

        # Ponderadores 
        a = weightsfunction(train_tray_infl, train_tray_infl_param)
        println(a)

        # Máscara de períodos de evaluación 
        mask = evalperiod.startdate .<= cv_dates .<= evalperiod.finaldate

        # Obtener métrica de evaluación en subperíodo de CV 
        cv_tray_infl_opt = sum(cv_tray_infl .* a', dims=2)
        mse_cv = @views eval_metrics(cv_tray_infl_opt[mask, :, :], cv_tray_infl_param[mask], short=true)[:mse]
        cv_mse[i] = mse_cv
        # test_mse = sum(x -> x^2, (cv_tray_infl .* a') .- cv_tray_infl_param, dims=2)
        # println(test_mse)

        @info "MSE de validación cruzada:" evalperiod mse_cv
    
    end

    cv_mse

end

cv_ls = crossvalidate(cvdata, cvconfig, combination_weights)
# 0.7869098
# 0.47194207
# 0.44733062
# 0.6802227
# 0.8701134
# ------------
# cv: 0.6513037f0

test_ls = crossvalidate(testdata, testconfig, combination_weights)
# weights: [6.580605, -2.405299, -5.39225, 2.1810615, -1.1393241, -0.16767445, 1.0078117, 0.4949687]
# test: 0.701053


## 

cv_ridge1 = crossvalidate(cvdata, cvconfig, 
    (t,p) -> ridge_combination_weights(t, p, 0.25)) 

# 0.9587095
# 0.60787463
# 0.6603935
# 1.1036613
# 1.2359673
# ----------
# cv: 0.9133212f0

crossvalidate(testdata, testconfig, 
    (t,p) -> ridge_combination_weights(t, p, 0.25))
# weights: [0.38536894, -0.23844618, 0.11278257, -0.0899095, -0.19451751, 0.20697166, 0.46780774, 0.39144528]
# test: 0.6541514

cv_ridge2 = crossvalidate(cvdata, cvconfig, 
    (t,p) -> ridge_combination_weights(t, p, 0.75))

# 0.690221
# 0.57258
# 0.62942594
# 1.133759
# 1.078821
# ---------   
# cv: 0.82096136f0

crossvalidate(testdata, testconfig, 
    (t,p) -> ridge_combination_weights(t, p, 0.75))

# test: 0.6800277


function lasso_estimation(t, p)
    a, _ = lasso_combination_weights(t, p, 0.25, maxiterations=1000, alpha=0.001)
    a
end

cv_lasso = crossvalidate(cvdata, cvconfig, lasso_estimation)
# 0.56710696
# 0.5807457
# 0.6405771
# 1.0386564
# 0.73496526
# -----------
# cv: 0.7124103f0


crossvalidate(testdata, testconfig, lasso_estimation)
# [0.12024018, 0.0, 0.12573409, 0.0, 0.0, 0.10783642, 0.22353297, 0.3683994]
# test: 0.81518936