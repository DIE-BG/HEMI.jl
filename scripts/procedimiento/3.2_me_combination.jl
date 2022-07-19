using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain


savepath = datadir("results", "tray_infl", "absme")
tray_dir = joinpath(savepath, "tray_infl")

combination_savepath  = datadir("results","optim_combination","absme")

gtdata_eval = GTDATA[Date(2021, 12)]

df_results = collect_results(savepath)

@chain df_results begin 
    select(:measure, :absme)
end

# DataFrame de combinación 
combine_df = @chain df_results begin 
    select(:measure, :absme, :inflfn, 
        :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path
    )
    sort(:absme)
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
    metric = :absme
)

#Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
insert!(a_optim, findall(.!components_mask)[1],0)

#Construccion de la MAI optima
mai_components = [fn isa InflationCoreMai for fn in functions]
mai_weights = a_optim[mai_components]/sum(a_optim[mai_components])
mai_fns = functions[mai_components]

optmai_me2022b = CombinationFunction(
    mai_fns..., 
    mai_weights, 
    "MAI óptima ABSME 2022b"
)

non_mai_weights = a_optim[.!mai_components]
non_mai_fns = functions[.!mai_components]

final_weights = vcat(non_mai_weights, sum(a_optim[mai_components])) 
final_fns     = vcat(non_mai_fns, optmai)

optabsme2022b = CombinationFunction(
    final_fns...,
    final_weights, 
    "Subyacente óptima ABSME 2022b"
)

wsave(joinpath(combination_savepath,"optabsme2022b.jld2"), "optabsme2022b", optabsme2022b , "optmai_me2022b", optmai_me2022b)

# ┌─────────────────────────────────────────────┬───────────┐
# │                                     measure │   weights │
# │                                      String │   Float32 │
# ├─────────────────────────────────────────────┼───────────┤
# │  Media Truncada Equiponderada (22.18, 96.0) │  0.261625 │
# │     Media Truncada Ponderada (25.17, 95.03) │  0.167057 │
# │ Exclusión fija de gastos básicos IPC (9, 6) │       0.0 │
# │  Inflación de exclusión dinámica (1.0, 3.4) │  0.184163 │
# │                   Percentil ponderado 70.23 │  0.182783 │
# │               Percentil equiponderado 71.92 │  0.120694 │
# │                      MAI óptima ABSME 2022b │ 0.0837766 │
# └─────────────────────────────────────────────┴───────────┘

# ┌──────────────────────────────────────────────────────────────────┬────────────┐
# │                                                          measure │    weights │
# │                                                           String │    Float32 │
# ├──────────────────────────────────────────────────────────────────┼────────────┤
# │   MAI (F,10,[0.1, 0.16, 0.49, 0.72, 0.8, 0.87, 0.9, 0.99, 0.99]) │   0.999978 │
# │ MAI (FP,10,[0.06, 0.1, 0.25, 0.29, 0.34, 0.48, 0.85, 0.98, 1.0]) │ 9.21613e-6 │
# │   MAI (G,10,[0.0, 0.24, 0.25, 0.34, 0.44, 0.48, 0.5, 0.74, 1.0]) │ 1.30453e-5 │
# └──────────────────────────────────────────────────────────────────┴────────────┘