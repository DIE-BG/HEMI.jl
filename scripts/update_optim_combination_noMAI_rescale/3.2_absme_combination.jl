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
loadpath = datadir("results", "tray_infl", "absme")
tray_dir = joinpath(loadpath, "tray_infl")
combination_loadpath  = datadir("results","optim_combination","absme")
combination_savepath  = datadir("results","optim_combination","absme_noMAI_rescale")

# RECOLECTAMOS LOS PESOS ORIGINALES
df_weights = collect_results(combination_loadpath)
df_optim_weights = DataFrame(
    inflfn = [x for x in df_weights.optabsme2023[1].ensemble.functions],
    weight = [x for x in df_weights.optabsme2023[1].weights]
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
optabsme2023 = CombinationFunction(
    df_optim_weights.inflfn...,
    df_optim_weights.weight, 
    "Subyacente óptima ABSME 2023"
)

wsave(joinpath(combination_savepath,"optabsme2023.jld2"), "optabsme2023", optabsme2023)



# pretty_table(components(optabsme2023))
# ┌──────────────────────────────────────────────┬──────────┐
# │                                      measure │  weights │
# │                                       String │  Float32 │
# ├──────────────────────────────────────────────┼──────────┤
# │  Media Truncada Equiponderada (33.41, 93.73) │ 0.474419 │
# │  Exclusión fija de gastos básicos IPC (9, 6) │      0.0 │
# │ Inflación de exclusión dinámica (1.05, 3.49) │ 0.104262 │
# │      Media Truncada Ponderada (32.16, 93.26) │ 0.135852 │
# │                    Percentil ponderado 70.23 │ 0.120182 │
# │                Percentil equiponderado 71.92 │ 0.165285 │
# │                        MAI óptima ABSME 2023 │      0.0 │
# └──────────────────────────────────────────────┴──────────┘

######################################################################################
################## INTERVALO DE CONFIANZA ############################################
######################################################################################

# CARGAMOS DATAFRAMES
df_results = collect_results(loadpath)
@chain df_results begin 
    select(:measure, :absme)
end
combine_df = @chain df_results begin 
    select(:measure, :absme, :inflfn, 
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
# │ upper │   1.33587 │   1.85578 │  0.988615 │
# │ lower │ -0.805544 │ -0.296012 │ -0.570317 │
# └───────┴───────────┴───────────┴───────────┘