# Evaluación de Medidas Basadas en Exclusión fija

##
"""
Escenario A: replica del trabajo efectuado en 2020 (criterios básicos a dic-19)

En este scrpit se evaluan las medidas basadas en exclusión fija descritas a continuación

Evaluación de medidas de exclusión fija 
 1. Exclusión fija de Alimentos y energéticos variante 11
 2. Exclusión fija de Energéticos 
 3. Exclusión fija de Alimentos y energéticos variante 9
 4. Exclusión fija óptima 

 Los parámetros de configuración son los siguientes:

 1. Período de Evaluación: Diciembre 2001 - Diciembre 2019, `ff = Date(2019, 12)`.
 2. Trayectoria de inflación paramétrica con cambio de base sintético: 2 cambios de base cada 3 años,  [`InflationTotalRebaseCPI(36, 2)`].
 3. Método de remuestreo de extracciones estocásticas independientes (Remuestreo por meses de ocurrencia), [`ResampleScrambleVarMonths()`].
 4. Muestra completa para evaluación, [`SimConfig`].

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
ff = Date(2019,12)

## Vectores de exclusión por medida
# 1. Exclusión fija de Alimentos y energéticos variante 11
exc_ae1 = (vcat(collect(23:41), 104, 159), vcat(collect(22:48), 116, collect(184:186)))

# Exclusión fija de Energéticos 
exc_e  = ([104, 159], vcat(116, collect(184:186)))

# Exclusión fija de Alimentos y energéticos variante 9
exc_ae2 = (vcat(collect(1:62), 104, 159), vcat(collect(1:74), collect(116:118), collect(184:186)))

# 4. Exclusión fija óptima 
opt00 = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161]
opt10 = [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184]
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


savepath = datadir("results","Fx-Exc","Esc-A","Medidas")

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

saveplot = plotsdir("Fx-Exc","Esc-A","MSE-Med.svg")
savefig(graf,saveplot)

## Trayectorias
## Trayectorias hasta Febrero 2021

tot = InflationTotalCPI()(gtdata)
AE_v1 = InflationFixedExclusionCPI(exc_ae1)(gtdata)
Energ = InflationFixedExclusionCPI(exc_e)(gtdata)
AE_v2 = InflationFixedExclusionCPI(exc_ae2)(gtdata)
Opt = InflationFixedExclusionCPI(exc_opt)(gtdata)

saveplot = plotsdir("Fx-Exc","Esc-A","Trayectorias-FxEx.svg")

plotrng = Date(2001, 12):Month(1):Date(2021, 6)

tray_plot = plot(plotrng, Opt, label = "Exclusión Fija Óptima",
title = "Medidas de exclusión Fija", dpi=200) 

plot!(plotrng, AE_v1, label= "Alimentos y Energéticos (11)")
plot!(plotrng, Energ, label = "Energéticos")
plot!(plotrng, AE_v2, label = "Alimentos y Energéticos (9)")  
plot!(plotrng, tot, label = "Inflación Total", color=[:black])

hspan!([3,5], color=[:gray], alpha=0.25, label="")
hline!([4], linestyle=:dash, color=[:black], label = "")
    
savefig(tray_plot,saveplot)



## Tabla Markdown
using Chain
using PrettyTables
savepath = datadir("results","Fx-Exc","Esc-A","Medidas")
df = collect_results(savepath)
gr_l = ["Exclusión Óptima","Alimentos y Energéticos 11","Alimentos y Energéticos 9","Energéticos"]
# Exc_1019[!,:exclusiones] = exclusiones 
sens_metrics = @chain df begin 
    select(:mse, :mse_std_error, r"^mse_[bvc]", :rmse, :me, :mae, :huber, :corr)
    sort(:mse)
end 

insertcols!(sens_metrics, 1, :medida => gr_l)
# sens_metrics[!,:medida] = gr_l
vscodedisplay(sens_metrics)

pretty_table(sens_metrics, tf=tf_markdown, formatters=ft_round(3))

"""
|                     medida |      mse | mse_std_error | mse_bias |  mse_var |  mse_cov |     rmse |       me |      mae |    huber |     corr |
|                     String | Float32? |      Float64? | Float32? | Float32? | Float32? | Float32? | Float32? | Float32? | Float64? | Float32? |
|----------------------------|----------|---------------|----------|----------|----------|----------|----------|----------|----------|----------|
|           Exclusión Óptima |   0.6422 |        0.0006 |   0.1263 |   0.1408 |   0.3752 |   0.7919 |  -0.3051 |   0.6407 |   0.2901 |   0.9731 |
| Alimentos y Energéticos 11 |   0.8667 |        0.0016 |   0.1836 |   0.2534 |   0.4297 |   0.9102 |  -0.3668 |   0.7396 |   0.3659 |   0.9707 |
|  Alimentos y Energéticos 9 |   3.1216 |         0.003 |   2.3603 |   0.1495 |   0.6117 |   1.7542 |  -1.5135 |   1.5924 |   1.1134 |    0.954 |
|                Energéticos |  82.0842 |        2.3344 |  10.4907 |  62.9358 |   8.6577 |   4.2484 |   1.6031 |   2.3149 |   1.9144 |   0.7678 |

"""

