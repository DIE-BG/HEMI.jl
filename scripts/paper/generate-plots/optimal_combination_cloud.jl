using DrWatson
@quickactivate :HEMI

# Cargar el módulo de Distributed para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

using DataFrames, Chain, PrettyTables
using CSV
using Plots

## Path 
results_savepath = datadir("results", "mse-combination", "optmse2022")
plots_savepath = mkpath(plotsdir("paper", "clouds", "optimal"))
csv_output = datadir("results", "paper-assessment", "clouds")

# Load optimal linear combination of inflation measures
include(scriptsdir("mse-combination", "optmse2022.jl"))

## TIMA settings 

# Resampling technique, parametric inflation formula and trend function 
paramfn = InflationTotalRebaseCPI(60)
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()

# CPI data
data = GTDATA[Date(2020, 12)]
dates = infl_dates(data)

# Population trend inflation series
param = InflationParameter(paramfn, resamplefn, trendfn)
trend_infl = param(data)

# Configuration to generate trajectories
config = Dict(
    :inflfn => optmse2022, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 10_000, 
    :traindate => Date(2020, 12)) |> dict_list

## Lote de simulación con los primeros 100 vectores de exclusión
# run_batch(data, config, results_savepath)

## Recolección de trayectorias de inflación
df_results = collect_results(joinpath(results_savepath, "tray_infl"))

## Load helper functions
include("plot-helpers.jl")

# Optimal MSE combination of core inflation cloudplots
periods = [
    EvalPeriod(Date(2001, 12), Date(2010, 12), "gt_b00"),
    EvalPeriod(Date(2011, 01), Date(2020, 12), "gt_b10"),
    CompletePeriod(),
]

optimalmse_traj = get_realizations(df_results, "COMBFN")
optimalmse_00 = cloudplot(optimalmse_traj, trend_infl, dates, "Optimal MSE combination", periods[1])
optimalmse_10 = cloudplot(optimalmse_traj, trend_infl, dates, "Optimal MSE combination", periods[2])
optimalmse_0010 = cloudplot(optimalmse_traj, trend_infl, dates, "Optimal MSE combination", periods[3]; ylims = (0,14))

savecloudplot(optimalmse_00, "OPTMSE22", periods[1], plots_savepath)
savecloudplot(optimalmse_10, "OPTMSE22", periods[2], plots_savepath)
savecloudplot(optimalmse_0010, "OPTMSE22", periods[3], plots_savepath)

# Anonymous plot for presentation
est2_0010 = cloudplot(optimalmse_traj, trend_infl, dates, "Inflation Estimator 2", periods[3]; ylims=(0,14))
savecloudplot(est2_0010, "InflEst2", periods[3], plots_savepath)

# Comparison with est1_0010 from cloud_trajectories

comp_est = plot(
    est1_0010, 
    est2_0010, 
    layout=(1,2),
    size=(1200, 800),
    left_margin=5 * Plots.mm,
    bottom_margin=5 * Plots.mm,
)

savecloudplot(comp_est, "ComparisonInflationEstimators", periods[3], plots_savepath)