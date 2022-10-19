using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain


savepath = datadir("results", "tray_infl", "absme")
tray_dir = joinpath(savepath, "tray_infl")

combination_savepath  = datadir("results","optim_combination","absme_noMAI_recalc")

gtdata_eval = GTDATA[Date(2021, 12)]

df_results = collect_results(savepath)

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
components_mask = [!(fn isa InflationFixedExclusionCPI || fn isa InflationCoreMai ) for fn in functions]

combine_period = EvalPeriod(Date(2011, 12), Date(2021, 12), "combperiod") 
periods_filter = eval_periods(gtdata_eval, combine_period)

a_optim = metric_combination_weights(
    tray_infl[periods_filter, components_mask, :],
    tray_infl_pob[periods_filter],
    metric = :absme
)

#Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
for x in findall(.!components_mask)
    insert!(a_optim,x,0)
end

#Construccion de la MAI optima
mai_components = [fn isa InflationCoreMai for fn in functions]
mai_weights = [0, 0, 0] #reemplazamos por ceros
mai_fns = functions[mai_components]

optmai_absme2023 = CombinationFunction(
    mai_fns..., 
    mai_weights, 
    "MAI óptima ABSME 2023"
)

non_mai_weights = a_optim[.!mai_components]
non_mai_fns = functions[.!mai_components]

final_weights = vcat(non_mai_weights, sum(a_optim[mai_components])) 
final_fns     = vcat(non_mai_fns, optmai_absme2023)

optabsme2023 = CombinationFunction(
    final_fns...,
    final_weights, 
    "Subyacente óptima ABSME 2023"
)

wsave(joinpath(combination_savepath,"optabsme2023.jld2"), "optabsme2023", optabsme2023 , "optmai_absme2023", optmai_absme2023)

# using PrettyTables
# pretty_table(components(optabsme2023))
# ┌──────────────────────────────────────────────┬──────────┐
# │                                      measure │  weights │
# │                                       String │  Float32 │
# ├──────────────────────────────────────────────┼──────────┤
# │  Media Truncada Equiponderada (33.41, 93.73) │ 0.162018 │
# │  Exclusión fija de gastos básicos IPC (9, 6) │      0.0 │
# │ Inflación de exclusión dinámica (1.05, 3.49) │ 0.191829 │
# │      Media Truncada Ponderada (32.16, 93.26) │ 0.200148 │
# │                    Percentil ponderado 70.23 │ 0.215302 │
# │                Percentil equiponderado 71.92 │ 0.230753 │
# │                        MAI óptima ABSME 2023 │      0.0 │
# └──────────────────────────────────────────────┴──────────┘

# pretty_table(components(optmai_absme2023))
# ┌──────────────────────────────────────────┬─────────┐
# │                                  measure │ weights │
# │                                   String │   Int64 │
# ├──────────────────────────────────────────┼─────────┤
# │      MAI (FP,5,[0.38, 0.43, 0.57, 0.85]) │       0 │
# │ MAI (G,6,[0.15, 0.32, 0.53, 0.62, 0.78]) │       0 │
# │              MAI (F,4,[0.17, 0.4, 0.85]) │       0 │
# └──────────────────────────────────────────┴─────────┘

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
# ┌───────┬──────────┬───────────┬───────────┐
# │       │      b00 │         T │       b10 │
# ├───────┼──────────┼───────────┼───────────┤
# │ upper │  1.09648 │  0.723012 │  0.501536 │
# │ lower │ -1.01401 │ -0.679432 │ -0.517613 │
# └───────┴──────────┴───────────┴───────────┘