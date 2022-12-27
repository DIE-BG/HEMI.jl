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
loadpath = datadir("results","no_trans", "tray_infl", "corr")
tray_dir = joinpath(loadpath, "tray_infl")
loadpath_2019 = datadir("results","no_trans", "tray_infl_2019", "corr")
tray_dir_2019 = joinpath(loadpath_2019, "tray_infl")
combination_loadpath  = datadir("results","no_trans","optim_combination","corr")

save_results = datadir("results","no_trans","eval","corr")

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
optcorr = df_weights[1,:optcorr2023]


######## HACEMOS COINCIDIR LAS TRAYECTORIAS CON SUS PESOS Y RENORMALIZAMOS LA MAI ####################

opt_w = DataFrame(
    :inflfn => [x for x in optcorr.ensemble.functions],
    :inflfn_type => [typeof(x) for x in optcorr.ensemble.functions], 
    :weight => optcorr.weights
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

df_renorm    = vcat(df_renorm, DataFrame(:inflfn => [optcorr], :tray_infl => [w_tray]), cols=:union)
df_renorm_19 = vcat(df_renorm_19, DataFrame(:inflfn => [optcorr], :tray_infl => [w_tray_19]), cols=:union)


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
df_final = df_renorm[:, [:measure_name,:weight,:b00_corr,:trn_corr,:b10_corr,:b19_corr,:complete_corr]]

# using PrettyTables
# pretty_table(df_final)
# ┌───────────────────────────────────────────────┬────────────┬──────────┬──────────┬──────────┬──────────┬───────────────┐
# │                                  measure_name │     weight │ b00_corr │ trn_corr │ b10_corr │ b19_corr │ complete_corr │
# │                                        String │   Float32? │  Float32 │  Float32 │  Float32 │  Float32 │       Float32 │
# ├───────────────────────────────────────────────┼────────────┼──────────┼──────────┼──────────┼──────────┼───────────────┤
# │                 Percentil equiponderado 79.84 │   0.254759 │ 0.863131 │ 0.980241 │ 0.746329 │ 0.975106 │      0.977753 │
# │                      Percentil ponderado 82.2 │  0.0366308 │ 0.843677 │ 0.976447 │ 0.596974 │ 0.972414 │       0.97317 │
# │   Media Truncada Equiponderada (16.41, 98.45) │   0.416954 │ 0.882948 │ 0.980475 │ 0.768324 │ 0.979878 │      0.981702 │
# │        Media Truncada Ponderada (31.7, 96.11) │ 3.94964e-6 │ 0.868388 │ 0.984021 │ 0.650562 │ 0.979127 │      0.979933 │
# │  Inflación de exclusión dinámica (0.85, 2.32) │   0.291732 │ 0.871634 │  0.98224 │ 0.669022 │ 0.978923 │      0.979955 │
# │ Exclusión fija de gastos básicos IPC (13, 57) │        0.0 │ 0.886242 │ 0.989597 │  0.45894 │ 0.981926 │      0.982428 │
# │                   Subyacente óptima CORR 2023 │        1.0 │ 0.900711 │ 0.985907 │ 0.795016 │ 0.983066 │      0.984583 │
# └───────────────────────────────────────────────┴────────────┴──────────┴──────────┴──────────┴──────────┴───────────────┘

# guardamos el resultado
using  CSV
mkpath(save_results)
CSV.write(joinpath(save_results,"eval.csv"), df_final)

#################################
######### PLOTS #################
#################################
# NO DESCOMENTAR
#=
using Plots
using StatsBase

for i in 1:7

    TITLE = df_renorm[i,:measure_name]
    PARAM = tray_infl_pob
    X = infl_dates(gtdata_eval)
    TRAYS = df_renorm[i,:tray_infl]
    TRAY_INFL = [ TRAYS[:,:,i] for i in 1:size(TRAYS)[3]]
    TRAY_VEC = sample(TRAY_INFL,500)
    TRAY_PROM = mean(TRAYS,dims=3)[:,:,1]
    TRAY_MED = median(TRAYS,dims=3)[:,:,1]
    TRAY_25 = [percentile(x[:],25) for x in eachslice(TRAYS,dims=1)][:,:] 
    TRAY_75 = [percentile(x[:],75) for x in eachslice(TRAYS,dims=1)][:,:]
    # cambiamos el rango de fechas
    #X = X[b10_mask]
    #TRAY_VEC = map(x -> x[b10_mask],TRAY_VEC)
    #PARAM = PARAM[b10_mask]

    p=plot(
        X,
        TRAY_VEC;
        legend = true,
        label = false,
        c="grey12",
        linewidth = 0.25/2,
        title = TITLE,
        size = (900,600),
        ylims = (0,14)
    )

    p=plot!(
        X,PARAM;
        legend = true,
        label="Parámetro",
        c="blue3",
        linewidth = 3.5
    )

    p=plot!(
        X,TRAY_PROM;
        legend = true,
        label="Promedio",
        c="red",
        linewidth = 3.5
    )

    p=plot!(
        X,TRAY_MED;
        legend = true,
        label="Mediana",
        c="green",
        linewidth = 2.0
    )

    p=plot!(
        X,TRAY_25;
        legend = true,
        label = "Percentil 25",
        c="green",
        linewidth = 2.0,
        linestyle=:dash
    )

    p=plot!(
        X,TRAY_75;
        legend = true,
        label = "Percentil 75",
        c="green",
        linewidth = 2.0,
        linestyle=:dash
    )
    display(p)
    savefig("C:\\Users\\DJGM\\Desktop\\PLOTS\\2023_no_trans\\plot_"*string(i+14)*".png")
end
=#