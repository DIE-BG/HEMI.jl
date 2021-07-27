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
ref: https://github.com/DIE-BG/EMI/blob/master/%2BEMI/%2Bexclusion_fija/exclusion_alternativas.m
1. Evaluación de medidas de exclusión fija 
 - Exclusión óptima
Procedimiento general:
 - Base 2000
  - Definición de volatilidad para los 218 gastos básicos
  - Ordenamiento de mayor a menor
  - Proceso de optimización (desde 1 hasta N con menor MSE)
 - Base completa
  - Una vez optimizada la base 2000, se procede con el mismo procedimiento para la base completa, optimizando el 
    vector de exclusión de la base 2010, dejando fijo el de la base 2000 encontrado en la primera sección.

Vectores de exclusión Evaluación 2019

Base 2000: [35,30,190,36,37,40,31,104,162,32,33,159,193,161]
Base 2010: [29,31,116,39,46,40,30,35,186,47,197,41,22,48,185,34,184]} 

"""

## Instancias generales
gtdata_10 = gtdata[Date(2020, 12)]
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()

# Vector de exclusión óptimo para base 2000
v_exc00 = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188]

## BASE 2010 
## Cálculo de volatilidad histórica por gasto básico
# Volatilidad = desviación estándar de la variación interanual por cada gasto básico 

est_b = std(gt10.v |> capitalize |> varinteran, dims=1)

df = DataFrame(num = collect(1:279), Desv = vec(estd))

sorted_std = sort(df, "Desv", rev=true)

vec_v = sorted_std[!,:num]

# Creación de vectores de exclusión
# Se crearán 278 vectores para la exploración inicial

v_exc = []
tot = []
total = []
for i in 1:length(vec_v)-1
   exc = vec_v[1:i]
   v_exc =  append!(v_exc, [exc])
   tot = (v_exc00, v_exc[i])
   total = append!(total, [tot])
end

## Creación de diccionario para simulación y savepath
# Exploración inicial con 10000 simulaciones

FxEx_00 = Dict(
    :inflfn => InflationFixedExclusionCPI.(total), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 125000) |> dict_list

savepath = datadir("fixed-exclusion","Base2010-125K")    

## lote de simulación 

run_batch(gtdata_10, FxEx_00, savepath)

## resultados

dfExc_10 = collect_results(savepath)

# Para ordenamiento por cantidad de exclusiones 
exclusiones =  getindex.(map(x -> length.(x)[2], dfExc_10[!,:params]),1)
dfExc_10[!,:exclusiones] = exclusiones 
# Ordenamiento por cantidad de exclusiones
dfExc_10 = sort(dfExc_10, :exclusiones)

# DF ordenado por MSE
sort_10 = sort(dfExc_10, :mse)

## Exctracción de vector de exclusión 
a = collect(sort_10[1,:params])
exc10 = a[2]
# a = [29, 46, 39, 31, 116]
# Menor MSE
sort_10[1,:mse]
# 4.2655616f0 con 10,000 ([29, 46, 39, 31, 116])
# 4.254165f0 con 125,000 ([29, 46, 39, 31, 116])
# 5.093933f0 con vector de exclusión 2000 sin cambios respecto de evaluación 2019. ([29, 46, 39, 31, 116])


mseplot = plot(dfExc_10[1:50,:mse], 
    title = " Óptimización Base 2010",
    label = " MSE Exclusión fija Óptima Base 2010", 
    legend = :topleft, 
    xlabel= "Gastos Básicos Excluidos", ylabel = "MSE")

plot!([5],seriestype="vline", label = "Mínimo en 5 exclusiones")
# saveplot = plotsdir("fixed-exclusion","Base2000")    
savefig("plots//fixed-exclusion//mse-base2010")

## Trayectoria óptima

fxExOpt = InflationFixedExclusionCPI(v_exc00, a)
FxEx = fxExOpt(gtdata)

tray = plot(FxEx)