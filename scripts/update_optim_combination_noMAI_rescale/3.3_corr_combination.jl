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
loadpath = datadir("results", "tray_infl", "corr")
tray_dir = joinpath(loadpath, "tray_infl")
combination_loadpath  = datadir("results","optim_combination","corr")
combination_savepath  = datadir("results","optim_combination","corr_noMAI_rescale")


# RECOLECTAMOS LOS PESOS ORIGINALES
df_weights = collect_results(combination_loadpath)
df_optim_weights = DataFrame(
    inflfn = [x for x in df_weights.optcorr2023[1].ensemble.functions],
    weight = [x for x in df_weights.optcorr2023[1].weights]
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
optcorr2023 = CombinationFunction(
    df_optim_weights.inflfn...,
    df_optim_weights.weight, 
    "Subyacente óptima CORR 2023"
)

wsave(joinpath(combination_savepath,"optcorr2023.jld2"), "optcorr2023", optcorr2023)


# pretty_table(components(optcorr2023))
# ┌───────────────────────────────────────────────┬────────────┐
# │                                       measure │    weights │
# │                                        String │    Float32 │
# ├───────────────────────────────────────────────┼────────────┤
# │                      Percentil ponderado 81.0 │ 1.92011e-6 │
# │  Inflación de exclusión dinámica (0.46, 4.97) │   0.078062 │
# │ Exclusión fija de gastos básicos IPC (14, 51) │        0.0 │
# │       Media Truncada Ponderada (53.56, 96.47) │   0.127385 │
# │                 Percentil equiponderado 80.86 │   0.428769 │
# │     Media Truncada Equiponderada (55.0, 92.0) │   0.365782 │
# │                          MAI óptima CORR 2023 │        0.0 │
# └───────────────────────────────────────────────┴────────────┘
