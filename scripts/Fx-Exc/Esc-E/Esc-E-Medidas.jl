# Evaluación de Medidas Basadas en Exclusión fija

##
"""
Escenario E

En este scrpit se evaluan las medidas basadas en exclusión fija descritas a continuación

Evaluación de medidas de exclusión fija 
 1. Exclusión fija de Alimentos y energéticos variante 11
 2. Exclusión fija de Energéticos 
 3. Exclusión fija de Alimentos y energéticos variante 9
 4. Exclusión fija óptima 

 Los parámetros de configuración en este caso son los siguientes:

 inflfn     = InflationPercentileEq(69)
 resamplefn = ResampleSBB(36)
 trendfn    = TrendRandomWalk()
 paramfn    = InflationTotalRebaseCPI(60)
 nsim       = 125_000
 evaldate   = Date(2018,12)
 
 # Configuración de simulación período Diciembre 2001 - Diciembre 2018
 config = SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, evaldate).

"""

## carga de paquetes
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

## Definición de instancias principales
trendfn    = TrendRandomWalk()
resamplefn = ResampleSBB(36)
paramfn    = InflationTotalRebaseCPI(60)
ff = Date(2018,12) #< =====================

## Vectores de exclusión por medida
# 1. Exclusión fija de Alimentos y energéticos variante 11
exc_ae1 = (vcat(collect(23:41), 104, 159), vcat(collect(22:48), 116, collect(184:186)))

# Exclusión fija de Energéticos 
exc_e  = ([104, 159], vcat(116, collect(184:186)))

# Exclusión fija de Alimentos y energéticos variante 9
exc_ae2 = (vcat(collect(1:62), 104, 159), vcat(collect(1:74), collect(116:118), collect(184:186)))

# 4. Exclusión fija óptima 
opt00 = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188]
opt10 = [29, 46, 39, 31, 116]
exc_opt = (opt00, opt10)

# Vector con variantes de exclusión
list = [exc_ae1, exc_e, exc_ae2, exc_opt]

## Diccionario con variantes 
sim_FxEx = Dict(
    :inflfn => InflationFixedExclusionCPI.(list), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 125_000,
    :traindate => ff,  
    :evalperiods => (CompletePeriod(),)) |> dict_list


savepath = datadir("results","Fx-Exc","Esc-E","Medidas")  

## lote de simulación 

run_batch(gtdata, sim_FxEx, savepath, savetrajectories = true)

## recolección de resultados

FxEx = collect_results(savepath)
FxEx.medida = ["Exclusión Energéticos", "Alimentos y energéticos 11","Exclusión Óptima",  "Alimentos y Energéticos 9"]
## Gráfica MSE
df = DataFrame(medida = ["Exclusión Energéticos", "Alimentos y energéticos 11","Exclusión Óptima",  "Alimentos y Energéticos 9"], 
               mse = FxEx[!,:mse], huber = FxEx[!,:huber])
df = sort!(df, :mse)

gr = [df[1,:mse],df[2,:mse], df[3,:mse],df[4,:mse]]
gr_l = ["Exc. Óptima","Alim y En. 11","Alim. y En. 9","Energéticos*"]
graf = plot(gr, seriestype=:bar, xticks = (1:4, gr_l), label=false, dpi=200)
title!("MSE - Medidas de Exclusión Fija")       
annotate!((1, gr[1]+0.2, string(gr[1])[1:4]),
          (2, gr[2]+0.2, string(gr[2])[1:4]), 
          (3, gr[3]+0.2, string(gr[3])[1:4]),
          (4, 4.5, string(gr[4])[1:4]), annotationfontsize = 8)

saveplot = plotsdir("Fx-Exc\\Esc-E","MSE-Med.svg")
savefig(graf,saveplot)

## Trayectorias
## Trayectorias hasta Febrero 2021

tot = InflationTotalCPI()(gtdata)
AE_v1 = InflationFixedExclusionCPI(exc_ae1)(gtdata)
Energ = InflationFixedExclusionCPI(exc_e)(gtdata)
AE_v2 = InflationFixedExclusionCPI(exc_ae2)(gtdata)
Opt = InflationFixedExclusionCPI(exc_opt)(gtdata)

plotrng = Date(2001, 12):Month(1):Date(2021, 6)
## óptima
tray_plot = plot(plotrng, Opt, label = "Exclusión Fija Óptima",
title = "Medidas basadas en Exclusión Fija", dpi=200) 
plot!(plotrng, tot, label = "Inflación Total", color=[:black])
saveplot = plotsdir("Fx-Exc\\Esc-E","optima.svg") 
savefig(tray_plot,saveplot)



