using DrWatson
@quickactivate :HEMI

# Cargar el módulo de Distributed para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Path 
results_savepath = datadir("results", "mse-combination", "optmse2022-components")
mai_results_savepath = datadir("results", "mse-combination", "optmse2022-mai-components")

# Load optimal linear combination of inflation measures
#     exports optmai2018 and optmse2022
include(scriptsdir("mse-combination", "optmse2022.jl"))

## TIMA settings 

# Here we use synthetic base changes every 36 months, because this is the population trend 
# inflation time series used in the optimization of the Optimal Linear MSE Combination 2022

# Resampling technique, parametric inflation formula and trend function 
paramfn = InflationTotalRebaseCPI(36, 2)
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()

# CPI data
data = GTDATA[Date(2020, 12)]

## Configuration to generate components' trajectories
config = Dict(
    :inflfn => [ optmse2022.ensemble.functions... ], 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 10_000, 
    :traindate => Date(2020, 12)) |> dict_list

# Execute simulation batch to generate trajectories and assess core inflation measures
run_batch(data, config, results_savepath)

## Configuration to generate HES components' trajectories
config = Dict(
    :inflfn => [ optmai2018.ensemble.functions... ], 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 10_000, 
    :traindate => Date(2020, 12)) |> dict_list

# Execute simulation batch to generate trajectories and assess core inflation measures
run_batch(data, config, mai_results_savepath)
