using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Se carga el módulo de `Distributed` para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Directorios de resultados 
config_savepath = datadir("results", "mse-combination", "Esc-E2")
cv_savepath = datadir("results", "mse-combination", "Esc-E2", "cvdata")
test_savepath = datadir("results", "mse-combination", "Esc-E2", "testdata")

# Resultados de combinación MAI: combinación de medidas estándar de inflación
# subyacente MAI del escenario E
mai_weights_file = datadir("results", "CoreMai", "Esc-E", "Standard", "mse-weights", "mai-mse-weights.jld2")

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
mai_results = wload(mai_weights_file, "mai_mse_weights")

maifn = InflationCombination(
    mai_results.inflfn...,
    mai_results.analytic_weight, 
    "MAI óptima MSE 2020"
)


## Resto de funciones de inflación subyacente 
inflfn = InflationEnsemble(
    InflationPercentileEq(71.43), 
    InflationPercentileWeighted(69.04), 
    InflationTrimmedMeanEq(43.78, 90), 
    InflationTrimmedMeanWeighted(17.63, 96.2), 
    InflationDynamicExclusion(0.5695, 2.6672), 
    InflationFixedExclusionCPI(
        [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 
        21, 163, 3, 4, 97, 2, 27, 1, 191, 188], [29, 46, 39, 31, 116]),
    maifn 
)

## Combinación óptima simple

combfn = InflationCombination(
    inflfn, 
    # ones(Float32, 7) / 7, 
    Float32[1, 1, 1, 1, 1, 0, 1] / 6,
    "Subyacente óptima MSE 2020 (naïve)" 
)

# include(scriptsdir("mse-combination-2019", "optmse2019.jl"))
# plot(inflfn, gtdata, alpha = 0.5)
# plot!(combfn, gtdata, linewidth=2, color=:black)
# plot!(optmse2019, gtdata, linewidth=2, color=:blue)
# hline!([3], label=false, alpha=0.4, color=:gray)


## Configuración para validación cruzada 

# Períodos de validación cruzada
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
