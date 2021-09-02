using DrWatson
@quickactivate "HEMI" 

using HEMI 
using Plots
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


## Validación de método de mínimos cuadrados 
cv_ls = crossvalidate(cvdata, cvconfig, combination_weights)

test_ls = crossvalidate(testdata, testconfig, combination_weights)


## Validación cruzada de método de combinación Ridge

cv_ridge1 = crossvalidate(cvdata, cvconfig, 
    (t,p) -> ridge_combination_weights(t, p, 0.25)) 

crossvalidate(testdata, testconfig, 
    (t,p) -> ridge_combination_weights(t, p, 0.25))



λ_range = 0.1:0.1:10
mse_cv_ridge = map(λ_range) do λ
    mse_cv = crossvalidate(cvdata, cvconfig, 
        (t,p) -> ridge_combination_weights(t, p, λ), 
        show_status=false, 
        print_weights=false)
    mean(mse_cv)  
end
plot(λ_range, mse_cv_ridge, 
    label="Cross-validation MSE", 
    legend=:topleft)
lambda_ridge = λ_range[argmin(mse_cv_ridge)]
scatter!([lambda_ridge], [minimum(mse_cv_ridge)], label="λ min")

# Evaluación sobre conjunto de prueba 
crossvalidate(testdata, testconfig, 
    (t,p) -> ridge_combination_weights(t, p, lambda_ridge))



## Validación cruzada de método de combinación Lasso

lasso_estimation(λ) = (t,p) -> lasso_combination_weights(t, p, λ, alpha=0.001)


cv_lasso = crossvalidate(cvdata, cvconfig, 
    lasso_estimation(0.25))

crossvalidate(testdata, testconfig, lasso_estimation(0.25))

λ_range = 0.1:0.1:10
mse_cv_lasso = map(λ_range) do λ
    mse_cv = crossvalidate(cvdata, cvconfig, 
        (t,p) -> lasso_combination_weights(t, p, λ,
            alpha=0.001, show_status=false), 
        show_status=false, 
        print_weights=false)
    mean(mse_cv)  
end

plot(λ_range, mse_cv_lasso, 
    label="Cross-validation MSE", 
    legend=:topleft)

lambda_lasso = λ_range[argmin(mse_cv_lasso)]
scatter!([lambda_lasso], [minimum(mse_cv_lasso)], label="λ min")
    
crossvalidate(testdata, testconfig, lasso_estimation(lambda_lasso))



