using DrWatson
@quickactivate "HEMI"

using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

# Incluimos Scripts auxiliares
include(scriptsdir("TOOLS","INFLFNS","rank.jl"))

gtdata_eval = GTDATA[Date(2022, 12)]

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


## Configuracion General
genconfig = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 3),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :traindate => Date(2022, 12),
    :nsim => 125_000,
    :evalperiods => (CompletePeriod(), GT_EVAL_B00, GT_EVAL_B10, GT_EVAL_T0010, GT_EVAL_B20, GT_EVAL_B08, GT_EVAL_B0820)
)

################################################################################
########################### TRAYECTORIAS MSE ###################################
################################################################################

loadpath = datadir("results","optim_comb_2024_B","mse")

optim_results = collect_results(loadpath)

optim_results.infltypefn = typeof.(optim_results.inflfn)

#ordenamos por medida de inflacion 
optim_results.rank = rank.(optim_results.inflfn)
sort!(optim_results, :rank)

# creamos array ordenado de medidas
inflfns = optim_results.inflfn

# creamos configuración final
config =  merge(genconfig, Dict(:inflfn => inflfns)) |> dict_list

# creamos savepath
savepath = datadir("results","optim_comb_2024_B", "tray_infl", "mse")

# generamos trayectorias
run_batch(gtdata_eval, config, savepath; savetrajectories = true)

################################################################################
########################### TRAYECTORIAS ABSME ###################################
################################################################################

loadpath = datadir("results","optim_comb_2024_B","absme")

optim_results = collect_results(loadpath)

optim_results.infltypefn = typeof.(optim_results.inflfn)

#ordenamos por medida de inflacion 
optim_results.rank = rank.(optim_results.inflfn)
sort!(optim_results, :rank)

# creamos array ordenado de medidas
inflfns = optim_results.inflfn

# creamos configuración final
config =  merge(genconfig, Dict(:inflfn => inflfns)) |> dict_list

# creamos savepath
savepath = datadir("results","optim_comb_2024_B", "tray_infl", "absme")

# generamos trayectorias
run_batch(gtdata_eval, config, savepath; savetrajectories = true)

################################################################################
########################### TRAYECTORIAS CORR ###################################
################################################################################

loadpath = datadir("results","optim_comb_2024_B","corr")

optim_results = collect_results(loadpath)

optim_results.infltypefn = typeof.(optim_results.inflfn)

#ordenamos por medida de inflacion 
optim_results.rank = rank.(optim_results.inflfn)
sort!(optim_results, :rank)

# creamos array ordenado de medidas
inflfns = optim_results.inflfn

# creamos configuración final
config =  merge(genconfig, Dict(:inflfn => inflfns)) |> dict_list

# creamos savepath
savepath = datadir("results","optim_comb_2024_B", "tray_infl", "corr")

# generamos trayectorias
run_batch(gtdata_eval, config, savepath; savetrajectories = true)