using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain


savepath = datadir("results", "tray_infl", "corr")
tray_dir = joinpath(savepath, "tray_infl")

combination_savepath  = datadir("results","optim_combination","corr")

gtdata_eval = GTDATA[Date(2021, 12)]

df_results = collect_results(savepath)

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
paramfn = df_results[1, :paramfn]
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

#Construccion de la MAI optima
mai_components = [fn isa InflationCoreMai for fn in functions]
mai_weights = a_optim[mai_components]/sum(a_optim[mai_components])
mai_fns = functions[mai_components]

optmai_corr2022b = CombinationFunction(
    mai_fns..., 
    mai_weights, 
    "MAI óptima CORR 2022b"
)

non_mai_weights = a_optim[.!mai_components]
non_mai_fns = functions[.!mai_components]

final_weights = vcat(non_mai_weights, sum(a_optim[mai_components])) 
final_fns     = vcat(non_mai_fns, optmai)

optcorr2022b = CombinationFunction(
    final_fns...,
    final_weights, 
    "Subyacente óptima CORR 2022b"
)

wsave(joinpath(combination_savepath,"optcorr2022b.jld2"), "optcorr2022b", optcorr2022b , "optmai_corr2022b", optmai_corr2022b)

# ┌───────────────────────────────────────────────┬───────────┐
# │                                       measure │   weights │
# │                                        String │   Float32 │
# ├───────────────────────────────────────────────┼───────────┤
# │                     Percentil ponderado 69.86 │ 0.0710044 │
# │   Inflación de exclusión dinámica (0.4, 2.11) │ 0.0458298 │
# │       Media Truncada Ponderada (20.61, 95.98) │  0.140068 │
# │ Exclusión fija de gastos básicos IPC (14, 51) │       0.0 │
# │                 Percentil equiponderado 71.96 │  0.297154 │
# │    Media Truncada Equiponderada (28.5, 95.16) │  0.253535 │
# │                         MAI óptima CORR 2022b │  0.192491 │
# └───────────────────────────────────────────────┴───────────┘

# ┌────────────────────────────────────┬─────────────┐
# │                            measure │     weights │
# │                             String │     Float32 │
# ├────────────────────────────────────┼─────────────┤
# │  MAI (G,5,[0.3, 0.35, 0.52, 0.68]) │  0.00372133 │
# │ MAI (FP,5,[0.02, 0.12, 0.37, 0.6]) │ 0.000573439 │
# │        MAI (F,4,[0.13, 0.24, 0.8]) │    0.995705 │
# └────────────────────────────────────┴─────────────┘