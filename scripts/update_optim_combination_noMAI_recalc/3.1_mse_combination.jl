using DrWatson
@quickactivate "HEMI" 

using HEMI 

## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 

## Otras librerías
using DataFrames, Chain


savepath = datadir("results", "tray_infl", "mse")
tray_dir = joinpath(savepath, "tray_infl")

combination_savepath  = datadir("results","optim_combination","mse_noMAI_recalc")

gtdata_eval = GTDATA[Date(2021, 12)]

df_results = collect_results(savepath)

@chain df_results begin 
    select(:measure, :mse)
end

# DataFrame de combinación 
combine_df = @chain df_results begin 
    select(:measure, :mse, :inflfn, 
        :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path
    )
    sort(:mse)
end

tray_infl = mapreduce(hcat, combine_df.tray_path) do path
    load(path, "tray_infl")
end

resamplefn = df_results[1, :resamplefn]
trendfn = df_results[1, :trendfn]
paramfn = InflationTotalRebaseCPI(36, 3) #df_results[1, :paramfn]
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)
|
functions = combine_df.inflfn
components_mask = [!(fn isa InflationFixedExclusionCPI || fn isa InflationCoreMai ) for fn in functions]

combine_period = EvalPeriod(Date(2011, 12), Date(2021, 12), "combperiod") 
periods_filter = eval_periods(gtdata_eval, combine_period)

a_optim = share_combination_weights(
    tray_infl[periods_filter, components_mask, :],
    tray_infl_pob[periods_filter],
    show_status=true
)

#Insertamos el 0 en el vector de pesos en el lugar correspondiente a exclusion fija
for x in findall(.!components_mask)
    insert!(a_optim,x,0)
end

#Construccion de la MAI optima
mai_components = [fn isa InflationCoreMai for fn in functions]
mai_weights = [0, 0, 0] #reemplazamos por ceros
mai_fns = functions[mai_components]

optmai_mse2023 = CombinationFunction(
    mai_fns..., 
    mai_weights, 
    "MAI óptima MSE 2023"
)

non_mai_weights = a_optim[.!mai_components]
non_mai_fns = functions[.!mai_components]

final_weights = vcat(non_mai_weights, sum(a_optim[mai_components])) 
final_fns     = vcat(non_mai_fns, optmai_mse2023)

optmse2023 = CombinationFunction(
    final_fns...,
    final_weights, 
    "Subyacente óptima MSE 2023"
)

wsave(joinpath(combination_savepath,"optmse2023.jld2"), "optmse2023", optmse2023 , "optmai_mse2023", optmai_mse2023)

# using PrettyTables
# pretty_table(components(optmse2023))
# ┌───────────────────────────────────────────────┬────────────┐
# │                                       measure │    weights │
# │                                        String │    Float32 │
# ├───────────────────────────────────────────────┼────────────┤
# │     Media Truncada Equiponderada (57.0, 84.0) │   0.335592 │
# │                 Percentil equiponderado 71.96 │    0.40714 │
# │  Inflación de exclusión dinámica (0.34, 1.81) │  0.0175506 │
# │       Media Truncada Ponderada (20.51, 95.98) │ 6.34198e-7 │
# │                     Percentil ponderado 69.86 │   0.239716 │
# │ Exclusión fija de gastos básicos IPC (14, 17) │        0.0 │
# │                           MAI óptima MSE 2023 │        0.0 │
# └───────────────────────────────────────────────┴────────────┘

# ┌────────────────────────────────────┬─────────┐
# │                            measure │ weights │
# │                             String │   Int64 │
# ├────────────────────────────────────┼─────────┤
# │      MAI (FP,4,[0.28, 0.72, 0.76]) │       0 │
# │       MAI (F,4,[0.38, 0.67, 0.83]) │       0 │
# │ MAI (G,5,[0.06, 0.27, 0.74, 0.77]) │       0 │
# └────────────────────────────────────┴─────────┘

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
# ┌───────┬───────────┬───────────┬───────────┐
# │       │       b00 │         T │       b10 │
# ├───────┼───────────┼───────────┼───────────┤
# │ upper │   1.07375 │  0.731238 │  0.396138 │
# │ lower │ -0.855919 │ -0.414002 │ -0.478621 │
# └───────┴───────────┴───────────┴───────────┘
