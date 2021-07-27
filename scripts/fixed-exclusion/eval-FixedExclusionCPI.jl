# # Script de prueba para tipos que especifican variantes de simulación
using DrWatson
@quickactivate "HEMI"

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

"""
ref: https://github.com/DIE-BG/EMI/blob/master/%2BEMI/%2Bexclusion_fija/exclusion_alternativas.m
1. Evaluación de medidas de exclusión fija 
 - Alimentos y energéticos variante 1
 - Energéticos 
 - Alimentos y energéticos variante 2

"""
## Elementos generales evaluación
gtdata_eval = gtdata[Date(2020, 12)]
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()

# Inflación Inflation total
tot = InflationTotalCPI()
Infl_total = tot(gtdata_eval)
## Vectores de exclusión por medida
# 1. Alimentos y energéticos variante 1

exc_ae1 = (vcat(collect(23:41), 104, 159), vcat(collect(22:48), 116, collect(184:186)))

# 2.Energéticos
exc_e  = ([104, 159], vcat(116, collect(184:186)))

# 3. Todo alimentos y energéticos
exc_ae2 = (vcat(collect(1:62), 104, 159), vcat(collect(1:74), collect(116:118), collect(184:186)))

# 4. Excluión fija óptima
opt00 = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188]
opt10 = [29, 46, 39, 31, 116]
exc_opt = (opt00, opt10)

## Creación de diccionario para simulación y savepath
list = [exc_damp1, exc_damp2, exc_die1, exc_opt_die]

sim_FxEx = Dict(
    :inflfn => InflationFixedExclusionCPI.(list), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 125000) |> dict_list


savepath = datadir("fixed-exclusion","Medidas-base")

## lote de simulación 

run_batch(gtdata_eval, sim_FxEx, savepath)

## resultados

FxEx_base = collect_results(savepath)

## Trayectorias hasta Febrero 2021
AE_v1 = InflationFixedExclusionCPI(exc_ae1)(gtdata)
Energ = InflationFixedExclusionCPI(exc_e)(gtdata)
AE_v2 = InflationFixedExclusionCPI(exc_ae2)(gtdata)
Opt = InflationFixedExclusionCPI(exc_opt)(gtdata)
param = InflationTotalRebaseCPI() 
param_tray_infl = param(gtdata)


saveplot = plotsdir("fixed-exclusion", "Medidas-Base")

using Plots
tray_plot = plot(Opt, label = "Exclusión Fija Óptima") 
plot!(AE_v1, label= "Alimentos y Energéticos variante 1")  
plot!(Energ, label = "Energéticos")
plot!(AE_v2, label = "Alimentos y Energéticos variante 2")  
plot!(Infl_total, label = "Inflación Total")
plot!(param_tray_infl, label="Inflación Parámetro")
    
savefig(tray_plot,saveplot)