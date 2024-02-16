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
loadpath = datadir("results","optim_comb_2024_B","tray_infl","mse")

combination_savepath  = datadir("results","optim_comb_2024_B","optim_combination","mse")

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
components_mask = [!(fn isa InflationFixedExclusionCPI || fn isa  InflationCoreMai) for fn in functions] 

#####################################
### COMBINACION OPTIMA

# DEFINIMOS PERIODOS DE COMBINACION
combine_period =  CompletePeriod() 
periods_filter = eval_periods(gtdata_eval, CompletePeriod())

# CALCULAMOS LOS PESOS OPTIMOS
a_optim = share_combination_weights(
    tray_infl[periods_filter, components_mask, :],
    tray_infl_pob[periods_filter],
    show_status=true
)

# a_optim = metric_combination_weights(
#     tray_infl[periods_filter, components_mask, :],
#     tray_infl_pob[periods_filter],
#     metric=:mse,
#     w_start = [ 0.263894  0.103842  0.264964  0.146457  0.167876  0.0529677][:]
# )


a_optim = [0.482095  0.0553004  0.289238  1.81019f-7  0.173366][:]
# Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
insert!(a_optim, findall(.!components_mask)[1],0)
#insert!(a_optim_10, findall(.!components_mask_b10)[1],0)

###############################################################
# tray_w = sum(a_optim' .*  tray_infl[periods_filter,:, :],dims=2)
# metrics = eval_metrics(tray_w, tray_infl_pob[periods_filter])
# metrics[:mse] # 0.11948711481980118
###############################################################

# CREAMOS SUBYACENTE OPTIMAS 
optmse2024_b = CombinationFunction(
    functions[1:6]...,
    a_optim, 
    "Subyacente óptima MSE 2024 B",
    "SubOptMSE_2024_B"
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
    :inflfn => optmse2024_b
)|> dict_list

run_batch(gtdata_eval, config, combination_savepath; savetrajectories = true)


## RESULTADOS 
using PrettyTables
pretty_table(components(optmse2024_b))

# ┌───────────────────────────────────────────────┬────────────┐
# │                                       measure │    weights │
# │                                        String │    Float64 │
# ├───────────────────────────────────────────────┼────────────┤
# │                  Percentil equiponderado 72.0 │   0.482095 │
# │                      Percentil ponderado 70.0 │  0.0553004 │
# │     Media Truncada Equiponderada (62.0, 80.0) │   0.289238 │
# │         Media Truncada Ponderada (23.0, 95.0) │ 1.81019e-7 │
# │    Inflación de exclusión dinámica (0.3, 1.5) │   0.173366 │
# │ Exclusión fija de gastos básicos IPC (13, 18) │        0.0 │
# └───────────────────────────────────────────────┴────────────┘


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
quant_0125 = quantile.(vec.([error_tray[:,:]]),0.0125)  
quant_9875 = quantile.(vec.([error_tray[:,:]]),0.9875) 

bounds =transpose(hcat(-quant_0125,-quant_9875))

using PrettyTables
pretty_table(hcat(["upper","lower"],bounds),["","CompletePereiod()"])

# ┌───────┬───────────────────┐
# │       │ CompletePereiod() │
# ├───────┼───────────────────┤
# │ upper │          0.997946 │
# │ lower │         -0.640623 │
# └───────┴───────────────────┘