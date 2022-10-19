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

data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")

################################################################################
########################### TRAYECTORIAS MSE ###################################
################################################################################

savepath = datadir("results","no_trans", "tray_infl_2019", "mse")

inflfn_mse = [
    InflationFixedExclusionCPI((
       [32, 8, 35, 17, 16, 18, 33, 30, 29, 28, 41, 5, 7],
       [28, 42, 47, 64, 65, 6, 46, 63, 58, 41, 32, 37, 68, 20, 9, 30, 66, 59] 
    )),
    InflationPercentileEq(0.71844846),
    InflationPercentileWeighted( 0.6933576), 
    InflationTrimmedMeanEq([24.7089, 96.2772]),  # POR RECOMENDACION DE RCCP
    InflationTrimmedMeanWeighted([11.2034, 99.5524]),
    InflationDynamicExclusion([0.8061, 3.7844])
]

config =  merge(genconfig, Dict(:inflfn => inflfn_mse)) |> dict_list

run_batch(NOT_GTDATA, config, savepath; savetrajectories = true)

################################################################################
########################## TRAYECTORIAS ABSME ##################################
################################################################################

savepath = datadir("results","no_trans", "tray_infl_2019", "absme")

inflfn_me = [
    InflationFixedExclusionCPI((
        [32, 8, 35, 17],
        [28, 42]
    )),
    InflationPercentileEq(0.72949016),
    InflationPercentileWeighted(0.6988363), 
    InflationTrimmedMeanEq([26.1060, 95.6085]),
    InflationTrimmedMeanWeighted([20.1080, 98.1556]),
    InflationDynamicExclusion([0.7181, 4.1261])
]

config =  merge(genconfig, Dict(:inflfn => inflfn_me)) |> dict_list

run_batch(NOT_GTDATA, config, savepath; savetrajectories = true)


################################################################################
########################## TRAYECTORIAS CORR ###################################
################################################################################

savepath = datadir("results","no_trans", "tray_infl_2019", "corr")

inflfn_corr = [
    InflationFixedExclusionCPI((
       [32, 8, 35, 17, 16, 18, 33, 30, 29, 28, 41, 5, 7],
       [
           28, 42, 47, 64, 65, 6, 46, 63, 58, 41, 32, 37, 68, 20, 9,
           30, 66, 59, 40, 24, 27, 12, 11, 34, 69, 60, 18, 21, 5, 56,
           4, 2, 54, 57, 29, 38, 1, 67, 17, 52, 7, 15, 36, 31, 53,
           16, 45, 26, 55, 35, 10, 19, 22, 13, 62, 44, 43
       ]
    )),
    InflationPercentileEq(0.7983739),
    InflationPercentileWeighted(0.82199615), 
    InflationTrimmedMeanEq([16.4109, 98.4531]),
    InflationTrimmedMeanWeighted([31.6960, 96.1078]),
    InflationDynamicExclusion([0.8468, 2.3203])
]

config =  merge(genconfig, Dict(:inflfn => inflfn_corr)) |> dict_list

run_batch(NOT_GTDATA, config, savepath; savetrajectories = true)