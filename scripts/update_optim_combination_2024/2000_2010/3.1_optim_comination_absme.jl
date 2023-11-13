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

combination_savepath  = datadir("optim_comb_2024","2000_2010","optim_combination","absme","fx")

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
a_optim_00 = metric_combination_weights(
    tray_infl[periods_filter_00, components_mask_b00, :],
    tray_infl_pob[periods_filter_00],
    metric = :absme
)

a_optim_10 = metric_combination_weights(
    tray_infl[periods_filter_10, components_mask_b10, :],
    tray_infl_pob[periods_filter_10],
    metric = :absme
)


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
# │                Percentil equiponderado 72.0 │         0.0266561 │                Percentil equiponderado 72.0 │          0.407321 │
# │                    Percentil ponderado 69.0 │        0.00697998 │                    Percentil ponderado 72.0 │        0.00105415 │
# │   Media Truncada Equiponderada (63.0, 80.0) │          0.245002 │   Media Truncada Equiponderada (57.0, 83.0) │          0.404631 │
# │       Media Truncada Ponderada (63.0, 76.0) │          0.384159 │       Media Truncada Ponderada (67.0, 78.0) │        0.00912122 │
# │  Inflación de exclusión dinámica (1.2, 3.6) │          0.337279 │  Inflación de exclusión dinámica (0.7, 3.0) │          0.177772 │
# │ Exclusión fija de gastos básicos IPC (9, 6) │               0.0 │ Exclusión fija de gastos básicos IPC (9, 6) │               0.0 │
# └─────────────────────────────────────────────┴───────────────────┴─────────────────────────────────────────────┴───────────────────┘

# Peso de las Medidas incluyendo Exclusión Fija en Base00
# ┌─────────────────────────────────────────────┬───────────────────┬─────────────────────────────────────────────┬───────────────────┐
# │           Subyacente óptima ABSME base 2000 │ SubOptABSME_B00_w │           Subyacente óptima ABSME base 2010 │ SubOptABSME_B10_w │
# │                                         Any │               Any │                                         Any │               Any │
# ├─────────────────────────────────────────────┼───────────────────┼─────────────────────────────────────────────┼───────────────────┤
# │                Percentil equiponderado 72.0 │          0.161137 │                Percentil equiponderado 72.0 │          0.407321 │
# │                    Percentil ponderado 69.0 │           0.16507 │                    Percentil ponderado 72.0 │        0.00105415 │
# │   Media Truncada Equiponderada (63.0, 80.0) │          0.165985 │   Media Truncada Equiponderada (57.0, 83.0) │          0.404631 │
# │       Media Truncada Ponderada (63.0, 76.0) │          0.167349 │       Media Truncada Ponderada (67.0, 78.0) │        0.00912122 │
# │  Inflación de exclusión dinámica (1.2, 3.6) │          0.168555 │  Inflación de exclusión dinámica (0.7, 3.0) │          0.177772 │
# │ Exclusión fija de gastos básicos IPC (9, 6) │          0.171884 │ Exclusión fija de gastos básicos IPC (9, 6) │               0.0 │
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


# ┌───────┬───────────┬───────────┬───────────┐
# │       │       b00 │         T │       b10 │
# ├───────┼───────────┼───────────┼───────────┤
# │ upper │   1.27352 │  0.856775 │  0.704646 │
# │ lower │ -0.972867 │ -0.596535 │ -0.516272 │
# └───────┴───────────┴───────────┴───────────┘

#Incluyendo Exclusión Fija en Base00
# ┌───────┬──────────┬───────────┬───────────┐
# │       │      b00 │         T │       b10 │
# ├───────┼──────────┼───────────┼───────────┤
# │ upper │  1.12938 │  0.823653 │  0.704646 │
# │ lower │ -0.98474 │ -0.823295 │ -0.516272 │
# └───────┴──────────┴───────────┴───────────┘