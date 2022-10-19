using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain


loadpath = datadir("results", "no_trans","tray_infl","absme")
tray_dir = joinpath(loadpath, "tray_infl")

combination_savepath  = datadir("results","no_trans","optim_combination","absme")

data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")

gtdata_eval = NOT_GTDATA[Date(2021, 12)]

df_results = collect_results(loadpath)

@chain df_results begin 
    select(:measure, :absme)
end

# DataFrame de combinación 
combine_df = @chain df_results begin 
    select(:measure, :absme, :inflfn, 
        :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path
    )
    sort(:absme)
end

tray_infl = mapreduce(hcat, combine_df.tray_path) do path
    load(path, "tray_infl")
end

resamplefn = df_results[1, :resamplefn]
trendfn = df_results[1, :trendfn]
paramfn = InflationTotalRebaseCPI(36, 3) #df_results[1, :paramfn]
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)

functions = combine_df.inflfn
components_mask = [!(fn isa InflationFixedExclusionCPI) for fn in functions]

combine_period = EvalPeriod(Date(2011, 12), Date(2021, 12), "combperiod") 
periods_filter = eval_periods(gtdata_eval, combine_period)

a_optim = metric_combination_weights(
    tray_infl[periods_filter, components_mask, :],
    tray_infl_pob[periods_filter],
    metric = :absme,
    # Le asignamos pesos iniciales de una solucion de esquina
    w_start = float.([(fn isa InflationDynamicExclusion) for fn in functions][components_mask]) 
)

#Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
insert!(a_optim, findall(.!components_mask)[1],0)

optabsme2023 = CombinationFunction(
    functions...,
    a_optim, 
    "Subyacente óptima ABSME 2023 no transable"
)

wsave(joinpath(combination_savepath,"optabsme2023.jld2"), "optabsme2023", optabsme2023)

# using PrettyTables
# pretty_table(components(optabsme2023))
# ┌──────────────────────────────────────────────┬────────────┐
# │                                      measure │    weights │
# │                                       String │    Float64 │
# ├──────────────────────────────────────────────┼────────────┤
# │  Exclusión fija de gastos básicos IPC (4, 2) │        0.0 │
# │                Percentil equiponderado 72.95 │  1.0506e-5 │
# │      Media Truncada Ponderada (20.11, 98.16) │ 2.21687e-5 │
# │ Inflación de exclusión dinámica (0.72, 4.13) │    1.00007 │
# │  Media Truncada Equiponderada (26.11, 95.61) │ 1.20295e-7 │
# │                    Percentil ponderado 69.88 │ 3.22738e-8 │
# └──────────────────────────────────────────────┴────────────┘

######################################################################################
################## INTERVALO DE CONFIANZA ############################################
######################################################################################

a = reshape(a_optim,(1,length(a_optim),1))
b = reshape(tray_infl_pob,(length(tray_infl_pob),1,1))
w_tray = sum(a.*tray_infl,dims=2)
error_tray = dropdims(w_tray .- b,dims=2)

period_b00 = EvalPeriod(Date(2001,12), Date(2010,12), "b00")
period_trn = EvalPeriod(Date(2011,01), Date(2011,11), "trn")
period_b10 = EvalPeriod(Date(2011,12), Date(2021,12), "b10")

b00_mask = eval_periods(gtdata_eval, period_b00)
trn_mask = eval_periods(gtdata_eval, period_trn)
b10_mask = eval_periods(gtdata_eval, period_b10)

tray_b00 = error_tray[b00_mask, :]
tray_trn = error_tray[trn_mask, :]
tray_b10 = error_tray[b10_mask, :]

quant_0125 = quantile.(vec.([tray_b00,tray_trn,tray_b10]),0.0125)  
quant_9875 = quantile.(vec.([tray_b00,tray_trn,tray_b10]),0.9875) 

bounds =transpose(hcat(-quant_0125,-quant_9875))

# pretty_table(hcat(["upper","lower"],bounds),["","b00","T","b10"])
# ┌───────┬──────────┬──────────┬───────────┐
# │       │      b00 │        T │       b10 │
# ├───────┼──────────┼──────────┼───────────┤
# │ upper │  1.53964 │  1.28104 │  0.876843 │
# │ lower │ -2.23624 │ -1.34043 │ -0.439636 │
# └───────┴──────────┴──────────┴───────────┘