using DrWatson
@quickactivate "HEMI"

using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

genconfig = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 3),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :traindate => Date(2021, 12),
    :nsim => 125_000,
    :evalperiods => (CompletePeriod(), GT_EVAL_B00, GT_EVAL_B10, GT_EVAL_T0010)
)

data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")

gtdata_eval = NOT_GTDATA[Date(2021, 12)]

################################################################################
########################### TRAYECTORIAS MSE ###################################
################################################################################


############################# BASE 2000 ########################################

savepath = datadir("results", "no_trans", "tray_infl", "mse", "B00")

optim_loadpath = datadir("results","no_trans","optim", "mse", "B00")

optim_results = collect_results(optim_loadpath)

config =  merge(genconfig, Dict(:inflfn => optim_results.inflfn)) |> dict_list

run_batch(gtdata_eval, config, savepath; savetrajectories = true)

############################# BASE 2010 ########################################

savepath = datadir("results", "no_trans", "tray_infl", "mse", "B10")

optim_loadpath = datadir("results","no_trans","optim", "mse", "B10")

optim_results = collect_results(optim_loadpath)

config =  merge(genconfig, Dict(:inflfn => optim_results.inflfn)) |> dict_list

run_batch(gtdata_eval, config, savepath; savetrajectories = true)

################################################################################
########################## TRAYECTORIAS ABSME ##################################
################################################################################

############################# BASE 2000 ########################################

savepath = datadir("results", "no_trans", "tray_infl", "absme", "B00")

optim_loadpath = datadir("results","no_trans","optim", "absme", "B00")

optim_results = collect_results(optim_loadpath)

config =  merge(genconfig, Dict(:inflfn => optim_results.inflfn)) |> dict_list

run_batch(gtdata_eval, config, savepath; savetrajectories = true)

############################# BASE 2010 ########################################

savepath = datadir("results", "no_trans", "tray_infl", "absme", "B10")

optim_loadpath = datadir("results","no_trans","optim", "absme", "B10")

optim_results = collect_results(optim_loadpath)

config =  merge(genconfig, Dict(:inflfn => optim_results.inflfn)) |> dict_list

run_batch(gtdata_eval, config, savepath; savetrajectories = true)


################################################################################
########################## TRAYECTORIAS CORR ###################################
################################################################################

savepath = datadir("results", "no_trans", "tray_infl", "corr", "B00")

optim_loadpath = datadir("results","no_trans","optim", "corr", "B00")

optim_results = collect_results(optim_loadpath)

config =  merge(genconfig, Dict(:inflfn => optim_results.inflfn)) |> dict_list

run_batch(gtdata_eval, config, savepath; savetrajectories = true)

############################# BASE 2010 ########################################

savepath = datadir("results", "no_trans", "tray_infl", "corr", "B10")

optim_loadpath = datadir("results","no_trans","optim", "corr", "B10")

optim_results = collect_results(optim_loadpath)

config =  merge(genconfig, Dict(:inflfn => optim_results.inflfn)) |> dict_list

run_batch(gtdata_eval, config, savepath; savetrajectories = true)



#=
####################################################################
####################################################################
####################################################################
####################################################################
####################################################################
####################################################################
### test ###########################################################
testconfig = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 3),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :traindate => Date(2021, 12),
    :nsim => 10_000,
    :evalperiods => (CompletePeriod(), GT_EVAL_B00, GT_EVAL_B10, GT_EVAL_T0010)
)

savepath = datadir("results", "no_trans", "tray_infl", "mse", "splice")

optim_loadpath_B00 = datadir("results","no_trans","optim", "mse", "B00")
optim_results_B00 = collect_results(optim_loadpath_B00)

optim_loadpath_B10 = datadir("results","no_trans","optim", "mse", "B10")
optim_results_B10 = collect_results(optim_loadpath_B10)

splice_fns = [Splice([optim_results_B00.inflfn[i],optim_results_B10.inflfn[i]],[(Date(2011,01), Date(2011,11))], "Splice"*string(i), "S"*string(i)) for i in 1:6]

config =  merge(testconfig, Dict(:inflfn => splice_fns)) |> dict_list

run_batch(gtdata_eval, config, savepath; savetrajectories = true)

df = collect_results(savepath)

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
    elseif inflfn isa Splice
        rank(inflfn.f[1])
    end
end

df.rank = rank.(df.inflfn)
sort!(df,:rank)
df.tray_path = map(x->joinpath(dirname(x),"tray_infl",basename(x)),df.path)

tray_infl = mapreduce(hcat, df.tray_path) do path
    load(path, "tray_infl")
end

functions = df.inflfn
components_mask = [!(fn.f[1] isa InflationFixedExclusionCPI) for fn in functions]

combine_period_00 =  GT_EVAL_B00 #EvalPeriod(Date(2001, 12), Date(2010, 12), "combperiod_B00") 
combine_period_10 =  GT_EVAL_B10 #EvalPeriod(Date(2011, 12), Date(2021, 12), "combperiod_B10") 

periods_filter_00 = eval_periods(gtdata_eval, combine_period_00)
periods_filter_10 = eval_periods(gtdata_eval, combine_period_10)

# CALCULAMOS LOS PESOS OPTIMOS
a_optim_00 = share_combination_weights(
    tray_infl[periods_filter_00, components_mask, :],
    tray_infl_pob[periods_filter_00],
    show_status=true
)

a_optim_10 = share_combination_weights(
    tray_infl[periods_filter_10, components_mask, :],
    tray_infl_pob[periods_filter_10],
    show_status=true
)

insert!(a_optim_00, findall(.!components_mask)[1],0)
insert!(a_optim_10, findall(.!components_mask)[1],0)

optmseb00 = CombinationFunction(
    optim_results_B00.inflfn...,
    a_optim_00, 
    "Subyacente óptima MSE no transable base 2000"
)

optmseb10 = CombinationFunction(
    optim_results_B10.inflfn...,
    a_optim_10, 
    "Subyacente óptima MSE no transable base 2000"
)

optmse2023_nt = Splice([optmseb00, optmseb10], [(Date(2011,01), Date(2011,11))], "Subyacente Óptima MSE 2023 No Transable", "SubOptMse2023NT")

config =  dict_config(merge(testconfig, Dict(:inflfn => optmse2023_nt)))

results , tray = makesim(gtdata_eval, config)

tray_infl = hcat(tray_infl, tray)



eval_results = [eval_metrics(tray_infl[:,i:i,:], tray_infl_pob)[:mse] for i in 1:size(tray_infl)[2]]
eval_results_00 = [eval_metrics(tray_infl[periods_filter_00,i:i,:], tray_infl_pob[periods_filter_00])[:mse] for i in 1:size(tray_infl)[2]]
eval_results_10 = [eval_metrics(tray_infl[periods_filter_10,i:i,:], tray_infl_pob[periods_filter_10])[:mse] for i in 1:size(tray_infl)[2]]

########################################
########################################
=#