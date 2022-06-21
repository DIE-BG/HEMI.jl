using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain


savepath = datadir("results", "tray_infl", "mse")
tray_dir = joinpath(savepath, "tray_infl")

gtdata_eval = GTDATA[Date(2019, 12)]

df_results = collect_results(savepath)

@chain df_results begin 
    select(:measure, :mse)
end

# DataFrame de combinación 
combine_df = @chain df_results begin 
    select(:measure, :mse, :inflfn, 
        :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path
    )
    sort(:mse)
end

tray_infl = mapreduce(hcat, combine_df.tray_path) do path
    load(path, "tray_infl")
end

resamplefn = df_results[1, :resamplefn]
trendfn = df_results[1, :trendfn]
paramfn = df_results[1, :paramfn]
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)

functions = combine_df.inflfn
components_mask = [!(fn isa InflationFixedExclusionCPI) for fn in functions]

combine_period = EvalPeriod(Date(2011, 12), Date(2019, 12), "combperiod") 
periods_filter = eval_periods(gtdata_eval, combine_period)

a_optim = combination_weights(
    tray_infl[:, components_mask, :],
    tray_infl_pob 
)