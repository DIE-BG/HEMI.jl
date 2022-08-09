using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain



############ DATOS A UTILIZAR #########################

gtdata_eval = GTDATA[Date(2021, 12)]

########### CARGAMOS TRAYECTORIAS ###############

# DEFINIMOS LOS PATHS 
loadpath = datadir("results", "tray_infl", "mse")
tray_dir = joinpath(loadpath, "tray_infl")
loadpath_2019 = datadir("results", "tray_infl_2019", "mse")
tray_dir_2019 = joinpath(loadpath_2019, "tray_infl")
combination_loadpath  = datadir("results","optim_combination","mse")

save_results = datadir("results","eval","mse")

# RECOLECTAMOS LOS DATAFRAMES
df      = collect_results(loadpath)
df_19   = collect_results(loadpath_2019)
optim   = collect_results(combination_loadpath)

# CREAMOS DATAFRAMES PARA LAS MAI
df_mai      = df[[isa(x,InflationCoreMai) for x in df[:,:inflfn]],:]
df_mai_19   = df_19[[isa(x,InflationCoreMai) for x in df_19[:,:inflfn]],:]

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
optmai = df_weights[1,:optmai_mse2023]


######## HACEMOS COINCIDIR LAS TRAYECTORIAS CON SUS PESOS Y RENORMALIZAMOS LA MAI ####################

opt_w = DataFrame(
    :inflfn => [x for x in optmse.ensemble.functions],
    :inflfn_type => [typeof(x) for x in optmse.ensemble.functions], 
    :weight => optmse.weights
) 

opt_w_mai = DataFrame(
    :inflfn => [x for x in optmai.ensemble.functions],
    :inflfn_type => [typeof(x) for x in optmai.ensemble.functions], 
    :weight => optmai.weights
)

mai_indx = (x -> isa(x,CombinationFunction)).(opt_w.inflfn)
mai_w = opt_w[mai_indx,:weight][1]
opt_w_mai[!,:weight] = mai_w * opt_w_mai.weight

# PESO DE LA MAI OPTIMA
opt_w     = vcat(opt_w[.!mai_indx,:],opt_w_mai)

# DATAFRAMES RENORMALIZXADOS CON TRAYECTORIAS PONDERADAS
df_renorm = innerjoin(df,opt_w[:,[:inflfn_type,:weight]], on = :inflfn_type)[:,[:inflfn,:inflfn_type,:weight, :tray_infl]]
df_renorm[!,:w_tray] = df_renorm.weight .* df_renorm.tray_infl

df_renorm_19 = innerjoin(df_19,opt_w[:,[:inflfn_type,:weight]], on = :inflfn_type)[:,[:inflfn,:inflfn_type,:weight, :tray_infl]]
df_renorm_19[!,:w_tray] = df_renorm_19.weight .* df_renorm_19.tray_infl

df_renorm_mai    = df_renorm[(x -> isa(x,InflationCoreMai)).(df_renorm.inflfn),:]
df_renorm_19_mai = df_renorm_19[(x -> isa(x,InflationCoreMai)).(df_renorm_19.inflfn),:]


################# OBTENEMOS LAS TRAYECTORIAS #################################################


w_tray     = sum(df_renorm.w_tray, dims=1)[1]
w_tray_19  = sum(df_renorm_19.w_tray, dims=1)[1]

w_tray_mai     = sum(df_renorm_mai.w_tray, dims=1)[1] ./ mai_w 
w_tray_19_mai  = sum(df_renorm_19_mai.w_tray, dims=1)[1] ./ mai_w


##### AGREGAMOS COMBINACIONES OPTIMAS AL DATAFRAME RENORMALIZADO #############################

df_renorm    = vcat(df_renorm, DataFrame(:inflfn => [optmse, optmai], :tray_infl => [w_tray, w_tray_mai]), cols=:union)
df_renorm_19 = vcat(df_renorm_19, DataFrame(:inflfn => [optmse, optmai], :tray_infl => [w_tray_19, w_tray_19_mai]), cols=:union)


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


# Le devolvemos su peso a la OPTIMA y a la MAI OPTIMA
df_renorm[(x -> isa(x,CombinationFunction)).(df_renorm.inflfn),:weight] = [1, mai_w]

# Cremos un dataframe final
df_final = df_renorm[:, [:measure_name,:weight,:b00_mse,:trn_mse,:b10_mse,:b19_mse,:complete_mse]]

# pretty_table(df_final)
# ┌───────────────────────────────────────────────┬────────────┬──────────┬───────────┬───────────┬──────────┬──────────────┐
# │                                  measure_name │     weight │  b00_mse │   trn_mse │   b10_mse │  b19_mse │ complete_mse │
# │                                        String │   Float32? │  Float32 │   Float32 │   Float32 │  Float32 │      Float32 │
# ├───────────────────────────────────────────────┼────────────┼──────────┼───────────┼───────────┼──────────┼──────────────┤
# │     Media Truncada Equiponderada (57.0, 84.0) │   0.341524 │ 0.173026 │ 0.0756666 │ 0.0691272 │ 0.218107 │     0.116417 │
# │                 Percentil equiponderado 71.96 │   0.187792 │ 0.201842 │  0.119261 │ 0.0563398 │ 0.244139 │      0.12502 │
# │  Inflación de exclusión dinámica (0.34, 1.81) │  0.0127982 │ 0.327145 │  0.162758 │ 0.0867412 │ 0.291087 │     0.198941 │
# │       Media Truncada Ponderada (20.51, 95.98) │ 7.97753e-7 │ 0.344158 │  0.206836 │  0.104031 │ 0.293714 │     0.217329 │
# │                     Percentil ponderado 69.86 │   0.160404 │ 0.424832 │  0.253189 │  0.205343 │ 0.409463 │     0.306798 │
# │ Exclusión fija de gastos básicos IPC (14, 17) │        0.0 │ 0.831064 │  0.895471 │  0.448037 │ 0.642199 │     0.641695 │
# │                 MAI (FP,4,[0.28, 0.72, 0.76]) │   0.207104 │ 0.216984 │ 0.0836499 │ 0.0596975 │ 0.209307 │     0.131929 │
# │                  MAI (F,4,[0.38, 0.67, 0.83]) │  0.0903769 │ 0.256505 │  0.126606 │ 0.0953241 │ 0.327162 │     0.169651 │
# │            MAI (G,5,[0.06, 0.27, 0.74, 0.77]) │  8.3507e-8 │ 0.627207 │  0.366966 │  0.230421 │ 0.525295 │     0.416113 │
# │                    Subyacente óptima MSE 2023 │        1.0 │    0.185 │ 0.0746905 │ 0.0392289 │ 0.200627 │     0.106777 │
# │                           MAI óptima MSE 2023 │   0.297481 │ 0.208969 │ 0.0858078 │ 0.0642922 │ 0.217154 │     0.130709 │
# └───────────────────────────────────────────────┴────────────┴──────────┴───────────┴───────────┴──────────┴──────────────┘


# guardamos el resultado
using  CSV
mkpath(save_results)
CSV.write(joinpath(save_results,"eval.csv"), df_final)