using DrWatson
@quickactivate "HEMI"

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI


include("grid_batch.jl")
include("plot_grid.jl")
include("grid_optim.jl")

grid_batch(gtdata,InflationTrimmedMeanEq, ResampleScrambleVarMonths(), TrendRandomWalk(),10_000, 45:75, 70:100,InflationTotalRebaseCPI(36,2),Date(2020,12))
grid_batch(gtdata,InflationTrimmedMeanWeighted, ResampleScrambleVarMonths(), TrendRandomWalk(),10_000, 5:35, 70:100,InflationTotalRebaseCPI(36,2),Date(2020,12))


dir_list = ["InflationTrimmedMeanEq\\Esc-B\\MTEq_SVM_RW_Rebase36_N10000_2020-12", "InflationTrimmedMeanWeighted\\Esc-B\\MTW_SVM_RW_Rebase36_N10000_2020-12"]

plot_grid.(dir_list,:corr);




grid_optim(dir_list[1],gtdata,125_000,7)
grid_optim(dir_list[2],gtdata,125_000,7)




