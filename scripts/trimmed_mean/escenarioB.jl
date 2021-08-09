using DrWatson
@quickactivate "HEMI"
using HEMI


include("grid_batch.jl")
include("plot_grid.jl")

grid_batch(gtdata,InflationTrimmedMeanEq, ResampleScrambleVarMonths(), TrendRandomWalk(),10_000, 45:75, 70:100,InflationTotalRebaseCPI(36,2),Date(2020,12))
grid_batch(gtdata,InflationTrimmedMeanWeighted, ResampleScrambleVarMonths(), TrendRandomWalk(),10_000, 5:35, 70:100,InflationTotalRebaseCPI(36,2),Date(2020,12))


dir_list = ["MTEq_SVM_RW_Rebase36_N10000_2020-12", "MTW_SVM_RW_Rebase36_N10000_2020-12"]

plot_grid.(dir_list,:mse)

include("grid_optim.jl")


grid_optim(dir_list[1],gtdata,125_000,7)
grid_optim(dir_list[2],gtdata,125_000,7)




