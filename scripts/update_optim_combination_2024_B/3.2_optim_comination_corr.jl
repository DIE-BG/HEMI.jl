using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain

# incluimos scripts auxiliares
include(scriptsdir("TOOLS","INFLFNS","rank.jl"))

# DEFINIMOS PATHS
loadpath = datadir("results","optim_comb_2024_B","tray_infl","corr")

combination_savepath  = datadir("results","optim_comb_2024_B","optim_combination","corr")

# DATOS A EVALUAR
gtdata_eval = GTDATA[Date(2022, 12)]

# CARGAMOS Y ORDENAMOS DATAFRAMES SEGUN LA MEDIDA DE INFLACION
df_results = collect_results(loadpath)

#Ordenamos por medida de Inflacion
df_results.rank = rank.(df_results.inflfn)
sort!(df_results, :rank)

# PATHS DE TRAYECTORIAS
df_results.tray_path = map(
    x->joinpath(
        loadpath,
        "tray_infl",
        basename(x)
    ),
    df_results.path
)

# TRAYECTORIAS
tray_infl = mapreduce(hcat, df_results.tray_path) do path
    load(path, "tray_infl")
end

# DEFINIMOS "EL" PARAMETRO
resamplefn = df_results.resamplefn[1]
trendfn = df_results.trendfn[1]
paramfn = df_results.paramfn[1] #InflationTotalRebaseCPI(36, 3)
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)



# FILTRAMOS EXCLUSION FIJA y MAI
functions = df_results.inflfn
components_mask = [1 for fn in functions]#[!(fn.f[1] isa InflationFixedExclusionCPI || fn.f[1] isa  InflationCoreMai) for fn in functions] 

#####################################
### COMBINACION OPTIMA

# DEFINIMOS PERIODOS DE COMBINACION
combine_period =  CompletePeriod() 
periods_filter = eval_periods(gtdata_eval, CompletePeriod())

# CALCULAMOS LOS PESOS OPTIMOS
# a_optim = share_combination_weights(
#     tray_infl[periods_filter, components_mask, :],
#     tray_infl_pob[periods_filter],
#     show_status=true
# )

a_optim = metric_combination_weights(
    tray_infl[periods_filter, components_mask, :],
    tray_infl_pob[periods_filter],
    metric=:corr,
    w_start = [ 0.01  0.01  0.95  0.01  0.01  0.01][:],
    x_abstol = 1f-4, 
    f_abstol = 1f-6,
)


a_optim = [0.013201, 0.004728, 0.944753, 0.012774, 0.012666, 0.011891][:]
# Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
#insert!(a_optim_00, findall(.!components_mask)[1],0)
#insert!(a_optim_10, findall(.!components_mask_b10)[1],0)

###############################################################
tray_w = sum(a_optim' .*  tray_infl[periods_filter,:, :],dims=2)
metrics = eval_metrics(tray_w, tray_infl_pob[periods_filter])
metrics[:corr]
###############################################################

# CREAMOS SUBYACENTE OPTIMAS 
optcorr2024_b = CombinationFunction(
    functions[1:6]...,
    a_optim, 
    "Subyacente óptima CORR 2024 B",
    "SubOptCORR_2024_B"
)

## GENERAMOS TRAYECTORIAS DE LA COMBINACION OPTIMA

### PERIODOS DE evaluacion
GT_EVAL_B08 = EvalPeriod(Date(2001, 12), Date(2008, 12), "gt_b08")
GT_EVAL_B20 = EvalPeriod(Date(2011, 12), Date(2020, 12), "gt_b20")
GT_EVAL_B0820 = InflationEvalTools.PeriodVector(
    [
        (Date(2001, 12), Date(2008, 12)),
        (Date(2011, 12), Date(2020, 12))
    ],
    "gt_b0820"
)

config = Dict(
    :paramfn => paramfn,
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :traindate => Date(2022, 12),
    :nsim => 125_000,
    :evalperiods => (CompletePeriod(), GT_EVAL_B00, GT_EVAL_B10, GT_EVAL_T0010, GT_EVAL_B20, GT_EVAL_B08, GT_EVAL_B0820),
    :inflfn => optcorr2024_b
)|> dict_list

run_batch(gtdata_eval, config, combination_savepath; savetrajectories = true)


## RESULTADOS 
using PrettyTables
pretty_table(components(optcorr2024_b))

# ┌───────────────────────────────────────────────┬──────────┐
# │                                       measure │  weights │
# │                                        String │  Float64 │
# ├───────────────────────────────────────────────┼──────────┤
# │                  Percentil equiponderado 76.0 │ 0.013201 │
# │                      Percentil ponderado 76.0 │ 0.004728 │
# │     Media Truncada Equiponderada (60.0, 88.0) │ 0.944753 │
# │         Media Truncada Ponderada (58.0, 91.0) │ 0.012774 │
# │    Inflación de exclusión dinámica (0.1, 0.4) │ 0.012666 │
# │ Exclusión fija de gastos básicos IPC (14, 55) │ 0.011891 │
# └───────────────────────────────────────────────┴──────────┘

