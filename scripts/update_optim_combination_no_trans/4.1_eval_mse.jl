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
loadpath = datadir("results", "no_trans","tray_infl","mse")
tray_dir = joinpath(loadpath, "tray_infl")
combination_loadpath  = datadir("results","no_trans","optim_combination","mse")

save_results = datadir("results","no_trans","eval","mse")


#CREAMOS UNA FUNCION PARA ORDENAR LAS FUNCIONES
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
        rank(inflfn.f[1]) # retorna la primera funcion 
    end
end

# CARGAMOS Y ORDENAMOS DATAFRAMES SEGUN LA MEDIDA DE INFLACION
optim   = collect_results(combination_loadpath)


df_results_B00 = collect_results(joinpath(loadpath,"B00"))
df_results_B10 = collect_results(joinpath(loadpath,"B10"))

df_results_B00.rank = rank.(df_results_B00.inflfn)
df_results_B10.rank = rank.(df_results_B00.inflfn)

sort!(df_results_B00, :rank)
sort!(df_results_B10, :rank)


# PATHS DE TRAYECTORIAS
df_results_B00.tray_path = map(x->joinpath(loadpath,"B00","tray_infl",basename(x)),df_results_B00.path)
df_results_B10.tray_path = map(x->joinpath(loadpath,"B10","tray_infl",basename(x)),df_results_B10.path)


######## CARGAMOS LOS PESOS #####################################

w_B00 = round.(optim[1,:].optmse2023_nt.f[1].weights,digits=4)
w_B10 = round.(optim[1,:].optmse2023_nt.f[2].weights, digits=4)

######## EMPALMAMOS y CREAMOS TRAYECTORIAS OPTIMAS

inf_dates = infl_dates(gtdata_eval)

