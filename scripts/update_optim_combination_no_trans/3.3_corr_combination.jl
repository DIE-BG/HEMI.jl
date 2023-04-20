using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain


# DEFINIMOS PATHS
loadpath = datadir("results", "no_trans","tray_infl","corr")

combination_savepath  = datadir("results","no_trans","optim_combination","corr")

data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")

#CARGAMOS DATA A EVALUAR
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")

gtdata_eval = NOT_GTDATA[Date(2021, 12)]


#CREAMOS UNA FUNCION PARA ORDENAR LAS FUNCIONES
function rank(inflfn::InflationFunction)
    if inflfn isa InflationPercentileEq
        return 1
    elseif inflfn isa InflationPercentileWeighted
        return 2
    elseif inflfn isa InflationTrimmedMeanEq
        return 3
    elseif inflfn isa InflationTrimmedMeanWeighted
        return 4
    elseif inflfn isa InflationDynamicExclusion
        return 5
    elseif inflfn isa InflationFixedExclusionCPI
        return 6
    end
end


# CARGAMOS Y ORDENAMOS DATAFRAMES SEGUN LA MEDIDA DE INFLACION
df_results_B00 = collect_results(joinpath(loadpath,"B00"))
df_results_B10 = collect_results(joinpath(loadpath,"B10"))

df_results_B00.rank = rank.(df_results_B00.inflfn)
df_results_B10.rank = rank.(df_results_B00.inflfn)

sort!(df_results_B00, :rank)
sort!(df_results_B10, :rank)


# PATHS DE TRAYECTORIAS
df_results_B00.tray_path = map(x->joinpath(loadpath,"B00","tray_infl",basename(x)),df_results_B00.path)
df_results_B10.tray_path = map(x->joinpath(loadpath,"B10","tray_infl",basename(x)),df_results_B10.path)

# TRAYECTORIAS
tray_infl_B00 = mapreduce(hcat, df_results_B00.tray_path) do path
    load(path, "tray_infl")
end

tray_infl_B10 = mapreduce(hcat, df_results_B10.tray_path) do path
    load(path, "tray_infl")
end


# DEFINIMOS PARAMETRO
resamplefn = df_results_B00.resamplefn[1]
trendfn = df_results_B00.trendfn[1]
paramfn = df_results_B00.paramfn[1] #InflationTotalRebaseCPI(36, 3)
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)


# FILTRAMOS EXCLUSION FIJA
functions_B00 = df_results_B00.inflfn
components_mask_B00 = [!(fn isa InflationFixedExclusionCPI) for fn in functions_B00]

functions_B10 = df_results_B10.inflfn
components_mask_B10 = [!(fn isa InflationFixedExclusionCPI) for fn in functions_B10]

#####################################
### COMBINACION OPTIMA BASE 2000 y 2010


# DEFINIMOS PERIODOS DE COMBINACION
combine_period_00 =  GT_EVAL_B00 #EvalPeriod(Date(2001, 12), Date(2010, 12), "combperiod_B00") 
combine_period_10 =  GT_EVAL_B10 #EvalPeriod(Date(2011, 12), Date(2021, 12), "combperiod_B10") 

periods_filter_00 = eval_periods(gtdata_eval, combine_period_00)
periods_filter_10 = eval_periods(gtdata_eval, combine_period_10)

# CALCULAMOS LOS PESOS OPTIMOS
a_optim_00 = metric_combination_weights(
    tray_infl_B00[periods_filter_00, components_mask_B00, :],
    tray_infl_pob[periods_filter_00],
    metric = :corr
)

a_optim_10 = metric_combination_weights(
    tray_infl_B10[periods_filter_10, components_mask_B10, :],
    tray_infl_pob[periods_filter_10],
    metric = :corr
)

# Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
insert!(a_optim_00, findall(.!components_mask_B00)[1],0)
insert!(a_optim_10, findall(.!components_mask_B10)[1],0)

# CREAMOS SUBYACENTES OPTIMAS PARA CADA BASE
optcorrb00 = CombinationFunction(
    functions_B00...,
    a_optim_00, 
    "Subyacente óptima CORR no transable base 2000"
)

optcorrb10 = CombinationFunction(
    functions_B10...,
    a_optim_10, 
    "Subyacente óptima CORR no transable base 2010"
)

# EMPALMAMOS LA FUNCION PARA CREAR UNA SUBYACENTE OPTIMA NO TRANSABLE
optcorr2023_nt = Splice([optcorrb00, optcorrb10], [(Date(2011,01), Date(2011,11))], "Subyacente Óptima CORR 2023 No Transable", "SubOptCorr2023NT")

# GUARDAMOS  
wsave(joinpath(combination_savepath,"optcorr2023_nt.jld2"), "optcorr2023_nt", optcorr2023_nt)


# using PrettyTables
# pretty_table(DataFrame(
#        measure  = [measure_name(x) for x in optcorrb00.ensemble.functions],
#        wheights = optcorrb00.weights
#        )
# )
# ┌─────────────────────────────────────────────┬───────────┐
# │                                     measure │  wheights │
# │                                      String │   Float32 │
# ├─────────────────────────────────────────────┼───────────┤
# │                Percentil equiponderado 89.0 │ 0.0315523 │
# │                    Percentil ponderado 82.0 │  0.195219 │
# │   Media Truncada Equiponderada (63.0, 96.0) │  0.378063 │
# │       Media Truncada Ponderada (52.0, 97.0) │  0.230447 │
# │  Inflación de exclusión dinámica (0.8, 2.4) │  0.164818 │
# │ Exclusión fija de gastos básicos IPC (4, 1) │       0.0 │
# └─────────────────────────────────────────────┴───────────┘

# pretty_table(DataFrame(
#        measure  = [measure_name(x) for x in optcorrb10.ensemble.functions],
#        wheights = optcorrb10.weights
#        )
# )

# ┌─────────────────────────────────────────────┬────────────┐
# │                                     measure │   wheights │
# │                                      String │    Float32 │
# ├─────────────────────────────────────────────┼────────────┤
# │                Percentil equiponderado 86.0 │   0.516417 │
# │                    Percentil ponderado 89.0 │  0.0897511 │
# │   Media Truncada Equiponderada (77.0, 93.0) │   0.205611 │
# │       Media Truncada Ponderada (79.0, 97.0) │   0.188117 │
# │  Inflación de exclusión dinámica (0.5, 2.1) │ 5.90079e-6 │
# │ Exclusión fija de gastos básicos IPC (4, 1) │        0.0 │
# └─────────────────────────────────────────────┴────────────┘
