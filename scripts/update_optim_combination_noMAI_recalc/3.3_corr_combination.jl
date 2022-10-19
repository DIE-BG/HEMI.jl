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

combination_savepath  = datadir("results","optim_combination","corr_noMAI_recalc")

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
paramfn = InflationTotalRebaseCPI(36, 3) #df_results[1, :paramfn]
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)

functions = combine_df.inflfn
components_mask = [!(fn isa InflationFixedExclusionCPI || fn isa InflationCoreMai ) for fn in functions]

combine_period = EvalPeriod(Date(2011, 12), Date(2021, 12), "combperiod") 
periods_filter = eval_periods(gtdata_eval, combine_period)

a_optim = metric_combination_weights(
    tray_infl[periods_filter, components_mask, :],
    tray_infl_pob[periods_filter],
    metric = :corr,
    # Le asignamos pesos iniciales de una solucion de esquina
    w_start = float.([(fn isa InflationTrimmedMeanEq) for fn in functions][components_mask])    

)

#Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
for x in findall(.!components_mask)
    insert!(a_optim,x,0)
end

#Construccion de la MAI optima
mai_components = [fn isa InflationCoreMai for fn in functions]
mai_weights = [0, 0, 0] #reemplazamos por ceros
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

# using PrettyTables
# pretty_table(components(optcorr2023))
# ┌───────────────────────────────────────────────┬────────────┐
# │                                       measure │    weights │
# │                                        String │    Float64 │
# ├───────────────────────────────────────────────┼────────────┤
# │                      Percentil ponderado 81.0 │ 0.00783096 │
# │  Inflación de exclusión dinámica (0.46, 4.97) │ 0.00915982 │
# │ Exclusión fija de gastos básicos IPC (14, 51) │        0.0 │
# │       Media Truncada Ponderada (53.56, 96.47) │ 0.00106925 │
# │                 Percentil equiponderado 80.86 │   0.276791 │
# │     Media Truncada Equiponderada (55.0, 92.0) │   0.705083 │
# │                          MAI óptima CORR 2023 │        0.0 │
# └───────────────────────────────────────────────┴────────────┘

# pretty_table(components(optmai_corr2023))
# ┌───────────────────────────────┬─────────┐
# │                       measure │ weights │
# │                        String │   Int64 │
# ├───────────────────────────────┼─────────┤
# │   MAI (G,4,[0.26, 0.5, 0.75]) │       0 │
# │   MAI (F,4,[0.25, 0.5, 0.74]) │       0 │
# │ MAI (FP,4,[0.26, 0.51, 0.75]) │       0 │
# └───────────────────────────────┴─────────┘