# Evaluación de Medidas Basadas en Exclusión fija

##
"""
Escenario C: Evaluación de criterios básicos con cambio de parámetro de evaluación

En este scrpit se evaluan las medidas basadas en exclusión fija descritas a continuación

Evaluación de medidas de exclusión fija 
 1. Exclusión fija de Alimentos y energéticos variante 11
 2. Exclusión fija de Energéticos 
 3. Exclusión fija de Alimentos y energéticos variante 9
 4. Exclusión fija óptima 

 Los parámetros de configuración en este caso son los siguientes:

 - Período de Evaluación: Diciembre 2001 - Diciembre 2019, ff = Date(2019, 12)
 - Trayectoria de inflación paramétrica con cambios de base cada 5 años, [InflationTotalRebaseCPI(60)].
 - Método de remuestreo de extracciones estocásticas independientes (Remuestreo por meses de ocurrencia), [ResampleScrambleVarMonths()].
 - Muestra completa para evaluación [SimConfig].

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
paramfn    = InflationTotalRebaseCPI(60)
ff = Date(2019,12)

## Vectores de exclusión por medida
# 1. Exclusión fija de Alimentos y energéticos variante 11
exc_ae1 = (vcat(collect(23:41), 104, 159), vcat(collect(22:48), 116, collect(184:186)))

# Exclusión fija de Energéticos 
exc_e  = ([104, 159], vcat(116, collect(184:186)))

# Exclusión fija de Alimentos y energéticos variante 9
exc_ae2 = (vcat(collect(1:62), 104, 159), vcat(collect(1:74), collect(116:118), collect(184:186)))

# 4. Exclusión fija óptima 
opt00 = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193]
opt10 = [29, 31, 116, 39, 46, 40, 30]
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


savepath = datadir("results","Fx-Exc","Esc-C","C19","Medidas")  

## lote de simulación 

run_batch(gtdata, sim_FxEx, savepath)

## recolección de resultados

FxEx = collect_results(savepath)

## Gráfica MSE
df = DataFrame(medida = ["Exclusión Óptima", "Exclusión Energéticos","Alimentos y energéticos 11", "Alimentos y Energéticos 9"], 
               mse = FxEx[!,:mse], huber = FxEx[!,:huber])
df = sort!(df, :mse)

gr = [df[1,:mse],df[2,:mse], df[3,:mse],df[4,:mse]]
gr_l = ["Exc. Óptima","Alim y En. 11","Alim. y En. 9","Energéticos*"]
graf = plot(gr, seriestype=:bar, xticks = (1:4, gr_l), label=false, ylims=[0, 5], dpi=200)
title!("MSE - Medidas de Exclusión Fija")       
annotate!((1, gr[1]+0.2, string(gr[1])[1:4]),
          (2, gr[2]+0.2, string(gr[2])[1:4]), 
          (3, gr[3]+0.2, string(gr[3])[1:4]),
          (4, 4.5, string(gr[4])[1:4]), annotationfontsize = 8)

saveplot = plotsdir("Fx-Exc\\Esc-C\\C-19","MSE-Med.svg")
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

# hspan!([3,5], color=[:gray], alpha=0.25, label="")
# hline!([4], linestyle=:dash, color=[:black], label = "") 
saveplot = plotsdir("Fx-Exc\\Esc-C\\C-19","optima.svg") 
savefig(tray_plot,saveplot)

## Trayectorias
tray_plot = plot(plotrng, Opt, label = "Exclusión Fija Óptima",
title = "Medidas basadas en Exclusión Fija", dpi=200) 
plot!(plotrng, tot, label = "Inflación Total", color=[:black])
plot!(plotrng, AE_v1, label= "Alimentos y Energéticos (11)")
plot!(plotrng, Energ, label = "Energéticos")
plot!(plotrng, AE_v2, label = "Alimentos y Energéticos (9)") 
saveplot = plotsdir("Fx-Exc\\Esc-C\\C-19","Trayectorias-FxEx.svg")
savefig(tray_plot,saveplot)


## Trayectorias óptimas 19-C19
# Base 2000 -> [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 Exclusiones)
# Base 2010 -> [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184] (17 exclusiones)

opt19A = InflationFixedExclusionCPI(([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161],
                                    [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184]))(gtdata)

tray_plot = plot(plotrng, Opt, label = "Exclusión Fija Óptima 2019 SBB",
            title = "Exclusión Fija Óptima 2019A-2019C", dpi=200)  
plot!(plotrng, opt19A, label= "Exclusión Fija Óptima 2019A")     
hspan!([3,5], color=[:gray], alpha=0.25, label="")
hline!([4], linestyle=:dash, color=[:black], label = "")
saveplot = plotsdir("Fx-Exc","Esc-C","C-19","Comp-Optimas")  
savefig(tray_plot,saveplot)        


## Tablas 

df = FxEx
## Tabla Markdown
using Chain
using PrettyTables
# savepath = datadir("results","Fx-Exc","Esc-C","C-20","Medidas")  
df = collect_results(savepath)
gr_l = ["Exclusión Óptima","Alimentos y Energéticos 11","Alimentos y Energéticos 9","Energéticos"]
# Exc_1019[!,:exclusiones] = exclusiones 

# Tabla 1 resultados con criterios básicos (mse y std error)
sens_metrics = @chain df begin 
    select(:mse, :mse_std_error)#, r"^mse_[bvc]", :rmse, :me, :mae, :huber, :corr)
    sort(:mse)
end 

insertcols!(sens_metrics, 1, :medida => gr_l)
# sens_metrics[!,:medida] = gr_l
pretty_table(sens_metrics, tf=tf_markdown, formatters=ft_round(3))

# Tabla 2, descomposición aditiva del MSE
sens_metrics = @chain df begin 
    select(:mse, r"^mse_[bvc]")#, :rmse, :me, :mae, :huber, :corr)
    sort(:mse)
end 

t2 = sens_metrics[!,2:end]
insertcols!(t2, 1, :medida => gr_l)
pretty_table(t2, tf=tf_markdown, formatters=ft_round(3))

# Tabla 3, Métricas de evaluación
sens_metrics = @chain df begin 
    select(:mse, :rmse, :me, :mae, :huber, :corr)
    sort(:mse)
end 

t3 = sens_metrics[!,2:end]
insertcols!(t3, 1, :medida => gr_l)
pretty_table(t3, tf=tf_markdown, formatters=ft_round(3))
"""
|                     medida |      mse | mse_std_error | mse_bias |  mse_var |  mse_cov |     rmse |       me |      mae |    huber |     corr |
|                     String | Float32? |      Float64? | Float32? | Float32? | Float32? | Float32? | Float32? | Float32? | Float64? | Float32? |
|----------------------------|----------|---------------|----------|----------|----------|----------|----------|----------|----------|----------|
|           Exclusión Óptima |    0.807 |         0.001 |    0.208 |    0.092 |    0.507 |    0.891 |   -0.415 |    0.733 |    0.361 |    0.964 |
| Alimentos y Energéticos 11 |    1.092 |         0.001 |    0.422 |    0.211 |    0.459 |    1.031 |   -0.611 |     0.87 |    0.466 |    0.969 |
|  Alimentos y Energéticos 9 |     3.97 |         0.003 |    3.158 |    0.142 |     0.67 |    1.981 |   -1.757 |    1.817 |    1.332 |     0.95 |
|                Energéticos |   81.064 |         2.329 |    9.768 |    62.64 |    8.656 |    4.148 |    1.359 |    2.257 |    1.855 |    0.771 |

