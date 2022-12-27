using DrWatson
@quickactivate "HEMI"

using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI


data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")

########################
#### GTDATA_EVAL #######
########################

gtdata_eval = NOT_GTDATA[Date(2021, 12)]

#########################################################################################
############# DEFINIMOS PARAMETROS ######################################################
#########################################################################################

# PARAMETRO HASTA 2021
param = InflationParameter(
    InflationTotalRebaseCPI(36, 2), 
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


################################################################################
########################### GEN TRAY MSE #######################################
################################################################################

genconfig = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 2),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    #:traindate => Date(2021, 12),
    :nsim => 10_000
)

savepath    = datadir("results", "no_trans", "tray_infl_test", "mse")
savepath_19 = datadir("results", "no_trans", "tray_infl_test", "tray_19","mse")

inflfn_mse = [
    InflationPercentileEq(x) for x in [11:2:99...]
]

config    =  merge(genconfig, Dict(:traindate => Date(2021, 12), :inflfn => inflfn_mse)) |> dict_list
config_19 =  merge(genconfig, Dict(:traindate => Date(2019, 12), :inflfn => inflfn_mse)) |> dict_list

# run_batch(NOT_GTDATA, config, savepath; savetrajectories = true)
# run_batch(NOT_GTDATA, config_19, savepath_19; savetrajectories = true)

################################################################################
########################### PLOT DE EVALUACION #################################
################################################################################

######### CARGAMOS DATOS Y TRAYECTORIAS ###########################################

loadpath    = datadir("results", "no_trans","tray_infl_test","mse")
loadpath_19 = datadir("results", "no_trans","tray_infl_test","tray_19","mse")

tray_dir    = joinpath(loadpath, "tray_infl")
tray_dir_19 = joinpath(loadpath_19, "tray_infl")

df     = collect_results(loadpath)
df_19  = collect_results(loadpath_19)

df[!,:tray_path] = joinpath.(tray_dir,basename.(df.path))
df[!,:tray_infl] = [x["tray_infl"] for x in load.(df.tray_path)]

df_19[!,:tray_path] = joinpath.(tray_dir_19,basename.(df_19.path))
df_19[!,:tray_infl] = [x["tray_infl"] for x in load.(df_19.tray_path)]

df[!, :measure_tag]    = measure_tag.(df.inflfn)
df_19[!, :measure_tag] = measure_tag.(df_19.inflfn)

### Convertimos del tipo de Union{Missing, x} a x
for x in names(df)
    df[!,x] = identity.(df[:,x])
end

for x in names(df_19)
    df_19[!,x] = identity.(df_19[:,x])
end

################################################################################
########################### OPTIM COMBINATION MSE ##############################
################################################################################

##### DETERMINAMOS LA COMBINACION OPTIMA ######
combine_period = EvalPeriod(Date(2011, 12), Date(2021, 12), "combperiod") 
periods_filter = eval_periods(gtdata_eval, combine_period)
tray_infl = hcat(df.tray_infl...)
tray_infl_19 = hcat(df_19.tray_infl...)

# a_optim = share_combination_weights(
#     tray_infl[periods_filter, :, :],
#     tray_infl_pob[periods_filter],
#     show_status=true
# )

# b_optim = metric_combination_weights(
#     tray_infl[periods_filter, :, :],
#     tray_infl_pob[periods_filter],
#     metric = :absme
# )

# c_optim = metric_combination_weights(
#     tray_infl[periods_filter, :, :],
#     tray_infl_pob[periods_filter],
#     metric = :corr
# )

a_optim = [
    1.17575f-7,  2.72843f-7,  7.02187f-7,  1.97042f-6,  6.48972f-6,  2.26567f-5,  9.54898f-5,  0.000545962,  0.00238781,  0.0126863,  
    0.535334,  0.00643247,  0.00131864,  0.00048229,  0.000124413,  4.01479f-5,  1.47369f-5,  6.81922f-6,  3.66563f-6,  2.05641f-6,
    1.26168f-6,  8.35506f-7,  5.71292f-7,  4.21927f-7,  3.35266f-7,  2.86971f-7,  2.70815f-7,  2.83755f-7,  3.33815f-7,  4.43575f-7,
    6.68965f-7,  1.23847f-6,  2.82054f-6,  2.80619f-5,  0.0286687,  0.0618111,  0.0987122,  0.0853898,  0.0530525,  0.0553256,
    0.0323551,  0.0200345,  0.00198349,  0.00217465,  0.0009481
]

