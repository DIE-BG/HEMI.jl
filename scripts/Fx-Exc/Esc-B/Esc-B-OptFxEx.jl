# Script con optimización y evaluación, con datos y configuración de simulación hasta 2019
"""
Escenario B: extender el trabajo efectuado en 2020 (criterios básicos a dic-20)

Este escenario pretende evaluar las medidas de inflación utilizando la información hasta diciembre de 2020, utilizando los mismos parámetros de configuración que en el escenario A.

Los parámetros de configuración en este caso son los siguientes:

- Período de Evaluación: Diciembre 2001 - Diciembre 2020, ff = Date(2020, 12).
- Trayectoria de inflación paramétrica con cambio de base sintético: 2 cambios de base cada 3 años, [InflationTotalRebaseCPI(36, 2)].
- Método de remuestreo de extracciones estocásticas independientes (Remuestreo por meses de ocurrencia), [ResampleScrambleVarMonths()].
- Muestra completa para evaluación, [SimConfig].

Nota: Se llevará a cabo la optimización de la exclusión de la base 2010.

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
##
"""
Resultados de Evaluación 2019 con Matlab

Vectores de Exclusión 
Base 2000: [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 Exclusiones)
MSE = 0.777
No se optimiza.

Base 2010 -> [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184] (17 exclusiones)
MSE = 0.64

Número de simulaciones 
nsim: 10_000, para los primeros 100 vectores de Exclusión
nsim: 125_000, para un rango localizado de exclusiones al rededor de la exploración inicial 

"""

## Definición de instancias principales
trendfn    = TrendRandomWalk()
resamplefn = ResampleScrambleVarMonths()
paramfn    = InflationTotalRebaseCPI(36,2)
ff         = Date(2020,12)

#################  Optimización Base 2010  ###################################

# Vector óptimo base 2000 encontrado en el Escenario A (y en Matlab)
exc00 =  [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] 

## Creación de vector de de gastos básicos ordenados por volatilidad, con información a Diciembre de 2019
gtdata_10 = gtdata[Date(2020,12)]

est_10 = std(gtdata_10[2].v |> capitalize |> varinteran, dims=1)

df = DataFrame(num = collect(1:279), Desv = vec(est_10))

sorted_std = sort(df, "Desv", rev=true)

vec_v = sorted_std[!,:num]

# Creación de vectores de exclusión
# Se crearán 100 vectores para la exploración inicial
v_exc = []
tot = []
total = []
for i in 1:length(vec_v)
   exc = vec_v[1:i]
   v_exc =  append!(v_exc, [exc])
   tot = (exc00, v_exc[i])
   total = append!(total, [tot])
end
total

# Diccionarios para exploración inicial (primero 100 vectores de exclusión)
FxEx_10 = Dict(
    :inflfn => InflationFixedExclusionCPI.(total[1:100]), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 10_000,
    :traindate => ff) |> dict_list

savepath = datadir("results","Fx-Exc","Esc-B","B10-10K")  

## Lote de simulación con los primeros 100 vectores de exclusión

run_batch(gtdata, FxEx_10, savepath)

## Recolección de resultados
Exc_1020 = collect_results(savepath)

## Análisis de exploración preliminar
# obtener longitud del vector de exclusión de cada simulación
exclusiones =  getindex.(map(x -> length.(x), Exc_1020[!,:params]),1)
Exc_1020[!,:exclusiones] = exclusiones 

# Ordenamiento por cantidad de exclusiones
Exc_1020 = sort(Exc_1020, :exclusiones)

# DF ordenado por MSE
sort_1020 = sort(Exc_1020, :mse)

## Exctracción de vector de exclusión  y MSE
a = collect(sort_1020[1,:params])
sort_1020[1,:mse]

"""
Resultados de Evaluación de exploración con 10_000 simulaciones para los 100 primeros vectores de exlcusión

MATLAB Date(2019, 12)
Base 2000 -> [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 Exclusiones)
Base 2010 -> [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184] (17 exclusiones)
MSE = 0.64

JULIA Date(2020, 12), con 10_000 simulaciones
Base 2000 -> [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 Exclusiones)
Base 2010 -> [29, 46, 39, 31, 116, 40, 30, 186, 35, 47, 197, 41, 22, 185, 48, 34, 37, 184] (18 exclusiones)
MSE = 0.647326f0

"""

# Evaluación con 125_000 simulaciones al rededor del vector encontrado en la exploración inicial  (del 10 al 20)
FxEx_10 = Dict(
    :inflfn => InflationFixedExclusionCPI.(total[10:25]), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 125_000,
    :traindate => ff) |> dict_list

savepath = datadir("results","Fx-Exc","Esc-B","B10-125K")  

## Lote de simulación con los primeros 100 vectores de exclusión

run_batch(gtdata, FxEx_10, savepath)

## Recolección de resultados
Exc_1020 = collect_results(savepath)

# obtener longitud del vector de exclusión de cada simulación
exclusiones =  getindex.(map(x -> length.(x), Exc_1020[!,:params]),1)
Exc_1020[!,:exclusiones] = exclusiones 

# Ordenamiento por cantidad de exclusiones
Exc_1020 = sort(Exc_1020, :exclusiones)

# DF ordenado por MSE
sort_1020 = sort(Exc_1020, :mse)

## Exctracción de vector de exclusión  y MSE
a = collect(sort_1020[1,:params])
sort_1020[1,:mse]

"""
Resultados de Evaluación con 125_000 simulaciones para los vectores de exlcusión 10 a 25

MATLAB Date(2019, 12)
Base 2000 -> [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 Exclusiones)
Base 2010 -> [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184] (17 exclusiones)
MSE = 0.64

JULIA Date(2020, 12), con 10_000 simulaciones
Base 2000 -> [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 Exclusiones)
Base 2010 -> [29, 46, 39, 31, 116, 40, 30, 186, 35, 47, 197, 41, 22, 185, 48, 34, 37, 184] (18 exclusiones)
MSE = 0.647326f0

JULIA Date(2020, 12), con 125_000 simulaciones
Base 2000 -> [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 Exclusiones)
Base 2010 -> [29, 46, 39, 31, 116, 40, 30, 186, 35, 47, 197, 41, 22, 185, 48, 34, 37, 184] (18 exclusiones)
MSE = 0.6460847f0

"""