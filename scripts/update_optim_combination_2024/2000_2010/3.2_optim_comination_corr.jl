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
loadpath = datadir("optim_comb_2024", "2000_2010","tray_infl","corr")

combination_savepath  = datadir("optim_comb_2024","2000_2010","optim_combination","corr","fx")

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



# FILTRAMOS EXCLUSION FIJA Y MAI
#functions = df_results.inflfn
#components_mask = [!(fn.f[1] isa InflationFixedExclusionCPI || fn.f[1] isa  InflationCoreMai) for fn in functions] 

# FILTRAMOS EXCLUSION FIJA para base 10 Y MAI para ambas bases
functions = df_results.inflfn
components_mask_b00 = [!(fn.f[1] isa  InflationCoreMai) for fn in functions] 
components_mask_b10 = [!(fn.f[1] isa InflationFixedExclusionCPI || fn.f[1] isa  InflationCoreMai) for fn in functions] 

#####################################
### COMBINACION OPTIMA BASE 2000 y 2010

# DEFINIMOS PERIODOS DE COMBINACION
combine_period_00 =  GT_EVAL_B00 
combine_period_10 =  GT_EVAL_B10

periods_filter_00 = eval_periods(gtdata_eval, combine_period_00)
periods_filter_10 = eval_periods(gtdata_eval, combine_period_10)

# CALCULAMOS LOS PESOS OPTIMOS
a_optim_00 =  metric_combination_weights(
    tray_infl[periods_filter_00, components_mask_b00, :],
    tray_infl_pob[periods_filter_00],
    metric = :corr,
    w_start = [ 0.0001, 0.0, 0.9999, 0.0, 0.0, 0.0001] 
)

a_optim_10 =  metric_combination_weights(
    tray_infl[periods_filter_10, components_mask_b10, :],
    tray_infl_pob[periods_filter_10],
    metric = :corr,
    w_start = [ 0.0001, 0.0, 0.9999, 0.0, 0.0] 
)

# Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
#insert!(a_optim_00, findall(.!components_mask)[1],0)
insert!(a_optim_10, findall(.!components_mask_b10)[1],0)

###############################################################

#  tray_w = sum(a_optim_10' .*  tray_infl[periods_filter_10,:, :],dims=2)
#  metrics = eval_metrics(tray_w, tray_infl_pob[periods_filter_10])

#  trays_opts = collect_results(joinpath(combination_loadpath,"tray_infl")).tray_infl[1]

#  metrics2 = eval_metrics(trays_opts[periods_filter_10,:,:], tray_infl_pob[periods_filter_10])


###############################################################

# CREAMOS SUBYACENTES OPTIMAS PARA CADA BASE
optcorrb00 = CombinationFunction(
    functions[1:6]...,
    a_optim_00, 
    "Subyacente óptima CORR base 2000",
    "SubOptCORR_B00"
)

optcorrb10 = CombinationFunction(
    functions[1:6]...,
    a_optim_10, 
    "Subyacente óptima CORR base 2010",
    "SubOptCorr_B10"
)

# EMPALMAMOS LA FUNCION PARA CREAR UNA SUBYACENTE OPTIMA
optcorr2024 = Splice(
    optcorrb00, 
    optcorrb10; 
    name = "Subyacente Óptima CORR 2024",
    tag  = "SubOptCORR2024"
)


using PrettyTables
pretty_table(components(optcorr2024))
# ┌───────────────────────────────────────────────┬──────────────────┬───────────────────────────────────────────────┬──────────────────┐
# │              Subyacente óptima CORR base 2000 │ SubOptCORR_B00_w │              Subyacente óptima CORR base 2010 │ SubOptCorr_B10_w │
# │                                           Any │              Any │                                           Any │              Any │
# ├───────────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────┼──────────────────┤
# │                  Percentil equiponderado 67.0 │        0.0254377 │                  Percentil equiponderado 77.0 │        0.0602007 │
# │                      Percentil ponderado 77.0 │        0.0288299 │                      Percentil ponderado 78.0 │       2.01534e-6 │
# │     Media Truncada Equiponderada (56.0, 89.0) │         0.894161 │     Media Truncada Equiponderada (63.0, 87.0) │         0.898469 │
# │         Media Truncada Ponderada (50.0, 92.0) │        0.0274824 │         Media Truncada Ponderada (65.0, 85.0) │       0.00063201 │
# │    Inflación de exclusión dinámica (0.3, 1.3) │       1.12117e-6 │    Inflación de exclusión dinámica (0.1, 0.3) │        0.0406388 │
# │ Exclusión fija de gastos básicos IPC (14, 51) │        0.0241105 │ Exclusión fija de gastos básicos IPC (14, 51) │              0.0 │
# └───────────────────────────────────────────────┴──────────────────┴───────────────────────────────────────────────┴──────────────────┘




## GENERAMOS TRAYECTORIAS DE LA COMBINACION OPTIMA

# Creamos periodo de evaluacion para medidas hasta Dic 2020.
GT_EVAL_B2020 = EvalPeriod(Date(2011, 12), Date(2020, 12), "gt_b2020")

config = Dict(
    :paramfn => paramfn,
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :traindate => Date(2022, 12),
    :nsim => 125_000,
    :evalperiods => (CompletePeriod(), GT_EVAL_B00, GT_EVAL_B10, GT_EVAL_T0010, GT_EVAL_B2020),
    :inflfn => optcorr2024
)|> dict_list

run_batch(gtdata_eval, config, combination_savepath; savetrajectories = true)

