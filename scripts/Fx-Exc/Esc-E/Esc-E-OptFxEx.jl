# Script con optimización y evaluación, con datos y configuración de simulación hasta 2019
"""
Escenario E
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
## Definición de parámetros de simulación
inflfn     = InflationPercentileEq(69)
resamplefn = ResampleSBB(36)
trendfn    = TrendRandomWalk()
paramfn    = InflationTotalRebaseCPI(60)
nsim       = 125_000
evaldate   = Date(2018,12)

# Configuración de simulación período Diciembre 2001 - Diciembre 2018
config = SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, evaldate)
"""

## Definición de instancias principales
trendfn    = TrendRandomWalk()
resamplefn = ResampleSBB(36)
paramfn    = InflationTotalRebaseCPI(60)

# Para optimización Base 2000
ff00 = Date(2010,12)
# Para optimización Base 2010
ff10 = Date(2018,12)

#################  Optimización Base 2000  ###################################
 
# Creación de vector de de gastos básicos ordenados por volatilidad.

estd = std(gt00.v |> capitalize |> varinteran, dims=1)

df = DataFrame(num = collect(1:218), Desv = vec(estd))

sorted_std = sort(df, "Desv", rev=true)

vec_v = sorted_std[!,:num]

# Creación de vectores de exclusión
# Se crean 218 vectores para la exploración inicial y se almacenan en v_exc
v_exc = []
for i in 1:length(vec_v)
   exc = vec_v[1:i]
   append!(v_exc, [exc])
end

# Diccionarios para exploración inicial (primero 100 vectores de exclusión)
FxEx_00 = Dict(
    :inflfn => InflationFixedExclusionCPI.(v_exc[1:150]), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 10_000,
    :traindate => ff00,  
    :evalperiods => (CompletePeriod(),)) |> dict_list

savepath = datadir("results","Fx-Exc","Esc-E","Base00-10K")  

## Lote de simulación con los primeros 100 vectores de exclusión

run_batch(gtdata, FxEx_00, savepath)


## Recolección de resultados
Exc_0019 = collect_results(savepath)

## Análisis de exploración preliminar
# obtener longitud del vector de exclusión de cada simulación
exclusiones =  getindex.(map(x -> length.(x), Exc_0019[!,:params]),1)
Exc_0019[!,:exclusiones] = exclusiones 

# Ordenamiento por cantidad de exclusiones
Exc_0019 = sort(Exc_0019, :exclusiones)

# DF ordenado por MSE
sort_0019 = sort(Exc_0019, :mse)

## Exctracción de vector de exclusión  y MSE
a = collect(sort_0019[1,:params])
sort_0019[1,:mse]

"""
Resultados de Exploración inicial 

[35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188]
"""
## Evaluación con 125_000 simulaciones al rededor del vector encontrado en la exploración inicial  (del 10 al 20)

FxEx_00 = Dict(
    :inflfn => InflationFixedExclusionCPI.(v_exc[10:35]), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 125_000,
    :traindate => ff00,  
    :evalperiods => (CompletePeriod(),)) |> dict_list

savepath = datadir("results","Fx-Exc","Esc-E","Base00-125K")  

## Lote de simulación con 10 vectores de exclusión 
run_batch(gtdata, FxEx_00, savepath)

## Recolección de resultados
Exc_0019 = collect_results(savepath)

## Análisis de exploración preliminar
# obtener longitud del vector de exclusión de cada simulación
exclusiones =  getindex.(map(x -> length.(x), Exc_0019[!,:params]),1)
Exc_0019[!,:exclusiones] = exclusiones 

# Ordenamiento por cantidad de exclusiones
Exc_0019 = sort(Exc_0019, :exclusiones)

# DF ordenado por MSE
sort_0019 = sort(Exc_0019, :mse)

## Exctracción de vector de exclusión  y MSE
a = collect(sort_0019[1,:params])
sort_0019[1,:mse]

"""
[35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188]
"""

#################  Optimización Base 2010  ###################################

# Vector óptimo base 2000 encontrado en la primera sección
exc00 = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188]

## Creación de vector de de gastos básicos ordenados por volatilidad, con información a Diciembre de 2019

est_10 = std(gtdata[2].v |> capitalize |> varinteran, dims=1)

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
    :traindate => ff10,  
    :evalperiods => (CompletePeriod(),)) |> dict_list

savepath = datadir("results","Fx-Exc","Esc-E","Base10-10K")  

## Lote de simulación con los primeros 100 vectores de exclusión

run_batch(gtdata, FxEx_10, savepath)

## Recolección de resultados
Exc_1019 = collect_results(savepath)

## Análisis de exploración preliminar
# obtener longitud del vector de exclusión de cada simulación
exclusiones =  getindex.(map(x -> length.(x), Exc_1019[!,:params]),1)
Exc_1019[!,:exclusiones] = exclusiones 

# Ordenamiento por cantidad de exclusiones
Exc_1019 = sort(Exc_1019, :exclusiones)

# DF ordenado por MSE
sort_1019 = sort(Exc_1019, :mse)

## Exctracción de vector de exclusión  y MSE
a = collect(sort_1019[1,:params])
sort_1019[1,:mse]

"""
[35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188]

[29, 46, 39, 31, 116]

"""

# Evaluación con 125_000 simulaciones al rededor del vector encontrado en la exploración inicial  (del 10 al 20)
FxEx_10 = Dict(
    :inflfn => InflationFixedExclusionCPI.(total[1:15]), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 125_000,
    :traindate => ff10,  
    :evalperiods => (CompletePeriod(),)) |> dict_list

savepath = datadir("results","Fx-Exc","Esc-E","Base10-125K")  

## Lote de simulación con los primeros 100 vectores de exclusión

run_batch(gtdata, FxEx_10, savepath)

## Recolección de resultados
Exc_1019 = collect_results(savepath)

## Análisis de exploración preliminar
# obtener longitud del vector de exclusión de cada simulación
exclusiones =  getindex.(map(x -> length.(x), Exc_1019[!,:params]),1)
Exc_1019[!,:exclusiones] = exclusiones 

# Ordenamiento por cantidad de exclusiones
Exc_1019 = sort(Exc_1019, :exclusiones)

# DF ordenado por MSE
sort_1019 = sort(Exc_1019, :mse)

## Exctracción de vector de exclusión  y MSE
a = collect(sort_1019[1,:params])
sort_1019[1,:mse]

"""
[[35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188], [29, 46, 39, 31, 116]]
"""