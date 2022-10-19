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

data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")

# CARGANDO DATOS
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")
not_gt00 = NOT_GTDATA[1]
not_gt10 = NOT_GTDATA[2]

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

estd = std(not_gt00.v |> capitalize |> varinteran, dims=1)

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
    :evalperiods => GT_EVAL_B00
) |> dict_list

savepath = datadir("results","no_trans","optim","corr","Fx-Exc","B00")  

## Lote de simulación con los primeros 100 vectores de exclusión

run_batch(NOT_GTDATA, FxEx_00, savepath; savetrajectories=false)

## Recolección de resultados
Exc_0019 = collect_results(savepath)

## Análisis de exploración preliminar
# obtener longitud del vector de exclusión de cada simulación
exclusiones =  getindex.(map(x -> length.(x), Exc_0019[!,:params]),1)
Exc_0019[!,:exclusiones] = exclusiones 

# Ordenamiento por cantidad de exclusiones
Exc_0019 = sort(Exc_0019, :exclusiones)

# DF ordenado por CORR
sort_0019 = sort(Exc_0019, :gt_b00_corr, rev=true)

## Exctracción de vector de exclusión  y CORR
exc00 = collect(sort_0019[1,:params])

#[32, 8, 35, 17, 16, 18, 33, 30, 29, 28, 41, 5, 7]


#################  Optimización Base 2010  ###################################

# Vector óptimo base 2000 encontrado en la primera sección
exc00 =  [32, 8, 35, 17, 16, 18, 33, 30, 29, 28, 41, 5, 7] 

## Creación de vector de de gastos básicos ordenados por volatilidad, con información a Diciembre de 2018

est_10 = std(NOT_GTDATA[Date(2019,12)][2].v |> capitalize |> varinteran, dims=1)

df = DataFrame(num = collect(1:length(vec(est_10))), Desv = vec(est_10))

sorted_std = sort(df, "Desv", rev=true)

vec_v = sorted_std[!,:num]

# Creación de vectores de exclusión
# Se crearán 100 vectores para la exploración inicial
global v_exc = []
global tot = []
global total = []
for i in 1:length(vec_v)
   exc = vec_v[1:i]
   global v_exc =  append!(v_exc, [exc])
   global tot = (exc00, v_exc[i])
   global total = append!(total, [tot])
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

savepath = datadir("results","no_trans","optim","corr","Fx-Exc","B10")   

## Lote de simulación con los primeros 100 vectores de exclusión

run_batch(NOT_GTDATA, FxEx_10, savepath; savetrajectories=false)

## Recolección de resultados
Exc_1018 = collect_results(savepath)

## Análisis de exploración preliminar
# obtener longitud del vector de exclusión de cada simulación
exclusiones =  getindex.(map(x -> length.(x), Exc_1018[!,:params]),1)
Exc_1018[!,:exclusiones] = exclusiones 

# Ordenamiento por cantidad de exclusiones
Exc_1018 = sort(Exc_1018, :exclusiones)

# DF ordenado por CORR
sort_1019 = sort(Exc_1018, :corr, rev=true)

## Exctracción de vector de exclusión  y CORR
a = collect(sort_1019[1,:params])

# [32, 8, 35, 17, 16, 18, 33, 30, 29, 28, 41, 5, 7]
#    [
#        28, 42, 47, 64, 65, 6, 46, 63, 58, 41, 32, 37, 68, 20, 9,
#        30, 66, 59, 40, 24, 27, 12, 11, 34, 69, 60, 18, 21, 5, 56,
#        4, 2, 54, 57, 29, 38, 1, 67, 17, 52, 7, 15, 36, 31, 53,
#        16, 45, 26, 55, 35, 10, 19, 22, 13, 62, 44, 43
#    ]