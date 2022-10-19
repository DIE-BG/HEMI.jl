using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain

data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")

############ DATOS A UTILIZAR #########################

gtdata_eval = NOT_GTDATA[Date(2021, 12)]

########### CARGAMOS TRAYECTORIAS ###############

# DEFINIMOS LOS PATHS 
loadpath = datadir("results", "no_trans","tray_infl", "mse")
tray_dir = joinpath(loadpath, "tray_infl")
loadpath_2019 = datadir("results", "no_trans","tray_infl_2019", "mse")
tray_dir_2019 = joinpath(loadpath_2019, "tray_infl")
combination_loadpath  = datadir("results","no_trans","optim_combination","mse")

save_results = datadir("results","no_trans","eval","mse")

# RECOLECTAMOS LOS DATAFRAMES
df      = collect_results(loadpath)
df_19   = collect_results(loadpath_2019)
optim   = collect_results(combination_loadpath)

# CARGAMOS LAS TRAYECTORIAS CORRESPONDIENTES
df[!,:tray_path] = joinpath.(tray_dir,basename.(df.path))
df[!,:tray_infl] = [x["tray_infl"] for x in load.(df.tray_path)]
df[!, :inflfn_type] = typeof.(df.inflfn)

df_19[!,:tray_path] = joinpath.(tray_dir_2019,basename.(df_19.path))
df_19[!,:tray_infl] = [x["tray_infl"] for x in load.(df_19.tray_path)]
df_19[!, :inflfn_type] = typeof.(df.inflfn)

######## CARGAMOS LOS PESOS #####################################

df_weights = collect_results(combination_loadpath)
optmse = df_weights[1,:optmse2023]


######## HACEMOS COINCIDIR LAS TRAYECTORIAS CON SUS PESOS Y RENORMALIZAMOS LA MAI ####################

opt_w = DataFrame(
    :inflfn => [x for x in optmse.ensemble.functions],
    :inflfn_type => [typeof(x) for x in optmse.ensemble.functions], 
    :weight => optmse.weights
) 

# DATAFRAMES RENORMALIZXADOS CON TRAYECTORIAS PONDERADAS
df_renorm = innerjoin(df,opt_w[:,[:inflfn_type,:weight]], on = :inflfn_type)[:,[:inflfn,:inflfn_type,:weight, :tray_infl]]
df_renorm[!,:w_tray] = df_renorm.weight .* df_renorm.tray_infl

df_renorm_19 = innerjoin(df_19,opt_w[:,[:inflfn_type,:weight]], on = :inflfn_type)[:,[:inflfn,:inflfn_type,:weight, :tray_infl]]
df_renorm_19[!,:w_tray] = df_renorm_19.weight .* df_renorm_19.tray_infl

################# OBTENEMOS LAS TRAYECTORIAS #################################################

w_tray     = sum(df_renorm.w_tray, dims=1)[1]
w_tray_19  = sum(df_renorm_19.w_tray, dims=1)[1]

##### AGREGAMOS COMBINACIONES OPTIMAS AL DATAFRAME RENORMALIZADO #############################

df_renorm    = vcat(df_renorm, DataFrame(:inflfn => [optmse], :tray_infl => [w_tray]), cols=:union)
df_renorm_19 = vcat(df_renorm_19, DataFrame(:inflfn => [optmse], :tray_infl => [w_tray_19]), cols=:union)


############# DEFINIMOS PARAMETROS ######################################################

# PARAMETRO HASTA 2021
param = InflationParameter(
    InflationTotalRebaseCPI(36, 3), 
    ResampleScrambleVarMonths(), 
    TrendRandomWalk()
)

# PARAMETRO HASTA 2019 (para evaluacion en periodo de optimizacion de medidas individuales)
param_2019 = InflationParameter(
    InflationTotalRebaseCPI(36, 2), 
    ResampleScrambleVarMonths(), 
    TrendRandomWalk()
)

# TRAYECOTRIAS DE LOS PARAMETROS 
tray_infl_pob      = param(gtdata_eval)
tray_infl_pob_19   = param_2019(gtdata_eval[Date(2019,12)])


############ DEFINIMOS PERIODOS DE EVALUACION ############################################

period_b00 = EvalPeriod(Date(2001,12), Date(2010,12), "b00")
period_trn = EvalPeriod(Date(2011,01), Date(2011,11), "trn")
period_b10 = EvalPeriod(Date(2011,12), Date(2021,12), "b10")

