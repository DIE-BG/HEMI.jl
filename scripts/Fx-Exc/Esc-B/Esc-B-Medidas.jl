# Evaluación de Medidas Basadas en Exclusión fija

##
"""
Escenario B: extender el trabajo efectuado en 2020 (criterios básicos a dic-20)

En este scrpit se evaluan las medidas basadas en exclusión fija descritas a continuación

Evaluación de medidas de exclusión fija 
 1. Exclusión fija de Alimentos y energéticos variante 11
 2. Exclusión fija de Energéticos 
 3. Exclusión fija de Alimentos y energéticos variante 9
 4. Exclusión fija óptima 

 Los parámetros de configuración son los siguientes:

 - Período de Evaluación: Diciembre 2001 - Diciembre 2020, ff = Date(2020, 12). <======================
 - Trayectoria de inflación paramétrica con cambio de base sintético: 2 cambios de base cada 3 años, [InflationTotalRebaseCPI(36, 2)].
 - Método de remuestreo de extracciones estocásticas independientes (Remuestreo por meses de ocurrencia), [ResampleScrambleVarMonths()].
 - Muestra completa para evaluación, [SimConfig].

 ref: https://github.com/DIE-BG/EMI/blob/master/%2BEMI/%2Bexclusion_fija/exclusion_alternativas.m
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
resamplefn = ResampleScrambleVarMonths()
paramfn    = InflationTotalRebaseCPI(36,2)
ff = Date(2020,12)

## Vectores de exclusión por medida
# 1. Exclusión fija de Alimentos y energéticos variante 11
exc_ae1 = (vcat(collect(23:41), 104, 159), vcat(collect(22:48), 116, collect(184:186)))

# Exclusión fija de Energéticos 
exc_e  = ([104, 159], vcat(116, collect(184:186)))

# Exclusión fija de Alimentos y energéticos variante 9
exc_ae2 = (vcat(collect(1:62), 104, 159), vcat(collect(1:74), collect(116:118), collect(184:186)))

# 4. Exclusión fija óptima 
opt00 = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161]
## Cambio aquí!
opt10 = [29, 46, 39, 31, 116, 40, 30, 186, 35, 47, 197, 41, 22, 185, 48, 34, 37, 184]
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
    :traindate => ff) |> dict_list


savepath = datadir("results","Fx-Exc","Esc-B","Medidas")

## lote de simulación 

run_batch(gtdata, sim_FxEx, savepath)

## recolección de resultados

FxEx = collect_results(savepath)

## Gráfica MSE
df = DataFrame(medida = ["Exclusión Óptima", "Exclusión Energéticos","Alimentos y energéticos 11", "Alimentos y Energéticos 9"], 
               mse = FxEx[!,:mse], huber = FxEx[!,:huber])
df = sort!(df, :mse)

gr = [df[1,:mse],df[2,:mse], df[3,:mse],df[4,:mse]]
gr_l = ["Exc. Óptima","Alim y En. 9","Alim. y En. 11","Energéticos*"]
graf = plot(gr, seriestype=:bar, xticks = (1:4, gr_l), label=false, ylims=[0, 5], dpi=200)
title!("MSE - Medidas de Exclusión Fija")       
annotate!((1, gr[1]+0.2, string(gr[1])[1:4]),
          (2, gr[2]+0.2, string(gr[2])[1:4]), 
          (3, gr[3]+0.2, string(gr[3])[1:4]),
          (4, 4.5, string(gr[4])[1:4]), annotationfontsize = 8)

saveplot = plotsdir("Fx-Exc","Esc-B","MSE-Med")
savefig(graf,saveplot)

## Trayectorias
## Trayectorias hasta Febrero 2021

tot = InflationTotalCPI()(gtdata)
AE_v1 = InflationFixedExclusionCPI(exc_ae1)(gtdata)
Energ = InflationFixedExclusionCPI(exc_e)(gtdata)
AE_v2 = InflationFixedExclusionCPI(exc_ae2)(gtdata)
Opt = InflationFixedExclusionCPI(exc_opt)(gtdata)

saveplot = plotsdir("Fx-Exc","Esc-B","Trayectorias")

plotrng = Date(2001, 12):Month(1):Date(2021, 6)

tray_plot = plot(plotrng, Opt, label = "Exclusión Fija Óptima",
title = "Medidas de Exclusión Fija", dpi=200) 

plot!(plotrng, AE_v1, label= "Alimentos y Energéticos (11)")
plot!(plotrng, Energ, label = "Energéticos")
plot!(plotrng, AE_v2, label = "Alimentos y Energéticos (9)")  
plot!(plotrng, tot, label = "Inflación Total", linestyle=:dash, color=[:black])

hspan!([3,5], color=[:gray], alpha=0.25, label="")
hline!([4], linestyle=:dash, color=[:black], label = "")
    
savefig(tray_plot,saveplot)

## Trayectorias óptimas 19-20
# Base 2000 -> [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 Exclusiones)
# Base 2010 -> [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184] (17 exclusiones)

opt19 = InflationFixedExclusionCPI(([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161],
                                    [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184]))(gtdata)

tray_plot = plot(plotrng, Opt, label = "Exclusión Fija Óptima 2020",
            title = "Exclusión Fija Óptima 2019-2020", dpi=200)  
plot!(plotrng, opt19, label= "Exclusión Fija Óptima 2019")     
hspan!([3,5], color=[:gray], alpha=0.25, label="")
hline!([4], linestyle=:dash, color=[:black], label = "")
saveplot = plotsdir("Fx-Exc","Esc-B","Comp-Optimas")  
savefig(tray_plot,saveplot)                             