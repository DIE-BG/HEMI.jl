using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Se carga el módulo de `Distributed` para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Directorios de resultados 
cv_savepath = datadir("results", "mse-combination", "Esc-E2", "cvdata")
test_savepath = datadir("results", "mse-combination", "Esc-E2", "testdata")

##  ----------------------------------------------------------------------------
#   Configuración para evaluación de validación cruzada de combinaciones
#   lineales con la métrica de error cuadrático medio 
#   ----------------------------------------------------------------------------

## Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk() 
paramfn = InflationTotalRebaseCPI(60)

# Medidas óptimas del escenario E 

## Funciones de inflación MAI
maifn = InflationEnsemble(
    InflationCoreMai(MaiF(4)),
    InflationCoreMai(MaiF(5)),
    InflationCoreMai(MaiF(10)),
    InflationCoreMai(MaiF(20)),
    InflationCoreMai(MaiF(40)),
    InflationCoreMai(MaiG(4)),
    InflationCoreMai(MaiG(5)),
    InflationCoreMai(MaiG(10)),
    InflationCoreMai(MaiG(20)),
    InflationCoreMai(MaiG(40)),
    # InflationCoreMai(MaiFP(4)),
    # InflationCoreMai(MaiFP(5)),
    # InflationCoreMai(MaiFP(10)),
    # InflationCoreMai(MaiFP(20)),
    # InflationCoreMai(MaiFP(40)),
)


tray_infl_mai = pargentrayinfl(maifn, ResampleScrambleVarMonths(), trendfn, gtdata[Date(2018, 12)]; K = 1000)

param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_param = param(gtdata[Date(2018, 12)])

w_mai = combination_weights(tray_infl_mai, tray_infl_param)

plot(maifn, gtdata)
plot!(InflationCombination(maifn, w_mai), gtdata, legend=false, linewidth=3, color=:black)

##
inflfn = EnsembleFunction(
    InflationPercentileEq(71.43), 
    InflationPercentileWeighted(69.04), 
    InflationTrimmedMeanEq(43.78, 90), 
    InflationTrimmedMeanWeighted(17.63, 96.2), 
    InflationDynamicExclusion(0.5695, 2.6672), 
    InflationFixedExclusionCPI(
        [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 
        21, 163, 3, 4, 97, 2, 27, 1, 191, 188], [29, 46, 39, 31, 116]),
    #InflationCombination(inflfn, [...]) 
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


##  ----------------------------------------------------------------------------
#   Generación de datos de simulación 
#
#   Generar datos de simulación para algoritmo de validación cruzada La función
#   makesim genera un diccionario con trayectorias de inflación y trayectorias
#   paramétricas generadas datos en diferentes subperíodos. 
#   ----------------------------------------------------------------------------

cvdata, _ = produce_or_load(cv_savepath, cvconfig) do config 
    makesim(gtdata, config)
end

testdata, _ = produce_or_load(test_savepath, testconfig) do config 
    makesim(gtdata, config)
end
