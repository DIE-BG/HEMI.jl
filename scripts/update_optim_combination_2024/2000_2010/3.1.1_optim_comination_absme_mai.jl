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
loadpath = datadir("optim_comb_2024", "2000_2010","tray_infl","absme")

combination_savepath  = datadir("optim_comb_2024","2000_2010","optim_combination","absme","mai","fx")

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



# FILTRAMOS EXCLUSION FIJA
functions = df_results.inflfn
components_mask = [!(fn.f[1] isa InflationFixedExclusionCPI) for fn in functions]

#####################################
### COMBINACION OPTIMA BASE 2000 y 2010

# DEFINIMOS PERIODOS DE COMBINACION
combine_period_00 =  GT_EVAL_B00 
combine_period_10 =  GT_EVAL_B10

periods_filter_00 = eval_periods(gtdata_eval, combine_period_00)
periods_filter_10 = eval_periods(gtdata_eval, combine_period_10)

# CALCULAMOS LOS PESOS OPTIMOS
a_optim_00 = metric_combination_weights(
    tray_infl[periods_filter_00, :, :],
    tray_infl_pob[periods_filter_00],
    metric = :absme
)

a_optim_10 = metric_combination_weights(
    tray_infl[periods_filter_10, components_mask, :],
    tray_infl_pob[periods_filter_10],
    metric = :absme
)

# Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
#insert!(a_optim_00, findall(.!components_mask)[1],0)
insert!(a_optim_10, findall(.!components_mask)[1],0)

###############################################################
#  tray_w = sum(a_optim_10' .*  tray_infl[periods_filter_10,:, :],dims=2)
#  metrics = eval_metrics(tray_w, tray_infl_pob[periods_filter_10])
#  metrics[:absme]
###############################################################

# CREAMOS SUBYACENTES OPTIMAS PARA CADA BASE
optabsmeb00 = CombinationFunction(
    functions...,
    a_optim_00, 
    "Subyacente óptima ABSME base 2000",
    "SubOptABSME_B00"
)

optabsmeb10 = CombinationFunction(
    functions...,
    a_optim_10, 
    "Subyacente óptima ABSME base 2010",
    "SubOptABSME_B10"
)

# EMPALMAMOS LA FUNCION PARA CREAR UNA SUBYACENTE OPTIMA
optabsme2024 = Splice(
    optabsmeb00, 
    optabsmeb10; 
    name = "Subyacente Óptima ABSME 2024",
    tag = "SubOptABSME2024"
)

## GENERAMOS TRAYECTORIAS DE LA COMBINACION OPTIMA

# Creamos periodo de evaluacion para medidas hasta Dic 2020.
GT_EVAL_B2020 = EvalPeriod(Date(2011, 12), Date(2020, 12), "gt_b2020")

config = Dict(
    :paramfn => paramfn,
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :traindate => Date(2022, 12),
    :nsim => 25_000,
    :evalperiods => (CompletePeriod(), GT_EVAL_B00, GT_EVAL_B10, GT_EVAL_T0010, GT_EVAL_B2020),
    :inflfn => optabsme2024
)|> dict_list

run_batch(gtdata_eval, config, combination_savepath; savetrajectories = true)


## RESULTADOS 
using PrettyTables
pretty_table(components(optabsme2024))

# ┌─────────────────────────────────────────────┬───────────────────┬─────────────────────────────────────────────┬───────────────────┐
# │           Subyacente óptima ABSME base 2000 │ SubOptABSME_B00_w │           Subyacente óptima ABSME base 2010 │ SubOptABSME_B10_w │
# │                                         Any │               Any │                                         Any │               Any │
# ├─────────────────────────────────────────────┼───────────────────┼─────────────────────────────────────────────┼───────────────────┤
# │                Percentil equiponderado 72.0 │          0.182113 │                Percentil equiponderado 72.0 │          0.248181 │
# │                    Percentil ponderado 69.0 │          0.142902 │                    Percentil ponderado 72.0 │          0.163641 │
# │   Media Truncada Equiponderada (63.0, 80.0) │           0.14717 │   Media Truncada Equiponderada (57.0, 83.0) │          0.172982 │
# │       Media Truncada Ponderada (63.0, 76.0) │          0.149541 │       Media Truncada Ponderada (67.0, 78.0) │           0.17823 │
# │  Inflación de exclusión dinámica (1.2, 3.6) │          0.121299 │  Inflación de exclusión dinámica (0.7, 3.0) │            0.1171 │
# │ Exclusión fija de gastos básicos IPC (9, 6) │               0.0 │ Exclusión fija de gastos básicos IPC (9, 6) │               0.0 │
# │         MAI (FP,5,[0.01, 0.41, 0.41, 0.99]) │          0.106767 │          MAI (FP,5,[0.38, 0.46, 0.66, 1.0]) │         0.0854671 │
# │                MAI (F,4,[0.36, 0.61, 0.92]) │         0.0776598 │      MAI (F,6,[0.32, 0.4, 0.53, 0.8, 0.97]) │         0.0224189 │
# │     MAI (G,6,[0.17, 0.33, 0.5, 0.67, 0.83]) │         0.0725388 │                MAI (G,4,[0.38, 0.47, 0.74]) │         0.0119385 │
# └─────────────────────────────────────────────┴───────────────────┴─────────────────────────────────────────────┴───────────────────┘

