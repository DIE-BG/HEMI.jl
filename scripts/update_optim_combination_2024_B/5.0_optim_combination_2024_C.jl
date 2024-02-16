################################################################
# INICIO 
################################################################

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


################################################################
# GRID EXPLORATORIA 
################################################################

savepath = datadir("results","optim_comb_2024_B")
savepath_grid = joinpath(savepath,"grid")

grid_DF = collect_results(savepath_grid)

# agregamos tipo de funcion
grid_DF[!,:infltypefn] = typeof.(grid_DF[:,:inflfn])

# Le creamos una columna donde se encuentren los parametros de cada medida
grid_DF.k = map(
    x -> x isa Union{InflationPercentileEq, InflationPercentileWeighted} ? x.k :
    x isa Union{InflationTrimmedMeanEq, InflationTrimmedMeanWeighted} ? (x.l1,x.l2) :
    x isa InflationDynamicExclusion ? (x.lower_factor,x.upper_factor) : NaN,
    grid_DF.inflfn
)

# Filtramos los NaNs en donde hay cantidades numericas
filter!(row -> all(x -> !(x isa Number && isnan(x)), row), grid_DF)

## TOMAMOS SOLO MEDIAS TRUNCADAS

TMEQ = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanEq,:],order(:gt_b0820_mse))
TMW = sort(grid_DF[grid_DF.infltypefn .== InflationTrimmedMeanWeighted,:],order(:gt_b0820_mse))


## creamos un savepath
savepath_mse = joinpath(dirname(savepath), "optim_comb_2024_C","mse")
mkpath(savepath_mse)

## GUARDAMOS LOS RESULTADOS QUE BUSCAMOS

cp(TMEQ.path[11], joinpath(savepath_mse, basename(TMEQ.path[11])), force=true) #Utilizamos el 11 en lugar del primero por tener un intervalo mucho mas ancho
cp(TMW.path[1], joinpath(savepath_mse, basename(TMW.path[1])), force=true)

################################################################
# GENERAMOS TRAYECTORIAS 
################################################################

loadpath = savepath_mse
optim_results = collect_results(loadpath)


## PERIODOS DE evaluacion
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


inflfns = optim_results.inflfn
# creamos configuración final
config =  merge(genconfig, Dict(:inflfn => inflfns)) |> dict_list

savepath = datadir("results","optim_comb_2024_C", "tray_infl", "mse")
mkpath(savepath)

run_batch(gtdata_eval, config, savepath; savetrajectories = true)


################################################################
# COMBINACION OPTIMA
################################################################

loadpath = datadir("results","optim_comb_2024_C","tray_infl","mse")

combination_savepath  = datadir("results","optim_comb_2024_C","optim_combination","mse")
mkpath(combination_savepath)

df_results = collect_results(loadpath)

#Ordenamos por medida de Inflacion
df_results.rank = rank.(df_results.inflfn)
sort!(df_results, :rank)

# PATHS DE TRAYECTORIAS
df_results.tray_path = map(
    x->joinpath(
        loadpath,
        "tray_infl",
        basename(x)
    ),
    df_results.path
)

# TRAYECTORIAS
tray_infl = mapreduce(hcat, df_results.tray_path) do path
    load(path, "tray_infl")
end

# DEFINIMOS "EL" PARAMETRO
resamplefn = df_results.resamplefn[1]
trendfn = df_results.trendfn[1]
paramfn = df_results.paramfn[1] #InflationTotalRebaseCPI(36, 3)
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)


functions = df_results.inflfn

# DEFINIMOS PERIODOS DE COMBINACION
combine_period =  CompletePeriod() 
periods_filter = eval_periods(gtdata_eval, CompletePeriod())

a_optim = share_combination_weights(
    tray_infl[periods_filter, :, :],
    tray_infl_pob[periods_filter],
    show_status=true
)

a_optim = [0.86401  0.13599][:]
# InflationTrimmedMeanEq(46.0f0, 89.0f0)
# InflationTrimmedMeanWeighted(23.0f0, 95.0f0)

# tray_w = sum(a_optim' .*  tray_infl[periods_filter,:, :],dims=2)
# metrics = eval_metrics(tray_w, tray_infl_pob[periods_filter])
# metrics[:mse] # 0.1261292712529388

