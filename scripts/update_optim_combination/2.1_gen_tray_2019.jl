######################################################################
## NOTA: EL PROPÓSITO  DE LA GENERACIÓN DE ESTAS TRAYECTORIAS ES ÚNICA
##       Y EXCLUSIVAMENTE  PARA  LA EVALUACIÓN DE MEDIDAS DE INFLACIÓN
##       EN EL PERÍODO DE ÓPTIMIZACIÓN DE LAS LAS MEDIDAS INDIVIDUALES
##       DESDE 2001 HASTA 2019 EN EL CASO DE LA SUBYACENTE ÓPTIMA 2023
######################################################################
using DrWatson
@quickactivate "HEMI"

using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

genconfig = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 2),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :traindate => Date(2019, 12),
    :nsim => 125_000
)

################################################################################
########################### TRAYECTORIAS MSE ###################################
################################################################################

savepath = datadir("results", "tray_infl_2019", "mse")

inflfn_mse = [
    InflationCoreMaiFP([0.276032, 0.718878, 0.757874]),
    InflationCoreMaiF([0.382601, 0.667259, 0.82893]),
    InflationCoreMaiG([0.0588968, 0.271835, 0.742957, 0.771684]),
    InflationFixedExclusionCPI((
       [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161],
       [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184]
    )),
    InflationPercentileEq(0.7195656),
    InflationPercentileWeighted( 0.69855756), 
    InflationTrimmedMeanEq([57.0, 84.0]),  # POR RECOMENDACION DE RCCP
    InflationTrimmedMeanWeighted([20.5129, 95.9781]),
    InflationDynamicExclusion([0.3372, 1.8109])
]

config =  merge(genconfig, Dict(:inflfn => inflfn_mse)) |> dict_list

run_batch(GTDATA, config, savepath; savetrajectories = true)

################################################################################
########################## TRAYECTORIAS ABSME ##################################
################################################################################

savepath = datadir("results", "tray_infl_2019", "absme")

inflfn_me = [
    InflationCoreMaiFP([0.3845888666524634, 0.4295691350270274, 0.5743281227047974, 0.8543536613832147]),
    InflationCoreMaiF([0.17038605093873466, 0.4017265098735232, 0.8452449697043789]),
    InflationCoreMaiG([0.14835730457573407, 0.3150866710451448, 0.5267416375693601, 0.6158789355387055, 0.7764662307149562]),
    InflationFixedExclusionCPI((
       [35, 30, 190, 36, 37, 40, 31, 104, 162],
       [29, 31, 116, 39, 46, 40]
    )),
    InflationPercentileEq(0.7192383),
    InflationPercentileWeighted(0.7022669), 
    InflationTrimmedMeanEq([33.4117, 93.7347]),
    InflationTrimmedMeanWeighted([32.1643, 93.2568]),
    InflationDynamicExclusion([1.0482, 3.4888])
]

config =  merge(genconfig, Dict(:inflfn => inflfn_me)) |> dict_list

run_batch(GTDATA, config, savepath; savetrajectories = true)


################################################################################
########################## TRAYECTORIAS CORR ###################################
################################################################################

savepath = datadir("results", "tray_infl_2019", "corr")

inflfn_corr = [
    InflationCoreMaiFP([0.25752, 0.506395, 0.749041]),
    InflationCoreMaiF([0.252018, 0.502175, 0.742866]),
    InflationCoreMaiG([0.260524, 0.503361, 0.746734]),
    InflationFixedExclusionCPI((
       [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161],
       [
           29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185,
           34, 184, 25, 38, 37, 229, 32, 45, 3, 33, 44, 237, 274, 19, 10,
           42, 24, 15, 59, 43, 27, 275, 61, 115, 23, 71, 26, 113, 49, 268,
           236, 213, 117, 20, 36, 9
       ]
    )),
    InflationPercentileEq(0.80864954),
    InflationPercentileWeighted(0.80995136), 
    InflationTrimmedMeanEq([55.0, 92.0]),
    InflationTrimmedMeanWeighted([53.5550, 96.4679]),
    InflationDynamicExclusion([0.46, 4.97])
]

config =  merge(genconfig, Dict(:inflfn => inflfn_corr)) |> dict_list

run_batch(GTDATA, config, savepath; savetrajectories = true)
