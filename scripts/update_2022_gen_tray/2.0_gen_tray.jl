using DrWatson
@quickactivate "HEMI"
using HEMI

using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

include(scriptsdir("generate_optim_combination","2022","optmse2022.jl"))
include(scriptsdir("generate_optim_combination","2022","optabsme2022.jl"))
include(scriptsdir("generate_optim_combination","2022","optcorr2022.jl"))

general_savedir = datadir("results","2022_tray_infl")

genconfig = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 2),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :traindate => Date(2020, 12),
    :nsim => 25_000
)

################################################################################
########################### TRAYECTORIAS MSE ###################################
################################################################################

savepath = joinpath(general_savedir, "tray_infl", "mse")

inflfn_mse = [
    optmai2022,
    InflationFixedExclusionCPI((
    [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], 
    [29, 116, 31, 46, 39, 40, 186, 30, 35, 185, 197, 34, 48, 184]
    )),
    InflationPercentileEq(72.3966), 
    InflationPercentileWeighted(69.9966), 
    InflationTrimmedMeanEq(58.7573, 83.1520), 
    InflationTrimmedMeanWeighted(21.0019, 95.8886), 
    InflationDynamicExclusion(0.3158, 1.6832), 
]

config =  merge(genconfig, Dict(:inflfn => inflfn_mse)) |> dict_list

run_batch(GTDATA, config, savepath; savetrajectories = true)


################################################################################
########################## TRAYECTORIAS ABSME ##################################
################################################################################

savepath = joinpath(general_savedir, "tray_infl", "absme")

inflfn_me = [
    optmai2018_absme,
    InflationFixedExclusionCPI((
        [35, 30, 190, 36, 37, 40, 31, 104, 162], 
        [29, 116, 31, 46, 39, 40]
    )),
    InflationPercentileEq(0.716344f0), 
    InflationPercentileWeighted(0.695585f0), 
    InflationTrimmedMeanEq(35.2881f0, 93.4009f0), 
    InflationTrimmedMeanWeighted(34.1943f0, 93.0f0), 
    InflationDynamicExclusion(1.03194f0, 3.42365f0), 
]

config =  merge(genconfig, Dict(:inflfn => inflfn_me)) |> dict_list

run_batch(GTDATA, config, savepath; savetrajectories = true)


################################################################################
########################## TRAYECTORIAS CORR ###################################
################################################################################

savepath = joinpath(general_savedir, "tray_infl", "corr")

inflfn_corr = [
    optmai2018_corr,
    InflationFixedExclusionCPI((
        [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159], 
        [29, 116, 31, 46, 39, 40, 186, 30, 35, 185, 197, 34, 
            48, 184, 41, 47, 37, 22, 25, 229, 38, 32, 274, 3, 
            45, 44, 33, 237, 19, 10, 24, 275, 115, 15, 59, 42, 
            61, 43, 113, 49, 27, 71, 23, 268, 9, 36, 236, 78, 
            20, 213, 273, 26
        ]
    )),
    InflationPercentileEq(0.7725222f0), 
    InflationPercentileWeighted(0.809557f0), 
    InflationTrimmedMeanEq(55.90512f0, 92.17767f0), 
    InflationTrimmedMeanWeighted(46.443233f0, 98.54608f0), 
    InflationDynamicExclusion(0.4683226f0, 4.9745145f0), 
]

config =  merge(genconfig, Dict(:inflfn => inflfn_corr)) |> dict_list

run_batch(GTDATA, config, savepath; savetrajectories = true)