# Resultados criterios básicos

| Medida                     | MSE      | Error Estándar  |
|:---------------------------|---------:|----------------:|
|           Exclusión Óptima |    0.807 |           0.001 |
| Alimentos y Energéticos 11 |    1.092 |           0.001 |
|  Alimentos y Energéticos 9 |     3.97 |           0.003 |
|                Energéticos |   81.064 |           2.329 |

|                     Medida | Comp. Sesgo |  Comp. Varianza |  Comp. Covarianza |
|:---------------------------|------------:|----------------:|------------------:|
|           Exclusión Óptima |       0.208 |           0.092 |             0.507 |
| Alimentos y Energéticos 11 |       0.422 |           0.211 |             0.459 |
|  Alimentos y Energéticos 9 |       3.158 |           0.142 |              0.67 |
|                Energéticos |       9.768 |           62.64 |             8.656 |


|                     Medida |     RMSE |       ME |      MAE |    Huber | Correlación |
|:---------------------------|---------:|---------:|---------:|---------:|------------:|
|           Exclusión Óptima |    0.891 |   -0.415 |    0.733 |    0.361 |       0.964 |
| Alimentos y Energéticos 11 |    1.031 |   -0.611 |     0.87 |    0.466 |       0.969 |
|  Alimentos y Energéticos 9 |    1.981 |   -1.757 |    1.817 |    1.332 |        0.95 |
|                Energéticos |    4.148 |    1.359 |    2.257 |    1.855 |       0.771 |
"""