optmse2023NT = CombinationFunction(
    inflfn_mse...,
    a_optim, 
    "Subyacente óptima MSE 2023 No Transable",
    "OPTMSE23NT"
)

# optabsme2023NT = CombinationFunction(
#     inflfn_mse...,
#     b_optim, 
#     "Subyacente óptima ABSME 2023 No Transable",
#     "OPTABSME23NT"
# )

# optcorr2023NT = CombinationFunction(
#     inflfn_mse...,
#     c_optim, 
#     "Subyacente óptima CORR 2023 No Transable",
#     "OPTCORR23NT"
# )

################################################################################
########################### EVAL ###############################################
################################################################################


#### DEFINIMOS PERIODOS DE EVALUACION ######

period_b00 = EvalPeriod(Date(2001,12), Date(2010,12), "b00")
period_trn = EvalPeriod(Date(2011,01), Date(2011,11), "trn")
period_b10 = EvalPeriod(Date(2011,12), Date(2021,12), "b10")

b00_mask = eval_periods(gtdata_eval, period_b00)
trn_mask = eval_periods(gtdata_eval, period_trn)
b10_mask = eval_periods(gtdata_eval, period_b10)


##### AGREGAMOS LA SUBYACENTE OPTIMA AL DATAFRAME PARA QUE PUEDA SER EVALUADA ####

DF = outerjoin(df, components(optmse2023NT), on=:measure)
DF = hcat(DF,DataFrame(tray_infl_19 = df_19[:,:tray_infl]))

w_tray = df.tray_infl .* a_optim
w_tray_19 = df_19.tray_infl .* a_optim

tray_optim = sum(w_tray)
tray_optim_19 = sum(w_tray_19)

gt_b00_mse   = eval_metrics(tray_optim[b00_mask,:,:],tray_infl_pob[b00_mask])[:mse]
gt_b10_mse   = eval_metrics(tray_optim[b10_mask,:,:],tray_infl_pob[b10_mask])[:mse]
gt_t0010_mse = eval_metrics(tray_optim[trn_mask,:,:],tray_infl_pob[trn_mask])[:mse]
mse          = eval_metrics(tray_optim,tray_infl_pob)[:mse]

gt_b00_absme   = eval_metrics(tray_optim[b00_mask,:,:],tray_infl_pob[b00_mask])[:absme]
gt_b10_absme   = eval_metrics(tray_optim[b10_mask,:,:],tray_infl_pob[b10_mask])[:absme]
gt_t0010_absme = eval_metrics(tray_optim[trn_mask,:,:],tray_infl_pob[trn_mask])[:absme]
absme          = eval_metrics(tray_optim,tray_infl_pob)[:absme]  

gt_b00_corr   = eval_metrics(tray_optim[b00_mask,:,:],tray_infl_pob[b00_mask])[:corr]
gt_b10_corr   = eval_metrics(tray_optim[b10_mask,:,:],tray_infl_pob[b10_mask])[:corr]
gt_t0010_corr = eval_metrics(tray_optim[trn_mask,:,:],tray_infl_pob[trn_mask])[:corr]
corr          = eval_metrics(tray_optim,tray_infl_pob)[:corr]



temp = DataFrame(
    measure = optmse2023NT.name, 
    tray_infl = [tray_optim], 
    tray_infl_19  = [tray_optim_19],
    weights=1.0,

    gt_b00_mse = gt_b00_mse,
    gt_b10_mse = gt_b10_mse,
    gt_t0010_mse = gt_t0010_mse,
    mse = mse,

    gt_b00_absme = gt_b00_absme,
    gt_b10_absme = gt_b10_absme,
    gt_t0010_absme = gt_t0010_absme,
    absme = absme,

    gt_b00_corr = gt_b00_corr,
    gt_b10_corr = gt_b10_corr,
    gt_t0010_corr = gt_t0010_corr,
    corr = corr,
)

Df = vcat(DF,temp, cols=:union)



##### EVALUAMOS ############################

