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
gtdata_00 = gtdata[Date(2010, 12)]
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()

## BASE 2000 
## Cálculo de volatilidad histórica por gasto básico
# Volatilidad = desviación estándar de la variación interanual por cada gasto básico 

estd = std(varinteran(capitalize(gt00.v)), dims=1)

df = DataFrame(num = collect(1:218), Desv = vec(estd))

sorted_std = sort(df, "Desv", rev=true)

vec_v = sorted_std[!,:num]

# Creación de vectores de exclusión
# Se crearán 20 vectores para la exploración inicial
v_exc = []
for i in 1:length(vec_v)-1
   exc = vec_v[1:i]
   append!(v_exc, [exc])
end

v_exc

## Creación de diccionario para simulación y savepath
# Exploración inicial con 10000 simulaciones

FxEx_00 = Dict(
    :inflfn => InflationFixedExclusionCPI.(v_exc), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 125000) |> dict_list

savepath = datadir("fixed-exclusion","Base2000")    

## lote de simulación 

run_batch(gtdata_00, FxEx_00, savepath)

## resultados

dfExc_00 = collect_results(savepath)

# Para ordenamiento por cantidad de exclusiones 
exclusiones =  getindex.(map(x -> length.(x), dfExc_00[!,:params]),1)
dfExc_00[!,:exclusiones] = exclusiones 
# Ordenamiento por cantidad de exclusiones
dfExc_00 = sort(dfExc_00, :exclusiones)

# DF ordenado por MSE
sort_00 = sort(dfExc_00, :mse)

## Exctracción de vector de exclusión 
a = collect(sort_00[1,:params])
exc00 = a[1]
# a = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188]
# Menor MSE
sort_00[1,:mse]
#5.995067f0

## Revisión gráfica 
mseplot = plot(dfExc_00[!,:mse], 
    title = " Óptimización Base 2000",
    label = " MSE Exclusión fija Óptima Base 2000", 
    legend = :topleft, 
    xlabel= "Gastos Básicos Excluidos", ylabel = "MSE")

plot!([26],seriestype="vline", label = "Mínimo en 26 exclusiones")
# saveplot = plotsdir("fixed-exclusion","Base2000")    
savefig("plots//fixed-exclusion//mse-base2000")