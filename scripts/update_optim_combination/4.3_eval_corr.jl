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
loadpath = datadir("results", "tray_infl", "corr")
tray_dir = joinpath(loadpath, "tray_infl")
loadpath_2019 = datadir("results", "tray_infl_2019", "corr")
tray_dir_2019 = joinpath(loadpath_2019, "tray_infl")
combination_loadpath  = datadir("results","optim_combination","corr")

save_results = datadir("results","eval","corr")

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
optcorr = df_weights[1,:optcorr2023]
optmai = df_weights[1,:optmai_corr2023]


######## HACEMOS COINCIDIR LAS TRAYECTORIAS CON SUS PESOS Y RENORMALIZAMOS LA MAI ####################

opt_w = DataFrame(
    :inflfn => [x for x in optcorr.ensemble.functions],
    :inflfn_type => [typeof(x) for x in optcorr.ensemble.functions], 
    :weight => optcorr.weights
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

df_renorm    = vcat(df_renorm, DataFrame(:inflfn => [optcorr, optmai], :tray_infl => [w_tray, w_tray_mai]), cols=:union)
df_renorm_19 = vcat(df_renorm_19, DataFrame(:inflfn => [optcorr, optmai], :tray_infl => [w_tray_19, w_tray_19_mai]), cols=:union)


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
df_renorm[!,:complete_corr] = (x -> eval_metrics(x,tray_infl_pob)[:corr]).(df_renorm.tray_infl)

# PERIDO BASE 2000
df_renorm[!,:b00_corr] = (x -> eval_metrics(x[b00_mask,:,:],tray_infl_pob[b00_mask])[:corr]).(df_renorm.tray_infl)

# PERIDO DE TRANSICION
df_renorm[!,:trn_corr] = (x -> eval_metrics(x[trn_mask,:,:],tray_infl_pob[trn_mask])[:corr]).(df_renorm.tray_infl)

# PERIDO BASE 2010
df_renorm[!,:b10_corr] = (x -> eval_metrics(x[b10_mask,:,:],tray_infl_pob[b10_mask])[:corr]).(df_renorm.tray_infl)

# PERIODO 2001-2019
df_renorm[!,:b19_corr] = (x -> eval_metrics(x,tray_infl_pob_19)[:corr]).(df_renorm_19.tray_infl)




######## PULIMOS LOS RESULTADOS ##########################

# Le agregamos nombres a las funciones
df_renorm[!,:measure_name] = measure_name.(df_renorm.inflfn)


# Le devolvemos su peso a la OPTIMA y a la MAI OPTIMA
df_renorm[(x -> isa(x,CombinationFunction)).(df_renorm.inflfn),:weight] = [1, mai_w]

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
        if length(x.weights) == 3
            out = 7
        elseif length(x.weights) == 7
            out = 8
        end
    elseif x isa InflationCoreMai
        if string(x.method)[2:3]=="FP"
            out = 9
        elseif string(x.method)[2:3]=="F,"
            out = 10
        elseif string(x.method)[2:3]=="G,"
            out = 11
        end
    end 
    out
end

df_renorm[!,:rank_order] = inflfn_rank.(df_renorm.inflfn)

#ordenamos
sort!(df_renorm,:rank_order)

# Cremos un dataframe final
df_final = df_renorm[:, [:measure_name,:weight,:b00_corr,:trn_corr,:b10_corr,:b19_corr,:complete_corr]]

# using PrettyTables
# pretty_table(df_final)
# ┌───────────────────────────────────────────────┬─────────────┬──────────┬──────────┬──────────┬──────────┬───────────────┐
# │                                  measure_name │      weight │ b00_corr │ trn_corr │ b10_corr │ b19_corr │ complete_corr │
# │                                        String │    Float32? │  Float32 │  Float32 │  Float32 │  Float32 │       Float32 │
# ├───────────────────────────────────────────────┼─────────────┼──────────┼──────────┼──────────┼──────────┼───────────────┤
# │                 Percentil equiponderado 80.86 │    0.291214 │ 0.975114 │ 0.983872 │ 0.911682 │ 0.985763 │      0.992383 │
# │                      Percentil ponderado 81.0 │  1.30411e-6 │ 0.938299 │ 0.980331 │ 0.791392 │ 0.975788 │      0.982126 │
# │     Media Truncada Equiponderada (55.0, 92.0) │    0.248435 │ 0.978721 │ 0.985344 │ 0.915579 │ 0.986772 │      0.993255 │
# │       Media Truncada Ponderada (53.56, 96.47) │   0.0865183 │  0.94964 │ 0.982119 │ 0.781927 │ 0.979123 │       0.98387 │
# │  Inflación de exclusión dinámica (0.46, 4.97) │   0.0530187 │ 0.946347 │ 0.978487 │ 0.762266 │ 0.978094 │      0.982066 │
# │ Exclusión fija de gastos básicos IPC (14, 51) │         0.0 │  0.94211 │ 0.973802 │ 0.643733 │ 0.979527 │       0.97927 │
# │                          MAI óptima CORR 2023 │    0.320901 │ 0.975416 │ 0.988029 │ 0.900563 │ 0.982641 │      0.988648 │
# │                   Subyacente óptima CORR 2023 │         1.0 │ 0.977935 │ 0.987992 │  0.91267 │ 0.986509 │      0.992648 │
# │                 MAI (FP,4,[0.26, 0.51, 0.75]) │     0.15468 │ 0.975304 │ 0.988008 │ 0.900723 │  0.98262 │      0.988608 │
# │                   MAI (F,4,[0.25, 0.5, 0.74]) │    0.165794 │  0.97512 │ 0.987969 │ 0.899583 │ 0.982588 │      0.988616 │
# │                   MAI (G,4,[0.26, 0.5, 0.75]) │ 0.000426675 │ 0.940058 │ 0.984834 │ 0.767826 │ 0.970803 │      0.977716 │
# └───────────────────────────────────────────────┴─────────────┴──────────┴──────────┴──────────┴──────────┴───────────────┘

# guardamos el resultado
using  CSV
mkpath(save_results)
CSV.write(joinpath(save_results,"eval.csv"), df_final)