# Distribución del Peso de las Medidas incluyendo Exclusión Fija en Base 00
# ┌─────────────────────────────────────────────┬───────────────────┬─────────────────────────────────────────────┬───────────────────┐
# │           Subyacente óptima ABSME base 2000 │ SubOptABSME_B00_w │           Subyacente óptima ABSME base 2010 │ SubOptABSME_B10_w │
# │                                         Any │               Any │                                         Any │               Any │
# ├─────────────────────────────────────────────┼───────────────────┼─────────────────────────────────────────────┼───────────────────┤
# │                Percentil equiponderado 72.0 │          0.194062 │                Percentil equiponderado 72.0 │          0.248181 │
# │                    Percentil ponderado 69.0 │          0.162499 │                    Percentil ponderado 72.0 │          0.163641 │
# │   Media Truncada Equiponderada (63.0, 80.0) │          0.156363 │   Media Truncada Equiponderada (57.0, 83.0) │          0.172982 │
# │       Media Truncada Ponderada (63.0, 76.0) │          0.140381 │       Media Truncada Ponderada (67.0, 78.0) │           0.17823 │
# │  Inflación de exclusión dinámica (1.2, 3.6) │          0.117709 │  Inflación de exclusión dinámica (0.7, 3.0) │            0.1171 │
# │ Exclusión fija de gastos básicos IPC (9, 6) │          0.100542 │ Exclusión fija de gastos básicos IPC (9, 6) │               0.0 │
# │         MAI (FP,5,[0.01, 0.41, 0.41, 0.99]) │         0.0528811 │          MAI (FP,5,[0.38, 0.46, 0.66, 1.0]) │         0.0854671 │
# │                MAI (F,4,[0.36, 0.61, 0.92]) │          0.039761 │      MAI (F,6,[0.32, 0.4, 0.53, 0.8, 0.97]) │         0.0224189 │
# │     MAI (G,6,[0.17, 0.33, 0.5, 0.67, 0.83]) │         0.0358176 │                MAI (G,4,[0.38, 0.47, 0.74]) │         0.0119385 │
# └─────────────────────────────────────────────┴───────────────────┴─────────────────────────────────────────────┴───────────────────┘

######################################################################################
################## INTERVALO DE CONFIANZA ############################################
######################################################################################

## CREACION DE TRAYECTORIAS DE OPTIMA ABSME 

w_tray = collect_results(joinpath(combination_savepath,"tray_infl")).tray_infl[1]

## ERRORES
b = reshape(tray_infl_pob,(length(tray_infl_pob),1,1))
error_tray = dropdims(w_tray .- b,dims=2)

## PERIODOS DE EVALUACION
period_b00 = GT_EVAL_B00
period_trn = GT_EVAL_T0010
period_b10 = GT_EVAL_B10

b00_mask = eval_periods(gtdata_eval, period_b00)
trn_mask = eval_periods(gtdata_eval, period_trn)
b10_mask = eval_periods(gtdata_eval, period_b10)

tray_b00 = error_tray[b00_mask, :]
tray_trn = error_tray[trn_mask, :]
tray_b10 = error_tray[b10_mask, :]


## CUANTILES
quant_0125 = quantile.(vec.([tray_b00,tray_trn,tray_b10]),0.0125)  
quant_9875 = quantile.(vec.([tray_b00,tray_trn,tray_b10]),0.9875) 

bounds =transpose(hcat(-quant_0125,-quant_9875))

using PrettyTables
pretty_table(hcat(["upper","lower"],bounds),["","b00","T","b10"])

# ┌───────┬───────────┬───────────┬───────────┐
# │       │       b00 │         T │       b10 │
# ├───────┼───────────┼───────────┼───────────┤
# │ upper │   1.20733 │  0.774002 │  0.753945 │
# │ lower │ -0.884318 │ -0.594986 │ -0.530732 │
# └───────┴───────────┴───────────┴───────────┘

# Incluyendo Exclusión Fija en Base 00
# ┌───────┬───────────┬───────────┬───────────┐
# │       │       b00 │         T │       b10 │
# ├───────┼───────────┼───────────┼───────────┤
# │ upper │   1.12877 │  0.778449 │  0.753939 │
# │ lower │ -0.892216 │ -0.717366 │ -0.530732 │
# └───────┴───────────┴───────────┴───────────┘
