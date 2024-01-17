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
loadpath = datadir("results","optim_comb_no_trans_2024","tray_infl","absme")

combination_savepath  = datadir("results","optim_comb_no_trans_2024","optim_combination","absme")

# DATOS A EVALUAR
data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")
gtdata_eval = NOT_GTDATA[Date(2022, 12)]

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
a_optim_00 = metric_combination_weights(
    tray_infl[periods_filter_00, components_mask_b00, :],
    tray_infl_pob[periods_filter_00],
    metric = :absme
)
#a_optim_00 = [0.0334445, 0.229912,  0.0846386, 0.14619, 0.231975, 0.273933]

a_optim_10 = metric_combination_weights(
    tray_infl[periods_filter_10, components_mask_b10, :],
    tray_infl_pob[periods_filter_10],
    metric = :absme,
    w_start = [0.999, (0.001) .* fill(0.25,4)...]
)

#a_optim_10 =  [0.999751,  6.51575e-5,  1.54983e-7,  8.08151e-5,  3.17083e-6]


# Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
#insert!(a_optim_00, findall(.!components_mask)[1],0)
insert!(a_optim_10, findall(.!components_mask_b10)[1],0)

# CREAMOS SUBYACENTES OPTIMAS PARA CADA BASE
optabsmeb00 = CombinationFunction(
    functions[1:6]...,
    a_optim_00, 
    "Subyacente óptima ABSME base 2000",
    "SubOptABSME_B00"
)

optabsmeb10 = CombinationFunction(
    functions[1:6]...,
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

using PrettyTables
pretty_table(components(optabsme2024))

# ┌─────────────────────────────────────────────┬───────────────────┬─────────────────────────────────────────────┬───────────────────┐
# │           Subyacente óptima ABSME base 2000 │ SubOptABSME_B00_w │           Subyacente óptima ABSME base 2010 │ SubOptABSME_B10_w │
# │                                         Any │               Any │                                         Any │               Any │
# ├─────────────────────────────────────────────┼───────────────────┼─────────────────────────────────────────────┼───────────────────┤
# │                Percentil equiponderado 72.0 │         0.0334445 │                Percentil equiponderado 76.0 │          0.999751 │
# │                    Percentil ponderado 69.0 │          0.229912 │                    Percentil ponderado 75.0 │        6.51575e-5 │
# │   Media Truncada Equiponderada (47.0, 89.0) │         0.0846386 │   Media Truncada Equiponderada (76.0, 77.0) │        1.54983e-7 │
# │       Media Truncada Ponderada (48.0, 89.0) │           0.14619 │       Media Truncada Ponderada (66.0, 88.0) │        8.08151e-5 │
# │  Inflación de exclusión dinámica (2.0, 4.9) │          0.231975 │  Inflación de exclusión dinámica (0.3, 3.8) │        3.17083e-6 │
# │ Exclusión fija de gastos básicos IPC (4, 1) │          0.273933 │ Exclusión fija de gastos básicos IPC (4, 1) │               0.0 │
# └─────────────────────────────────────────────┴───────────────────┴─────────────────────────────────────────────┴───────────────────┘

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
    :inflfn => optabsme2024
)|> dict_list

run_batch(gtdata_eval, config, combination_savepath; savetrajectories = true)

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

pretty_table(hcat(["upper","lower"],bounds),["","b00","T","b10"])

# ┌───────┬──────────┬──────────┬───────────┐
# │       │      b00 │        T │       b10 │
# ├───────┼──────────┼──────────┼───────────┤
# │ upper │  1.64192 │   1.1431 │  0.576568 │
# │ lower │ -1.84894 │ -1.35007 │ -0.687575 │
# └───────┴──────────┴──────────┴───────────┘
