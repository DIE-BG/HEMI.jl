# # Script de prueba para tipos que especifican variantes de simulación
using DrWatson
@quickactivate "HEMI"

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI
using DataFrames
using Plots, CSV

"""
Evaluación comparativa con exclusiones óptimas 2019 y 2020

Evaluación 2019
Base 2000: [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161]
Base 2010: [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184]

Evaluación 2020
Base 2000: [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188]
Base 2010: [29, 46, 39, 31, 116]
"""

## Instancias generales
gtdata_10 = gtdata[Date(2020, 12)]
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()

opt00_19 = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161]
opt10_19 = [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184]
v_exc19  = (opt00_19, opt10_19)

opt00_20  = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188]
opt10_20  = [29, 46, 39, 31, 116]
v_exc20   = (opt00_20, opt10_20)


## Creación de diccionario para simulación y savepath
# Exploración inicial con 10000 simulaciones

FxEx_00 = Dict(
    :inflfn => InflationFixedExclusionCPI.(total), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 125000) |> dict_list

savepath = datadir("fixed-exclusion","Base2010")    

## lote de simulación 

run_batch(gtdata_10, FxEx_00, savepath)

## resultados

dfExc_10 = collect_results(savepath)