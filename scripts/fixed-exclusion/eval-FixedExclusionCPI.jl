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
 - DAMP alimentos y energéticos
 - DAMP energéticos 
 - DIE Todo alimentos y energéticos

"""
## Elementos generales evaluación
gtdata_eval = gtdata[Date(2020, 12)]
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()

## Vectores de exclusión por medida
# 1. DAMP alimentos y energéticos

exc_damp1 = (vcat(collect(23:41), 104, 159), vcat(collect(22:48), 116, collect(184:186)))

# 2. DAMP energéticos
exc_damp2 = ([104, 159], vcat(116, collect(184:186)))

# 3. DIE todo alimentos y energéticos
exc_die1 = (vcat(collect(1:62), 104, 159), vcat(collect(1:74), collect(116:118), collect(184:186)))

# 4. DIE excluión fija óptima
opt00 = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188]
opt10 = [29, 46, 39, 31, 116]
exc_opt_die = (opt00, opt10)

## Creación de diccionario para simulación y savepath
list = [exc_damp1, exc_damp2, exc_die1, exc_opt_die]

sim_FxEx = Dict(
    :inflfn => InflationFixedExclusionCPI.(list), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 10000) |> dict_list


savepath = datadir("fixed-exclusion","Medidas-base")

## lote de simulación 

run_batch(gtdata_eval, sim_FxEx, savepath)

## resultados

FxEx_base = collect_results(savepath)

## Trayectorias
damp1 = InflationFixedExclusionCPI(exc_damp1)
damp2 = InflationFixedExclusionCPI(exc_damp2)
die1 = InflationFixedExclusionCPI(exc_die1)
die2 = InflationFixedExclusionCPI(exc_opt_die)
param = InflationTotalRebaseCPI() 
param_tray_infl = param(gtdata)

damp_ae = damp1(gtdata)
damp_e = damp2(gtdata)
die_ae = die1(gtdata)
die_opt = die2(gtdata)

using Plots
plot(die_opt, label = "DIE optima") 
plot!(die_ae, label= "DIE Alim y Energ")  
plot!(damp_ae, label = "DAMP Alim y Energ")
plot!(damp_e, label = "DAMP Energ")  
plot!(param_tray_infl, label="Parámetro")
    
    savefig("plots//fixed-exclusion//TRAYECTORIAS")