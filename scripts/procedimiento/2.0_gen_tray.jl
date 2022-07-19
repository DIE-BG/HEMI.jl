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
    :traindate => Date(2021, 12),
    :nsim => 125_000
)

################################################################################
########################### TRAYECTORIAS MSE ###################################
################################################################################

savepath = datadir("results", "tray_infl", "mse")

inflfn_mse = [
    #InflationCoreMaiFP([0.276032, 0.718878, 0.757874]),
    #InflationCoreMaiF([0.382601, 0.667259, 0.82893]),
    #InflationCoreMaiG([0.0588968, 0.271835, 0.742957, 0.771684]),
    #InflationFixedExclusionCPI((
    #    [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161],
    #    [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184]
    #)),
    #InflationPercentileEq(0.7195656),
    #InflationPercentileWeighted( 0.69855756), 
    InflationTrimmedMeanEq([57.0, 84.0]),  # POR RECOMENDACION DE RCCP
    #InflationTrimmedMeanWeighted([20.5129, 95.9781]),
    #InflationDynamicExclusion([0.3372, 1.8109])
]

config =  merge(genconfig, Dict(:inflfn => inflfn_mse)) |> dict_list

run_batch(GTDATA, config, savepath; savetrajectories = true)

################################################################################
########################## TRAYECTORIAS ABSME ##################################
################################################################################

savepath = datadir("results", "tray_infl", "absme")

inflfn_me = [
    #InflationCoreMaiFP([0.0584298, 0.0954737, 0.245661, 0.291486, 0.33868, 0.478096, 0.846356, 0.97829, 0.999177]),
    #InflationCoreMaiF([0.0958119, 0.155845, 0.485898, 0.719933, 0.795759, 0.869557, 0.898225, 0.99026, 0.990358]),
    #InflationCoreMaiG([0.00474738, 0.23966, 0.253779, 0.339322, 0.443259, 0.476159, 0.499084, 0.736747, 0.999839]),
    #InflationFixedExclusionCPI((
    #    [35, 30, 190, 36, 37, 40, 31, 104, 162],
    #    [29, 31, 116, 39, 46, 40]
    #)),
    #InflationPercentileEq(0.7192383),
    #InflationPercentileWeighted(0.7022669), 
    #InflationTrimmedMeanEq([33.4117, 93.7347]),
    #InflationTrimmedMeanWeighted([32.1643, 93.2568]),
    #InflationDynamicExclusion([1.0482, 3.4888])
]

#config =  merge(genconfig, Dict(:inflfn => inflfn_me)) |> dict_list

#run_batch(GTDATA, config, savepath; savetrajectories = true)


################################################################################
########################## TRAYECTORIAS CORR ###################################
################################################################################

savepath = datadir("results", "tray_infl", "corr")

inflfn_corr = [
    #InflationCoreMaiFP([0.0216123, 0.117179, 0.373563, 0.60367]),
    #InflationCoreMaiF([0.13028, 0.243783, 0.798061]),
    #InflationCoreMaiG([0.298485, 0.349466, 0.521438, 0.676048]),
    #InflationFixedExclusionCPI((
    #    [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161],
    #    [
    #        29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185,
    #        34, 184, 25, 38, 37, 229, 32, 45, 3, 33, 44, 237, 274, 19, 10,
    #        42, 24, 15, 59, 43, 27, 275, 61, 115, 23, 71, 26, 113, 49, 268,
    #        236, 213, 117, 20, 36, 9
    #    ]
    #)),
    #InflationPercentileEq(0.80864954),
    #InflationPercentileWeighted(0.80995136), 
    #InflationTrimmedMeanEq([55.0, 92.0]),
    #InflationTrimmedMeanWeighted([53.5550, 96.4679]),
    #InflationDynamicExclusion([0.46, 4.97])
]

#config =  merge(genconfig, Dict(:inflfn => inflfn_corr)) |> dict_list

#run_batch(GTDATA, config, savepath; savetrajectories = true)

