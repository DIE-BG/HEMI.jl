using DrWatson
@quickactivate :HEMI

using DataFrames
using Chain
using PrettyTables

# Load Distributed package to use parallel computing capabilities 
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Path 
mai_results_savepath = datadir("results", "mse-combination", "optmse2022-mai-components-18")

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
data = GTDATA[Date(2018, 12)]

# Population trend inflation series
param = InflationParameter(paramfn, resamplefn, trendfn)
trend_infl = param(data)

## Configuration to generate HES components' trajectories
config = Dict(
    :inflfn => [ optmai2018.ensemble.functions... ], 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 10_000, 
    :traindate => Date(2018, 12)) |> dict_list

# Execute simulation batch to generate trajectories and assess core inflation measures
# run_batch(data, config, mai_results_savepath)

## Load results
df_results = collect_results(mai_results_savepath)

# Obtain MSE results within optimization period
opt_results = @chain df_results begin
    select(:measure, :mse_bias, :mse_var, :mse_cov, :mse, :mse_std_error)
end

# Add optimal weights from the optmai2018 variable
hes_results = leftjoin(opt_results, components(optmai2018), on=:measure)
pretty_table(hes_results, tf=tf_latex_booktabs, formatters=ft_round(4))


## Obtain results for optimal combination within optimization period 

# Get the cube of trajectories to combine and obtain weights
combine_df = @chain df_results begin 
    select(:measure, :path)
    leftjoin(components(optmai2018), on=:measure)
end

tray_infl = mapreduce(hcat, combine_df.path) do path
    # Load array of trajectories for each measure
    tray_path = joinpath(dirname(path), "tray_infl", basename(path))
    @info "Loading trajectories file" tray_path
    load(tray_path, "tray_infl")
end

# Get the optimal combination trajectories and evaluate within optimization period
opthes_tray_infl = sum(tray_infl .* combine_df.weights'; dims=2)
opthes_metrics = eval_metrics(opthes_tray_infl, trend_infl)
opthes_df = DataFrame(opthes_metrics)
opthes_df[!, :measure] .= "Historically Expanded Sample Core"
opthes_df[!, :weights] .= missing

# Selected results of optimal HES combination
opthes_results = @chain opthes_df begin
    select(:measure, :mse_bias, :mse_var, :mse_cov, :mse, :mse_std_error, :weights)
end

# All final summary statistics
hes_final_df = [hes_results; opthes_results]
pretty_table(hes_final_df, tf=tf_latex_booktabs, formatters=ft_round(4))