# Script con optimización y evaluación, con datos y configuración de simulación hasta 2018

## carga de paquetes
using DrWatson
@quickactivate "HEMI"

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI
using CSV, DataFrames, Chain
#using Plots 

##

## Definición de instancias principales
trendfn    = TrendRandomWalk()
resamplefn = ResampleScrambleVarMonths()
paramfn    = InflationTotalRebaseCPI(36,2)

# Para optimización Base 2000
ff00 = Date(2010,12)
# Para optimización Base 2010
ff10 = Date(2019,12)

#################  Optimización Base 2000  ###################################
 
# Creación de vector de de gastos básicos ordenados por volatilidad.

estd = std(gt00.v |> capitalize |> varinteran, dims=1)

df = DataFrame(num = collect(1:length(vec(estd))), Desv = vec(estd))

sort!(df, :Desv, rev=true)

vec_v = df[!,:num]

# Creación de vectores de exclusión
# Se crean 218 vectores para la exploración inicial y se almacenan en v_exc
v_exc = []
for i in 1:length(vec_v)
   exc = vec_v[1:i]
   append!(v_exc, [exc])
end

# Diccionarios para exploración inicial (primero 100 vectores de exclusión)
FxEx_00 = Dict(
    :inflfn => InflationFixedExclusionCPI.(v_exc[1:30]), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 10_000,
    :traindate => ff00,
    :evalperiods => GT_EVAL_B00,
) |> dict_list

savepath = datadir("results","optim","me","Fx-Exc","B00")  

## Lote de simulación con los primeros 100 vectores de exclusión

run_batch(gtdata, FxEx_00, savepath; savetrajectories=false)

## Recolección de resultados
Exc_0019 = collect_results(savepath)

## Análisis de exploración preliminar
# obtener longitud del vector de exclusión de cada simulación
exclusiones =  getindex.(map(x -> length.(x), Exc_0019[!,:params]),1)
Exc_0019[!,:exclusiones] = exclusiones 

# Ordenamiento por cantidad de exclusiones
Exc_0019 = sort(Exc_0019, :exclusiones)

# DF ordenado por ME
sort_0019 = sort(Exc_0019, :gt_b00_absme)

## Exctracción de vector de exclusión  y ME
exc00 = collect(sort_0019[1,:params])

# [35, 30, 190, 36, 37, 40, 31, 104, 162]

#################  Optimización Base 2010  ###################################

# Vector óptimo base 2000 encontrado en la primera sección
exc00 =  [35, 30, 190, 36, 37, 40, 31, 104, 162] 

## Creación de vector de de gastos básicos ordenados por volatilidad, con información a Diciembre de 2019

est_10 = std(gtdata[Date(2019,12)][2].v |> capitalize |> varinteran, dims=1)

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
    :inflfn => InflationFixedExclusionCPI.(total[1:60]), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 10_000,
    :traindate => ff10
) |> dict_list

savepath = datadir("results","optim","me","Fx-Exc","B10")   

## Lote de simulación con los primeros 100 vectores de exclusión

run_batch(gtdata, FxEx_10, savepath; savetrajectories=false)

## Recolección de resultados
Exc_1018 = collect_results(savepath)

## Análisis de exploración preliminar
# obtener longitud del vector de exclusión de cada simulación
exclusiones =  getindex.(map(x -> length.(x), Exc_1018[!,:params]),1)
Exc_1018[!,:exclusiones] = exclusiones 

# Ordenamiento por cantidad de exclusiones
Exc_1018 = sort(Exc_1018, :exclusiones)

# DF ordenado por ME
sort_1019 = sort(Exc_1018, :absme)

## Exctracción de vector de exclusión  y ME
Exc = collect(sort_1019[1,:params])

#[35, 30, 190, 36, 37, 40, 31, 104, 162]
#[29, 31, 116, 39, 46, 40]
