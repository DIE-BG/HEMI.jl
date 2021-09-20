using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Se carga el módulo de `Distributed` para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Directorios de resultados 
config_savepath = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI")
cv_savepath = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI", "cvdata")
test_savepath = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI", "testdata")

# Funciones de inflación óptima MSE 2019: optmse2019 y optmai2019
include(scriptsdir("mse-combination-2019", "optmse2019.jl"))


##  ----------------------------------------------------------------------------
#   Configuración para evaluación de validación cruzada de combinaciones
#   lineales con la métrica de error cuadrático medio 
#   ----------------------------------------------------------------------------

## Se obtiene la función de inflación, de remuestreo y de tendencia a aplicar
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk() 
paramfn = InflationTotalRebaseCPI(36, 2)

# Medidas óptimas a diciembre de 2018
inflfn = InflationEnsemble(
    InflationPercentileEq(72.4), 
    InflationPercentileWeighted(70), 
    # InflationTrimmedMeanEq(57.5, 84.0), 
    # InflationTrimmedMeanWeighted(15.0, 97.0), 
    InflationDynamicExclusion(0.3158, 1.6832), 
    InflationFixedExclusionCPI(
        [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], 
        [29, 116, 31, 46, 39, 40, 186, 30, 35, 185, 197, 34, 48, 184]),
    # optmai2019, 
)

# Períodos para validación cruzada 
CV_PERIODS = (
    EvalPeriod(Date(2013, 1), Date(2014, 12), "cv1314"),
    EvalPeriod(Date(2014, 1), Date(2015, 12), "cv1415"),
    EvalPeriod(Date(2015, 1), Date(2016, 12), "cv1516"),
    EvalPeriod(Date(2016, 1), Date(2017, 12), "cv1617"),
    EvalPeriod(Date(2017, 1), Date(2018, 12), "cv1718"),
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

wsave(joinpath(config_savepath, "cv_test_config.jld2"), 
    "cvconfig", cvconfig, 
    "testconfig", testconfig
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