# PERIDO COMPLETO (2001-2021)
# df_mse[!,:complete_mse] = (x -> eval_metrics(x,tray_infl_pob)[:mse]).(df_mse.tray_infl)

# PERIDO BASE 2000
# df_mse[!,:b00_mse] = (x -> eval_metrics(x[b00_mask,:,:],tray_infl_pob[b00_mask])[:mse]).(df_mse.tray_infl)

# PERIDO DE TRANSICION
# df_mse[!,:trn_mse] = (x -> eval_metrics(x[trn_mask,:,:],tray_infl_pob[trn_mask])[:mse]).(df_mse.tray_infl)

# PERIDO BASE 2010
# df_mse[!,:b10_mse] = (x -> eval_metrics(x[b10_mask,:,:],tray_infl_pob[b10_mask])[:mse]).(df_mse.tray_infl)

# PERIODO 2001-2019
Df[!,:gt_b19_mse] = (x -> eval_metrics(x,tray_infl_pob_19)[:mse]).(Df.tray_infl_19)
Df[!,:gt_b19_absme] = (x -> eval_metrics(x,tray_infl_pob_19)[:absme]).(Df.tray_infl_19)
Df[!,:gt_b19_corr] = (x -> eval_metrics(x,tray_infl_pob_19)[:corr]).(Df.tray_infl_19)


# df_final = df_mse[:, [:measure,:weights,:b00_mse,:trn_mse,:b10_mse,:b19_mse,:complete_mse]]

# REMOVEMOS NANS
replace_nan(v) = map(x -> isnan(x) ? zero(x) : x, v)
Df[!,:gt_b00_corr] = Df[:,:gt_b00_corr] |> replace_nan
Df[!,:gt_b10_corr] = Df[:,:gt_b10_corr] |> replace_nan
Df[!,:gt_b19_corr] = Df[:,:gt_b19_corr] |> replace_nan
Df[!,:gt_t0010_corr] = Df[:,:gt_t0010_corr] |> replace_nan


############################ PLOTS ########################################

# Using Plots
bar(
    Df.measure_tag, 
    1 ./ Df.gt_b19_mse[1:end-1],
    xrotation = 90,
    size = (900,600),
    xlabel  = "Percentil equiponderado \n \n",
    ylabel = "\n 1 / MSE",
    title = "1/MSE, 2001-2019",#, MSE = "*string(Df.gt_b10_mse[end]),
    legend = false
)

bar(
    Df.measure_tag, 
    1 ./ Df.gt_b10_mse[1:end-1],
    xrotation = 90,
    size = (900,600),
    xlabel  = "Percentil equiponderado \n \n",
    ylabel = "\n 1 / MSE",
    title = "1/MSE, 2011-2021",#, MSE = "*string(Df.gt_b10_mse[end]),
    legend = false
)

bar(
    Df.measure_tag, 
    a_optim,
    xrotation = 90,
    size = (900,600),
    xlabel  = "Percentil equiponderado \n \n",
    ylabel = "\n W",
    title = "W optim, 2011-2021, MSE = "*string(Df.gt_b10_mse[end]),
    legend = false
)


#################################
######### PLOTS #################
#################################
# NO DESCOMENTAR

using Plots
using StatsBase

sorted_df = sort(Df, :weights, rev=true)

for i in [1,2,3,4,5]

    TITLE = sorted_df[i,:measure]
    PARAM = tray_infl_pob
    X = infl_dates(gtdata_eval)
    TRAYS = sorted_df[i,:tray_infl]
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
        ylims = (0,12)
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

    # p=plot!(
    #     X,TRAY_MED;
    #     legend = true,
    #     label="Mediana",
    #     c="green",
    #     linewidth = 2.0
    # )

    # p=plot!(
    #     X,TRAY_25;
    #     legend = true,
    #     label = "Percentil 25",
    #     c="green",
    #     linewidth = 2.0,
    #     linestyle=:dash
    # )

    # p=plot!(
    #     X,TRAY_75;
    #     legend = true,
    #     label = "Percentil 75",
    #     c="green",
    #     linewidth = 2.0,
    #     linestyle=:dash
    # )
    display(p)
    #savefig("C:\\Users\\DJGM\\Desktop\\PLOTS\\2023_no_trans\\plot_"*string(i)*".png")
end
