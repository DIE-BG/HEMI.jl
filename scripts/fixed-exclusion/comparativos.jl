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
gtdata_eval = gtdata[Date(2020, 12)]
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()

# Óptima 2019
opt00_19 = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161]
opt10_19 = [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184]
v_exc19  = (opt00_19, opt10_19)
# Óptima 2020
opt00_20  = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188]
opt10_20  = [29, 46, 39, 31, 116]
v_exc20   = (opt00_20, opt10_20)

# Otras combinaciones
# sin cambiar la base 2000
v_exc3 = (opt00_19, opt10_20)
v_exc4 = (opt00_20, opt10_19)

exc = vcat(v_exc19, v_exc20, v_exc3, v_exc4)
## Creación de diccionario para simulación y savepath
# Exploración inicial con 10000 simulaciones

FxEx_00 = Dict(
    :inflfn => InflationFixedExclusionCPI.(exc), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 10000) |> dict_list

savepath = datadir("fixed-exclusion","Combinaciones-10K")    

## lote de simulación 

run_batch(gtdata_eval, FxEx_00, savepath)

## resultados

dfExc = collect_results(savepath)
sorted = sort(dfExc, :mse)

gr = [sorted[1,:mse],sorted[2,:mse], sorted[3,:mse],sorted[4,:mse]]
gr_l = ["Opt. Eval-20","00-20/10-19","00-19/10-20","Opt. Eval-19"]
graf = plot(gr, seriestype=:bar, xticks = (1:4, gr_l), label="MSE", ylims=[0, 6])
title!("Comparativo entre Medidas de Exclusión óptima")

saveplot = plotsdir("fixed-exclusion", "Comparativo")
savefig(graf,saveplot)


