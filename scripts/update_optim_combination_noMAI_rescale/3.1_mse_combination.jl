using DrWatson
@quickactivate "HEMI" 

using HEMI 
## Parallel processing
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI 


## Otras librerías
using DataFrames, Chain

# DIRECTORIOS
loadpath = datadir("results", "tray_infl", "mse")
tray_dir = joinpath(loadpath, "tray_infl")
combination_loadpath  = datadir("results","optim_combination","mse")
combination_savepath  = datadir("results","optim_combination","mse_noMAI_rescale")


# RECOLECTAMOS LOS PESOS ORIGINALES
df_weights = collect_results(combination_loadpath)
df_optim_weights = DataFrame(
    inflfn = [x for x in df_weights.optmse2023[1].ensemble.functions],
    weight = [x for x in df_weights.optmse2023[1].weights]
)

df_optim_weights.measure = measure_name.(df_optim_weights.inflfn)


# FIJAMOS EN CERO LOS PESOS DE LAS MAI Y RE-ESCALAMOS
for x in eachrow(df_optim_weights)
    if x.inflfn isa CombinationFunction
        x.weight = 0
    end
end

df_optim_weights[!,:weight] = df_optim_weights[:,:weight] / sum(df_optim_weights[:,:weight])


# CONSTRUIMOS LA NUEVA SUBYACENTE OPTIMA
optmse2023 = CombinationFunction(
    df_optim_weights.inflfn...,
    df_optim_weights.weight, 
    "Subyacente óptima MSE 2023"
)

wsave(joinpath(combination_savepath,"optmse2023.jld2"), "optmse2023", optmse2023)

# ┌───────────────────────────────────────────────┬────────────┐
# │                                       measure │     weight │
# │                                        String │    Float32 │
# ├───────────────────────────────────────────────┼────────────┤
# │     Media Truncada Equiponderada (57.0, 84.0) │   0.486143 │
# │                 Percentil equiponderado 71.96 │   0.267312 │
# │  Inflación de exclusión dinámica (0.34, 1.81) │  0.0182175 │
# │       Media Truncada Ponderada (20.51, 95.98) │ 1.13556e-6 │
# │                     Percentil ponderado 69.86 │   0.228327 │
# │ Exclusión fija de gastos básicos IPC (14, 17) │        0.0 │
# │                           MAI óptima MSE 2023 │        0.0 │
# └───────────────────────────────────────────────┴────────────┘


######################################################################################
################## INTERVALO DE CONFIANZA ############################################
######################################################################################

# CARGAMOS DATAFRAMES
df_results = collect_results(loadpath)
@chain df_results begin 
    select(:measure, :mse)
end
combine_df = @chain df_results begin 
    select(:measure, :mse, :inflfn, 
        :path => ByRow(p -> joinpath(tray_dir, basename(p))) => :tray_path
    )
end

## INSERTAMOS LOS PESOS EN ORDEN CORRESPONDIENTE VIA OUTERJOIN
DF_temp = outerjoin(combine_df, df_optim_weights[:,[:measure,:weight]], on=:measure)
DF_temp = DF_temp[.!(ismissing.(DF_temp.inflfn)),:]
DF_temp.weight = coalesce.(DF_temp.weight, 0)

# CARGAMOS TRAYECTORIAS
tray_infl = mapreduce(hcat, DF_temp.tray_path) do path
    load(path, "tray_infl")
end

# CONTRUIMOS PARAMETRO
resamplefn = df_results[1, :resamplefn]
trendfn = df_results[1, :trendfn]
paramfn = df_results[1, :paramfn]
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)

# CALCULAMOS LOS INTERVALOS DE CONFIANZA
a = reshape(DF_temp.weight,(1,length(DF_temp.weight),1))
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
# │ upper │   1.25536 │   1.89096 │    1.0703 │
# │ lower │ -0.850729 │ -0.193368 │ -0.483512 │
# └───────┴───────────┴───────────┴───────────┘
