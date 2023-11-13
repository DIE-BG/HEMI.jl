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
loadpath = datadir("optim_comb_2024", "2000_2010","tray_infl","mse")

combination_savepath  = datadir("optim_comb_2024","2000_2010","optim_combination","mse","fx")

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
a_optim_00 = share_combination_weights(
    tray_infl[periods_filter_00, components_mask_b00, :],
    tray_infl_pob[periods_filter_00],
    show_status=true
)

a_optim_10 = share_combination_weights(
    tray_infl[periods_filter_10, components_mask_b10, :],
    tray_infl_pob[periods_filter_10],
    show_status=true
)

# Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
#insert!(a_optim_00, findall(.!components_mask)[1],0)
insert!(a_optim_10, findall(.!components_mask_b10)[1],0)

###############################################################
# tray_w = sum(a_optim_10' .*  tray_infl[periods_filter_10,:, :],dims=2)
# metrics = eval_metrics(tray_w, tray_infl_pob[periods_filter_10])
# metrics[:mse]
###############################################################

# CREAMOS SUBYACENTES OPTIMAS PARA CADA BASE
optmseb00 = CombinationFunction(
    functions[1:6]...,
    a_optim_00, 
    "Subyacente óptima MSE base 2000",
    "SubOptMSE_B00"
)

optmseb10 = CombinationFunction(
    functions[1:6]...,
    a_optim_10, 
    "Subyacente óptima MSE base 2010",
    "SubOptMSE_B10"
)

# EMPALMAMOS LA FUNCION PARA CREAR UNA SUBYACENTE OPTIMA
optmse2024 = Splice(
    optmseb00, 
    optmseb10; 
    name = "Subyacente Óptima MSE 2024",
    tag = "SubOptMSE2024"
)

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
    :inflfn => optmse2024
)|> dict_list

run_batch(gtdata_eval, config, combination_savepath; savetrajectories = true)


## RESULTADOS 
using PrettyTables
pretty_table(components(optmse2024))

# ┌───────────────────────────────────────────────┬─────────────────┬───────────────────────────────────────────────┬─────────────────┐
# │               Subyacente óptima MSE base 2000 │ SubOptMSE_B00_w │               Subyacente óptima MSE base 2010 │ SubOptMSE_B10_w │
# │                                           Any │             Any │                                           Any │             Any │
# ├───────────────────────────────────────────────┼─────────────────┼───────────────────────────────────────────────┼─────────────────┤
# │                  Percentil equiponderado 72.0 │      5.20732e-7 │                  Percentil equiponderado 72.0 │        0.136963 │
# │                      Percentil ponderado 69.0 │       2.0264e-7 │                      Percentil ponderado 72.0 │      2.84453e-7 │
# │     Media Truncada Equiponderada (52.0, 87.0) │        0.890449 │     Media Truncada Equiponderada (52.0, 86.0) │        0.748689 │
# │         Media Truncada Ponderada (34.0, 92.0) │      3.01948e-7 │         Media Truncada Ponderada (60.0, 83.0) │      3.04718e-7 │
# │    Inflación de exclusión dinámica (0.3, 1.5) │         0.10955 │    Inflación de exclusión dinámica (0.3, 1.6) │        0.114347 │
# │ Exclusión fija de gastos básicos IPC (14, 17) │             0.0 │ Exclusión fija de gastos básicos IPC (14, 17) │             0.0 │
# └───────────────────────────────────────────────┴─────────────────┴───────────────────────────────────────────────┴─────────────────┘

# Con Exclusión Fija en la Base 00

# ┌───────────────────────────────────────────────┬─────────────────┬───────────────────────────────────────────────┬─────────────────┐
# │               Subyacente óptima MSE base 2000 │ SubOptMSE_B00_w │               Subyacente óptima MSE base 2010 │ SubOptMSE_B10_w │
# │                                           Any │             Any │                                           Any │             Any │
# ├───────────────────────────────────────────────┼─────────────────┼───────────────────────────────────────────────┼─────────────────┤
# │                  Percentil equiponderado 72.0 │      7.28969e-7 │                  Percentil equiponderado 72.0 │        0.136963 │
# │                      Percentil ponderado 69.0 │      5.92559e-8 │                      Percentil ponderado 72.0 │      2.84453e-7 │
# │     Media Truncada Equiponderada (52.0, 87.0) │        0.814358 │     Media Truncada Equiponderada (52.0, 86.0) │        0.748689 │
# │         Media Truncada Ponderada (34.0, 92.0) │      5.05308e-8 │         Media Truncada Ponderada (60.0, 83.0) │      3.04718e-7 │
# │    Inflación de exclusión dinámica (0.3, 1.5) │      1.09876e-7 │    Inflación de exclusión dinámica (0.3, 1.6) │        0.114347 │
# │ Exclusión fija de gastos básicos IPC (14, 17) │        0.185641 │ Exclusión fija de gastos básicos IPC (14, 17) │             0.0 │
# └───────────────────────────────────────────────┴─────────────────┴───────────────────────────────────────────────┴─────────────────┘


######################################################################################
################## INTERVALO DE CONFIANZA ############################################
######################################################################################

## CREACION DE TRAYECTORIAS DE OPTIMA MSE 


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

# ┌───────┬───────────┬──────────┬───────────┐
# │       │       b00 │        T │       b10 │
# ├───────┼───────────┼──────────┼───────────┤
# │ upper │   1.04547 │ 0.760376 │  0.729263 │
# │ lower │ -0.767988 │ -0.34805 │ -0.472879 │
# └───────┴───────────┴──────────┴───────────┘