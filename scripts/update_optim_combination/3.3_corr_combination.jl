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

optmai_corr2023 = CombinationFunction(
    mai_fns..., 
    mai_weights, 
    "MAI óptima CORR 2023"
)

non_mai_weights = a_optim[.!mai_components]
non_mai_fns = functions[.!mai_components]

final_weights = vcat(non_mai_weights, sum(a_optim[mai_components])) 
final_fns     = vcat(non_mai_fns, optmai_corr2023)

optcorr2023 = CombinationFunction(
    final_fns...,
    final_weights, 
    "Subyacente óptima CORR 2023"
)

wsave(joinpath(combination_savepath,"optcorr2023.jld2"), "optcorr2023", optcorr2023 , "optmai_corr2023", optmai_corr2023)


# pretty_table(components(optcorr2023))
# ┌───────────────────────────────────────────────┬────────────┐
# │                                       measure │    weights │
# │                                        String │    Float32 │
# ├───────────────────────────────────────────────┼────────────┤
# │                      Percentil ponderado 81.0 │ 1.30411e-6 │
# │  Inflación de exclusión dinámica (0.46, 4.97) │  0.0530187 │
# │ Exclusión fija de gastos básicos IPC (14, 51) │        0.0 │
# │       Media Truncada Ponderada (53.56, 96.47) │  0.0865183 │
# │                 Percentil equiponderado 80.86 │   0.291214 │
# │     Media Truncada Equiponderada (55.0, 92.0) │   0.248435 │
# │                          MAI óptima CORR 2023 │   0.320901 │
# └───────────────────────────────────────────────┴────────────┘

# pretty_table(components(optmai_corr2023))
# ┌───────────────────────────────┬────────────┐
# │                       measure │    weights │
# │                        String │    Float32 │
# ├───────────────────────────────┼────────────┤
# │   MAI (G,4,[0.26, 0.5, 0.75]) │ 0.00132962 │
# │   MAI (F,4,[0.25, 0.5, 0.74]) │   0.516653 │
# │ MAI (FP,4,[0.26, 0.51, 0.75]) │   0.482018 │
# └───────────────────────────────┴────────────┘