b00_mask = eval_periods(gtdata_eval, period_b00)
trn_mask = eval_periods(gtdata_eval, period_trn)
b10_mask = eval_periods(gtdata_eval, period_b10)


##### EVALUAMOS ############################

# PERIDO COMPLETO (2001-2021)
df_renorm[!,:complete_mse] = (x -> eval_metrics(x,tray_infl_pob)[:mse]).(df_renorm.tray_infl)

# PERIDO BASE 2000
df_renorm[!,:b00_mse] = (x -> eval_metrics(x[b00_mask,:,:],tray_infl_pob[b00_mask])[:mse]).(df_renorm.tray_infl)

# PERIDO DE TRANSICION
df_renorm[!,:trn_mse] = (x -> eval_metrics(x[trn_mask,:,:],tray_infl_pob[trn_mask])[:mse]).(df_renorm.tray_infl)

# PERIDO BASE 2010
df_renorm[!,:b10_mse] = (x -> eval_metrics(x[b10_mask,:,:],tray_infl_pob[b10_mask])[:mse]).(df_renorm.tray_infl)

# PERIODO 2001-2019
df_renorm[!,:b19_mse] = (x -> eval_metrics(x,tray_infl_pob_19)[:mse]).(df_renorm_19.tray_infl)




######## PULIMOS LOS RESULTADOS ##########################

# Le agregamos nombres a las funciones
df_renorm[!,:measure_name] = measure_name.(df_renorm.inflfn)

# Le devolvemos su peso a la OPTIMA
df_renorm[(x -> isa(x,CombinationFunction)).(df_renorm.inflfn),:weight] = [1]

# Defininimos una funcion para ordenar los resultados en el orden de filas deseado.
function inflfn_rank(x)
    if x isa InflationPercentileEq
        out = 1
    elseif x isa InflationPercentileWeighted
        out = 2
    elseif x isa InflationTrimmedMeanEq
        out = 3
    elseif x isa InflationTrimmedMeanWeighted
        out = 4
    elseif x isa InflationDynamicExclusion
        out = 5
    elseif x isa InflationFixedExclusionCPI
        out = 6
    elseif x isa CombinationFunction
        out = 7
        end
    out
end

df_renorm[!,:rank_order] = inflfn_rank.(df_renorm.inflfn)

#ordenamos
sort!(df_renorm,:rank_order)

# Cremos un dataframe final
df_final = df_renorm[:, [:measure_name,:weight,:b00_mse,:trn_mse,:b10_mse,:b19_mse,:complete_mse]]

# using PrettyTables
# pretty_table(df_final)
# ┌───────────────────────────────────────────────┬────────────┬──────────┬──────────┬──────────┬──────────┬──────────────┐
# │                                  measure_name │     weight │  b00_mse │  trn_mse │  b10_mse │  b19_mse │ complete_mse │
# │                                        String │   Float32? │  Float32 │  Float32 │  Float32 │  Float32 │      Float32 │
# ├───────────────────────────────────────────────┼────────────┼──────────┼──────────┼──────────┼──────────┼──────────────┤
# │                 Percentil equiponderado 71.84 │ 2.03072e-9 │ 0.877697 │  1.16979 │ 0.509863 │ 0.581089 │     0.706349 │
# │                     Percentil ponderado 69.34 │ 1.82954e-8 │ 0.891715 │ 0.562155 │ 0.369096 │ 0.551539 │     0.614279 │
# │   Media Truncada Equiponderada (24.71, 96.28) │   0.999999 │ 0.505169 │  0.52378 │ 0.117053 │ 0.298626 │     0.311155 │
# │        Media Truncada Ponderada (11.2, 99.55) │ 5.25671e-7 │ 0.577895 │ 0.367749 │ 0.183291 │ 0.339003 │     0.370183 │
# │  Inflación de exclusión dinámica (0.81, 3.78) │ 3.78395e-8 │ 0.578671 │ 0.418231 │  0.25187 │ 0.362794 │      0.40727 │
# │ Exclusión fija de gastos básicos IPC (13, 18) │        0.0 │ 0.707091 │ 0.571861 │ 0.608339 │ 0.449241 │     0.651337 │
# │       Subyacente óptima MSE 2023 no transable │        1.0 │ 0.505169 │  0.52378 │ 0.117053 │ 0.298626 │     0.311155 │
# └───────────────────────────────────────────────┴────────────┴──────────┴──────────┴──────────┴──────────┴──────────────┘


# guardamos el resultado
using  CSV
mkpath(save_results)
CSV.write(joinpath(save_results,"eval.csv"), df_final)