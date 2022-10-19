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
loadpath = datadir("results", "tray_infl", "absme")
tray_dir = joinpath(loadpath, "tray_infl")
loadpath_2019 = datadir("results", "tray_infl_2019", "absme")
tray_dir_2019 = joinpath(loadpath_2019, "tray_infl")
combination_loadpath  = datadir("results","optim_combination","absme_noMAI_rescale")

save_results = datadir("results","eval","absme_noMAI_rescale")

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
optabsme = df_weights[1,:optabsme2023]

######## HACEMOS COINCIDIR LAS TRAYECTORIAS CON SUS PESOS Y RENORMALIZAMOS LA MAI ####################

opt_w = DataFrame(
    :inflfn => [x for x in optabsme.ensemble.functions],
    :inflfn_type => [typeof(x) for x in optabsme.ensemble.functions], 
    :weight => optabsme.weights
) 

# DATAFRAMES RENORMALIZXADOS CON TRAYECTORIAS PONDERADAS
df_renorm = leftjoin(df,opt_w[:,[:inflfn_type,:weight]], on = :inflfn_type)[:,[:inflfn,:inflfn_type,:weight, :tray_infl]]
df_renorm.weight = coalesce.(df_renorm.weight,0)
df_renorm[!,:w_tray] = df_renorm.weight .* df_renorm.tray_infl

df_renorm_19 = leftjoin(df_19,opt_w[:,[:inflfn_type,:weight]], on = :inflfn_type)[:,[:inflfn,:inflfn_type,:weight, :tray_infl]]
df_renorm_19.weight = coalesce.(df_renorm_19.weight,0)
df_renorm_19[!,:w_tray] = df_renorm_19.weight .* df_renorm_19.tray_infl

################# OBTENEMOS LAS TRAYECTORIAS #################################################

w_tray     = sum(df_renorm.w_tray, dims=1)[1]
w_tray_19  = sum(df_renorm_19.w_tray, dims=1)[1]

##### AGREGAMOS COMBINACIONES OPTIMAS AL DATAFRAME RENORMALIZADO #############################

df_renorm    = vcat(df_renorm, DataFrame(:inflfn => [optabsme], :tray_infl => [w_tray]), cols=:union)
df_renorm_19 = vcat(df_renorm_19, DataFrame(:inflfn => [optabsme], :tray_infl => [w_tray_19]), cols=:union)


####### DEFINIMOS PARAMETROS ######################################################

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
df_renorm[!,:complete_absme] = (x -> eval_metrics(x,tray_infl_pob)[:absme]).(df_renorm.tray_infl)

# PERIDO BASE 2000
df_renorm[!,:b00_absme] = (x -> eval_metrics(x[b00_mask,:,:],tray_infl_pob[b00_mask])[:absme]).(df_renorm.tray_infl)

# PERIDO DE TRANSICION
df_renorm[!,:trn_absme] = (x -> eval_metrics(x[trn_mask,:,:],tray_infl_pob[trn_mask])[:absme]).(df_renorm.tray_infl)

# PERIDO BASE 2010
df_renorm[!,:b10_absme] = (x -> eval_metrics(x[b10_mask,:,:],tray_infl_pob[b10_mask])[:absme]).(df_renorm.tray_infl)

# PERIODO 2001-2019
df_renorm[!,:b19_absme] = (x -> eval_metrics(x,tray_infl_pob_19)[:absme]).(df_renorm_19.tray_infl)


######## PULIMOS LOS RESULTADOS ##########################

# Le agregamos nombres a las funciones
df_renorm[!,:measure_name] = measure_name.(df_renorm.inflfn)


# Le devolvemos su peso a la OPTIMA y a la MAI OPTIMA
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
df_final = df_renorm[:, [:measure_name,:weight,:b00_absme,:trn_absme,:b10_absme,:b19_absme,:complete_absme]]

# pretty_table(df_final)
# ┌──────────────────────────────────────────────┬──────────┬────────────┬───────────┬───────────┬─────────────┬────────────────┐
# │                                 measure_name │   weight │  b00_absme │ trn_absme │ b10_absme │   b19_absme │ complete_absme │
# │                                       String │    Real? │    Float32 │   Float32 │   Float32 │     Float32 │        Float32 │
# ├──────────────────────────────────────────────┼──────────┼────────────┼───────────┼───────────┼─────────────┼────────────────┤
# │                Percentil equiponderado 71.92 │ 0.165285 │  0.0722941 │  0.225484 │  0.117635 │   0.0570941 │      0.0160726 │
# │                    Percentil ponderado 70.23 │ 0.120182 │   0.348092 │  0.105118 │  0.268993 │   0.0336459 │      0.0175834 │
# │  Media Truncada Equiponderada (33.41, 93.73) │ 0.474419 │   0.169975 │  0.113316 │  0.318311 │ 0.000780069 │      0.0777672 │
# │      Media Truncada Ponderada (32.16, 93.26) │ 0.135852 │   0.287649 │ 0.0196027 │  0.133075 │  0.00111028 │      0.0641798 │
# │ Inflación de exclusión dinámica (1.05, 3.49) │ 0.104262 │  0.0934483 │  0.169014 │ 0.0295413 │ 0.000153863 │      0.0648113 │
# │  Exclusión fija de gastos básicos IPC (9, 6) │      0.0 │   0.109512 │  0.680816 │  0.182561 │  0.00136531 │       0.172264 │
# │                 Subyacente óptima ABSME 2023 │        1 │ 0.00193345 │ 0.0833769 │   0.12313 │   0.0129756 │      0.0571403 │
# │          MAI (FP,5,[0.38, 0.43, 0.57, 0.85]) │        0 │    0.34876 │ 0.0326877 │  0.233728 │  0.00382644 │      0.0418813 │
# │                  MAI (F,4,[0.17, 0.4, 0.85]) │        0 │  0.0781019 │  0.081888 │  0.192522 │   0.0091444 │       0.135722 │
# │     MAI (G,6,[0.15, 0.32, 0.53, 0.62, 0.78]) │        0 │   0.723735 │  0.197893 │  0.439237 │    0.010727 │       0.115835 │
# └──────────────────────────────────────────────┴──────────┴────────────┴───────────┴───────────┴─────────────┴────────────────┘

# guardamos el resultado
using  CSV
mkpath(save_results)
CSV.write(joinpath(save_results,"eval.csv"), df_final)