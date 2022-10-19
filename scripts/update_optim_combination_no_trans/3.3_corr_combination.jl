using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain


loadpath = datadir("results", "no_trans","tray_infl","corr")
tray_dir = joinpath(loadpath, "tray_infl")

combination_savepath  = datadir("results","no_trans","optim_combination","corr")

data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")

gtdata_eval = NOT_GTDATA[Date(2021, 12)]

df_results = collect_results(loadpath)

@chain df_results begin 
    select(:measure, :corr)
end

# DataFrame de combinación 
combine_df = @chain df_results begin 
    select(:measure, :corr, :inflfn, 
        :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path
    )
    sort(:corr)
end

tray_infl = mapreduce(hcat, combine_df.tray_path) do path
    load(path, "tray_infl")
end

resamplefn = df_results[1, :resamplefn]
trendfn = df_results[1, :trendfn]
paramfn = InflationTotalRebaseCPI(36, 3) #df_results[1, :paramfn]
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)

functions = combine_df.inflfn
components_mask = [!(fn isa InflationFixedExclusionCPI) for fn in functions]

combine_period = EvalPeriod(Date(2011, 12), Date(2021, 12), "combperiod") 
periods_filter = eval_periods(gtdata_eval, combine_period)

a_optim = metric_combination_weights(
    tray_infl[periods_filter, components_mask, :],
    tray_infl_pob[periods_filter],
    metric = :corr
)

#Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
insert!(a_optim, findall(.!components_mask)[1],0)

optcorr2023 = CombinationFunction(
    functions...,
    a_optim, 
    "Subyacente óptima CORR 2023"
)

wsave(joinpath(combination_savepath,"optcorr2023.jld2"), "optcorr2023", optcorr2023)

# using PrettyTables
# pretty_table(components(optcorr2023))
# ┌───────────────────────────────────────────────┬────────────┐
# │                                       measure │    weights │
# │                                        String │    Float32 │
# ├───────────────────────────────────────────────┼────────────┤
# │                      Percentil ponderado 82.2 │  0.0366308 │
# │                 Percentil equiponderado 79.84 │   0.254759 │
# │        Media Truncada Ponderada (31.7, 96.11) │ 3.94964e-6 │
# │  Inflación de exclusión dinámica (0.85, 2.32) │   0.291732 │
# │   Media Truncada Equiponderada (16.41, 98.45) │   0.416954 │
# │ Exclusión fija de gastos básicos IPC (13, 57) │        0.0 │
# └───────────────────────────────────────────────┴────────────┘