tray_infl = let

    ramp_down = Float32.(CPIDataBase.ramp_down(inf_dates, optim[1,:].optmse2023_nt.dates[1]...))
    ramp_up   = Float32.(CPIDataBase.ramp_up(inf_dates, optim[1,:].optmse2023_nt.dates[1]...))
    
    tray_infl_B00 = mapreduce(hcat, df_results_B00.tray_path) do path
        load(path, "tray_infl")
    end

    tray_infl_B10 = mapreduce(hcat, df_results_B10.tray_path) do path
        load(path, "tray_infl")
    end

    tray_infl_B00 = round.(tray_infl_B00[:,:,1:125_000], digits=4)
    tray_infl_B10 = round.(tray_infl_B10[:,:,1:125_000], digits=4)

    w_tray_B00  = round.(tray_infl_B00 .* w_B00',digits=4) # Se redondea para ahorrar memoria
    w_tray_B10  = round.(tray_infl_B10 .* w_B10', digits=4) # Se redondea para ahorrar memoria
    tray_opt  = round.(sum(ramp_down .* w_tray_B00 .+ ramp_up .* w_tray_B10, dims=2), digits=4) # trayectorias de la optima 
    tray_infl = hcat(ramp_down .* tray_infl_B00 .+ ramp_up .* tray_infl_B10, tray_opt) # concatenamos con el resto de trayectorias
    tray_infl
end

#wsave(joinpath(save_results,"tray_infl","tray_infl.jld2"), "tray_infl",tray_infl)


############# DEFINIMOS PARAMETROS ######################################################

# PARAMETRO HASTA 2021
param = InflationParameter(
    InflationTotalRebaseCPI(36, 2), 
    ResampleScrambleVarMonths(), 
    TrendRandomWalk()
)

# TRAYECOTRIAS DE LOS PARAMETROS 
tray_infl_pob      = param(gtdata_eval)


############ DEFINIMOS PERIODOS DE EVALUACION ############################################

period_b00 = EvalPeriod(Date(2001,12), Date(2010,12), "b00")
period_trn = EvalPeriod(Date(2011,01), Date(2011,11), "trn")
period_b10 = EvalPeriod(Date(2011,12), Date(2021,12), "b10")

b00_mask = eval_periods(gtdata_eval, period_b00)
trn_mask = eval_periods(gtdata_eval, period_trn)
b10_mask = eval_periods(gtdata_eval, period_b10)


##### EVALUAMOS ############################

eval_results = [eval_metrics(tray_infl[:,i:i,:], tray_infl_pob)[:mse] for i in 1:size(tray_infl)[2]]
eval_results_00 = [eval_metrics(tray_infl[b00_mask,i:i,:], tray_infl_pob[b00_mask])[:mse] for i in 1:size(tray_infl)[2]]
eval_results_10 = [eval_metrics(tray_infl[b10_mask,i:i,:], tray_infl_pob[b10_mask])[:mse] for i in 1:size(tray_infl)[2]]
eval_results_tr = [eval_metrics(tray_infl[trn_mask,i:i,:], tray_infl_pob[trn_mask])[:mse] for i in 1:size(tray_infl)[2]]



######## PULIMOS LOS RESULTADOS ##########################

df_eval  = DataFrame(
    measure = [
        "Percentil Equiponderado", "Percentil Ponderado",
        "Media Truncada Equiponderada", "Media Truncada Ponderada",
        "Exclusión Dinámica", "Exclusión Fija",
        "Subyacente Óptima MSE 2023 No Transable"
    ],
    weights_b00 = vcat(w_B00,1),
    weights_b10 = vcat(w_B10,1),
    b00_mse = eval_results_00,
    trn_mse = eval_results_tr,
    b10_mse = eval_results_10,
    complete_mse = eval_results
) 


# using PrettyTables
# pretty_table(df_eval)
# ┌─────────────────────────────────────────┬─────────────┬─────────────┬──────────┬──────────┬───────────┬──────────────┐
# │                                 measure │ weights_b00 │ weights_b10 │  b00_mse │  trn_mse │   b10_mse │ complete_mse │
# │                                  String │     Float32 │     Float32 │  Float32 │  Float32 │   Float32 │      Float32 │
# ├─────────────────────────────────────────┼─────────────┼─────────────┼──────────┼──────────┼───────────┼──────────────┤
# │                 Percentil Equipenderado │      0.0003 │         0.0 │ 0.895248 │ 0.667364 │ 0.0643411 │      0.46767 │
# │                     Percentil Ponderado │      0.1599 │      0.0315 │  0.88679 │  0.48521 │  0.135907 │     0.491461 │
# │            Media Truncada Equiponderada │      0.5645 │      0.7921 │ 0.505915 │ 0.581494 │ 0.0415262 │     0.276207 │
# │                Media Truncada Ponderada │      0.2011 │      0.1764 │ 0.543522 │  0.33603 │ 0.0757423 │     0.299191 │
# │                      Exclusión Dinámica │      0.0742 │         0.0 │ 0.581342 │ 0.478002 │  0.119716 │     0.344855 │
# │                          Exclusión Fija │         0.0 │         0.0 │ 0.717496 │  0.73741 │  0.356273 │     0.537044 │
# │ Subyacente Óptima MSE 2023 No Transable │         1.0 │         1.0 │ 0.423319 │ 0.382786 │ 0.0391523 │     0.228589 │
# └─────────────────────────────────────────┴─────────────┴─────────────┴──────────┴──────────┴───────────┴──────────────┘


# guardamos el resultado
using  CSV
mkpath(save_results)
CSV.write(joinpath(save_results,"eval.csv"), df_eval)


#################################
######### PLOTS #################
#################################
# NO DESCOMENTAR

using Plots
using StatsBase

include(scriptsdir("TOOLS","PLOT","cloud_plot.jl"))

measure = [
    "Percentil Equiponderado", "Percentil Ponderado",
    "Media Truncada Equiponderada", "Media Truncada Ponderada",
    "Exclusión Dinámica", "Exclusión Fija",
    "Subyacente Óptima MSE 2023 No Transable"
]

savename = [
    "C:\\Users\\DJGM\\Desktop\\PLOTS\\2023_no_trans\\MSE\\PercEq.png",
    "C:\\Users\\DJGM\\Desktop\\PLOTS\\2023_no_trans\\MSE\\PercW.png",
    "C:\\Users\\DJGM\\Desktop\\PLOTS\\2023_no_trans\\MSE\\TMEQ.png",
    "C:\\Users\\DJGM\\Desktop\\PLOTS\\2023_no_trans\\MSE\\TMW.png",
    "C:\\Users\\DJGM\\Desktop\\PLOTS\\2023_no_trans\\MSE\\DE.png",
    "C:\\Users\\DJGM\\Desktop\\PLOTS\\2023_no_trans\\MSE\\FE.png",
    "C:\\Users\\DJGM\\Desktop\\PLOTS\\2023_no_trans\\MSE\\OPT.png",
]

cloud_plot(tray_infl, tray_infl_pob, gtdata_eval; title=measure, savename=savename)