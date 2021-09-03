using DrWatson
@quickactivate "HEMI" 

using HEMI 

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

# Medidas óptimas del escenario E 
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

# Períodos para validación cruzada 
CV_PERIODS = (
    EvalPeriod(Date(2013, 1), Date(2014, 12), "cv1314"),
    EvalPeriod(Date(2014, 1), Date(2015, 12), "cv1415"),
    EvalPeriod(Date(2015, 1), Date(2016, 12), "cv1516"),
    EvalPeriod(Date(2016, 1), Date(2017, 12), "cv1617"),
    EvalPeriod(Date(2017, 1), Date(2018, 12), "cv1718")
)

# Período de prueba 
TEST_PERIOD = EvalPeriod(Date(2019, 1), Date(2020, 12), "test1920")

cvconfig = CrossEvalConfig(
    inflfn, 
    resamplefn, 
    trendfn, 
    paramfn, 
    125_000, 
    CV_PERIODS
)

testconfig = CrossEvalConfig(
    inflfn, 
    resamplefn, 
    trendfn, 
    paramfn, 
    125_000, 
    TEST_PERIOD
)

## Generar datos de simulación para algoritmo de validación cruzada
# La función makesim genera un diccionario con trayectorias de inflación y trayectorias paramétricas generadas datos en diferentes subperíodos. 

cvdata, _ = produce_or_load(cv_savepath, cvconfig) do config 
    makesim(gtdata, config)
end

testdata, _ = produce_or_load(test_savepath, testconfig) do config 
    makesim(gtdata, config)
end
