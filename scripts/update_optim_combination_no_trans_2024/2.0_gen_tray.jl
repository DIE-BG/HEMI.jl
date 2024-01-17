using DrWatson
@quickactivate "HEMI"

using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

# Incluimos Scripts auxiliares
include(scriptsdir("TOOLS","INFLFNS","rank.jl"))



# CARGANDO DATOS
data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")
gtdata_eval = NOT_GTDATA[Date(2022, 12)]

# Creamos periodo de evaluacion para medidas hasta Dic 2020.
GT_EVAL_B2020 = EvalPeriod(Date(2011, 12), Date(2020, 12), "gt_b2020")


## Configuracion General
genconfig = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 3),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :traindate => Date(2022, 12),
    :nsim => 125_000,
    :evalperiods => (CompletePeriod(), GT_EVAL_B00, GT_EVAL_B10, GT_EVAL_T0010, GT_EVAL_B2020)
)

################################################################################
########################### TRAYECTORIAS MSE ###################################
################################################################################

loadpath_b00 = datadir("results","optim_comb_no_trans_2024","B00", "mse")
loadpath_b10 = datadir("results","optim_comb_no_trans_2024","B10", "mse")

optim_results_b00 = collect_results(loadpath_b00)
optim_results_b10 = collect_results(loadpath_b10)

optim_results_b00.infltypefn = typeof.(optim_results_b00.inflfn)
optim_results_b10.infltypefn = typeof.(optim_results_b10.inflfn)

inflfn_df = outerjoin(
    optim_results_b00,
    optim_results_b10, 
    on = :infltypefn, 
    makeunique=true
)

#ordenamos por medida de inflacion 
inflfn_df.rank = rank.(inflfn_df.inflfn)
sort!(inflfn_df, :rank)


inflfns = Array{Any}(undef, size(inflfn_df)[1])
for i in 1:size(inflfn_df)[1]
    inflfns[i] = Splice(
        inflfn_df.inflfn[i],
        inflfn_df.inflfn_1[i];
        name = inflfn_name(typeof(inflfn_df.inflfn[i])),
        tag = inflfn_tag(typeof(inflfn_df.inflfn[i]))
    )
end

config =  merge(genconfig, Dict(:inflfn => inflfns)) |> dict_list

savepath = datadir("results","optim_comb_no_trans_2024", "tray_infl", "mse")

run_batch(gtdata_eval, config, savepath; savetrajectories = true)

################################################################################
########################### TRAYECTORIAS ABSME ###################################
################################################################################

loadpath_b00 = datadir("results","optim_comb_no_trans_2024","B00", "absme")
loadpath_b10 = datadir("results","optim_comb_no_trans_2024","B10", "absme")

optim_results_b00 = collect_results(loadpath_b00)
optim_results_b10 = collect_results(loadpath_b10)

optim_results_b00.infltypefn = typeof.(optim_results_b00.inflfn)
optim_results_b10.infltypefn = typeof.(optim_results_b10.inflfn)

inflfn_df = outerjoin(optim_results_b00,optim_results_b10, on = :infltypefn, makeunique=true)[:,[:inflfn, :inflfn_1]]

#ordenamos por medida de inflacion 
inflfn_df.rank = rank.(inflfn_df.inflfn)
sort!(inflfn_df, :rank)


inflfns = Array{Any}(undef, size(inflfn_df)[1])
for i in 1:size(inflfn_df)[1]
    inflfns[i] = Splice(
        inflfn_df.inflfn[i],
        inflfn_df.inflfn_1[i];
        name = inflfn_name(typeof(inflfn_df.inflfn[i])),
        tag = inflfn_tag(typeof(inflfn_df.inflfn[i]))
    )
end

config =  merge(genconfig, Dict(:inflfn => inflfns)) |> dict_list

savepath = datadir("results","optim_comb_no_trans_2024", "tray_infl", "absme")

run_batch(gtdata_eval, config, savepath; savetrajectories = true)

################################################################################
########################### TRAYECTORIAS CORR ###################################
################################################################################

loadpath_b00 = datadir("results","optim_comb_no_trans_2024","B00", "corr")
loadpath_b10 = datadir("results","optim_comb_no_trans_2024","B10", "corr")

optim_results_b00 = collect_results(loadpath_b00)
optim_results_b10 = collect_results(loadpath_b10)

optim_results_b00.infltypefn = typeof.(optim_results_b00.inflfn)
optim_results_b10.infltypefn = typeof.(optim_results_b10.inflfn)

inflfn_df = outerjoin(optim_results_b00,optim_results_b10, on = :infltypefn, makeunique=true)[:,[:inflfn, :inflfn_1]]

#ordenamos por medida de inflacion 
inflfn_df.rank = rank.(inflfn_df.inflfn)
sort!(inflfn_df, :rank)

inflfns = Array{Any}(undef, size(inflfn_df)[1])
for i in 1:size(inflfn_df)[1]
    inflfns[i] = Splice(
        inflfn_df.inflfn[i],
        inflfn_df.inflfn_1[i];
        name = inflfn_name(typeof(inflfn_df.inflfn[i])),
        tag = inflfn_tag(typeof(inflfn_df.inflfn[i]))
    )
end

config =  merge(genconfig, Dict(:inflfn => inflfns)) |> dict_list

savepath = datadir("results","optim_comb_no_trans_2024", "tray_infl", "corr")

run_batch(gtdata_eval, config, savepath; savetrajectories = true)