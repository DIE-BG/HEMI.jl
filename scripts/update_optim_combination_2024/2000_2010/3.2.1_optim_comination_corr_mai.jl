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

combination_savepath  = datadir("optim_comb_2024","2000_2010","optim_combination","corr","mai","fx")

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
    metric = :corr,
    w_start = [ 0.001, 0.0, 0.999, 0.0, 0.0, 0.0, 0.001, 0.001, 0.0 ] 
)

a_optim_10 = metric_combination_weights(
    tray_infl[periods_filter_10, components_mask, :],
    tray_infl_pob[periods_filter_10],
    metric = :corr,
    w_start = [ 0.001, 0.0, 0.999, 0.0, 0.0, 0.001, 0.001, 0.0] 
)

# Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
#insert!(a_optim_00, findall(.!components_mask)[1],0)
insert!(a_optim_10, findall(.!components_mask)[1],0)

###############################################################
#  tray_w = sum(a_optim_10' .*  tray_infl[periods_filter_10,:, :],dims=2)
#  metrics = eval_metrics(tray_w, tray_infl_pob[periods_filter_10])
#  metrics[:corr]
###############################################################

# CREAMOS SUBYACENTES OPTIMAS PARA CADA BASE
optcorrb00 = CombinationFunction(
    functions...,
    a_optim_00, 
    "Subyacente óptima CORR base 2000",
    "SubOptCORR_B00"
)

optcorrb10 = CombinationFunction(
    functions...,
    a_optim_10, 
    "Subyacente óptima CORR base 2010",
    "SubOptCORR_B10"
)

# EMPALMAMOS LA FUNCION PARA CREAR UNA SUBYACENTE OPTIMA
optcorr2024 = Splice(
    optcorrb00, 
    optcorrb10; 
    name = "Subyacente Óptima CORR 2024",
    tag = "SubOptCORR2024"
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
    :inflfn => optcorr2024
)|> dict_list

run_batch(gtdata_eval, config, combination_savepath; savetrajectories = true)


## RESULTADOS 
using PrettyTables
pretty_table(components(optcorr2024))

#
# Distribución del Peso de las Medidas incluyendo Exclusión Fija en Base 00
# ┌───────────────────────────────────────────────┬──────────────────┬───────────────────────────────────────────────┬──────────────────┐
# │              Subyacente óptima CORR base 2000 │ SubOptCORR_B00_w │              Subyacente óptima CORR base 2010 │ SubOptCORR_B10_w │
# │                                           Any │              Any │                                           Any │              Any │
# ├───────────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────┼──────────────────┤
# │                  Percentil equiponderado 67.0 │         0.403461 │                  Percentil equiponderado 77.0 │         0.276758 │
# │                      Percentil ponderado 77.0 │      0.000226257 │                      Percentil ponderado 78.0 │       4.28736e-6 │
# │     Media Truncada Equiponderada (56.0, 89.0) │        0.0247162 │     Media Truncada Equiponderada (63.0, 87.0) │         0.188763 │
# │         Media Truncada Ponderada (50.0, 92.0) │        0.0822224 │         Media Truncada Ponderada (65.0, 85.0) │         0.173941 │
# │    Inflación de exclusión dinámica (0.3, 1.3) │        0.0131188 │    Inflación de exclusión dinámica (0.1, 0.3) │         0.148375 │
# │ Exclusión fija de gastos básicos IPC (14, 51) │        0.0685928 │ Exclusión fija de gastos básicos IPC (14, 51) │              0.0 │    
# │                  MAI (FP,4,[0.25, 0.5, 0.75]) │         0.186528 │                 MAI (FP,4,[0.27, 0.47, 0.75]) │        0.0946795 │    
# │                   MAI (F,4,[0.25, 0.5, 0.75]) │         0.221116 │                   MAI (F,4,[0.3, 0.48, 0.75]) │         0.117402 │    
# │                   MAI (G,4,[0.25, 0.5, 0.75]) │       1.93151e-5 │             MAI (G,5,[0.28, 0.37, 0.6, 0.81]) │       3.76536e-7 │    
# └───────────────────────────────────────────────┴──────────────────┴───────────────────────────────────────────────┴──────────────────┘

#Distribución de Peso de las Medidas con peso inicial. 
# ┌───────────────────────────────────────────────┬──────────────────┬───────────────────────────────────────────────┬──────────────────┐
# │              Subyacente óptima CORR base 2000 │ SubOptCORR_B00_w │              Subyacente óptima CORR base 2010 │ SubOptCORR_B10_w │
# │                                           Any │              Any │                                           Any │              Any │
# ├───────────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────┼──────────────────┤
# │                  Percentil equiponderado 67.0 │        0.0204378 │                  Percentil equiponderado 77.0 │        0.0279822 │
# │                      Percentil ponderado 77.0 │       3.10559e-6 │                      Percentil ponderado 78.0 │       0.00899382 │
# │     Media Truncada Equiponderada (56.0, 89.0) │         0.811857 │     Media Truncada Equiponderada (63.0, 87.0) │         0.935041 │
# │         Media Truncada Ponderada (50.0, 92.0) │       0.00912357 │         Media Truncada Ponderada (65.0, 85.0) │       0.00824192 │
# │    Inflación de exclusión dinámica (0.3, 1.3) │        0.0112348 │    Inflación de exclusión dinámica (0.1, 0.3) │        0.0195432 │
# │ Exclusión fija de gastos básicos IPC (14, 51) │        0.0947092 │ Exclusión fija de gastos básicos IPC (14, 51) │              0.0 │
# │                  MAI (FP,4,[0.25, 0.5, 0.75]) │       0.00876126 │                 MAI (FP,4,[0.27, 0.47, 0.75]) │      0.000197362 │
# │                   MAI (F,4,[0.25, 0.5, 0.75]) │        0.0437943 │                   MAI (F,4,[0.3, 0.48, 0.75]) │       5.20047e-6 │
# │                   MAI (G,4,[0.25, 0.5, 0.75]) │       6.25579e-6 │             MAI (G,5,[0.28, 0.37, 0.6, 0.81]) │       7.12773e-5 │
# └───────────────────────────────────────────────┴──────────────────┴───────────────────────────────────────────────┴──────────────────┘

######################################################################################
################## INTERVALO DE CONFIANZA ############################################
######################################################################################

## CREACION DE TRAYECTORIAS DE OPTIMA corr 

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


# Incluyendo Exclusión Fija en Base 00
# ┌───────┬───────────┬─────────┬───────────┐
# │       │       b00 │       T │       b10 │
# ├───────┼───────────┼─────────┼───────────┤
# │ upper │   1.31093 │ 0.53168 │ -0.419259 │
# │ lower │ -0.579893 │ -1.4531 │  -1.56325 │
# └───────┴───────────┴─────────┴───────────┘

# Considerando un Peso inicial 
# ┌───────┬───────────┬───────────┬───────────┐
# │       │       b00 │         T │       b10 │
# ├───────┼───────────┼───────────┼───────────┤
# │ upper │ -0.235807 │ -0.396603 │ -0.746202 │
# │ lower │  -1.91661 │  -1.79685 │  -1.78224 │
# └───────┴───────────┴───────────┴───────────┘
