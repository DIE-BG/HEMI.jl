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
using Plots 

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
    :inflfn => InflationFixedExclusionCPI.(v_exc[1:100]), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 100,
    :traindate => ff00,
) |> dict_list

savepath = datadir("results","optim","mse","Fx-Exc")  

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

MATLAB
Vector de Exclusión -> [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 Exclusiones)
MSE = 0.777

JULIA, con 10K simulaciones
Vector de Exclusión ->  [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 Exclusiones)
MSE = 0.7750067f0


"Cebolla"
"Tomate"
"Otras cuotas fijas y extraordinarias en la educaión preprimaria y primaria"
"Papa o patata"
"Zanahoria"
"Culantro o cilantro"
"Güisquil"
"Gastos derivados del gas manufacturado y natural y gases licuados del petróleo"
"Transporte aéreo"
"Otras verduras y hortalizas"
"Frijol"
"Gasolina"
"Otras cuotas fijas y extraordinarios en la educación secundaria"
"Transporte urbano"

"""

## Evaluación con 125_000 simulaciones al rededor del vector encontrado en la exploración inicial  (del 10 al 20)

FxEx_00 = Dict(
    :inflfn => InflationFixedExclusionCPI.(v_exc[10:20]), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 125_000
    :traindate => ff00) |> dict_list

savepath = datadir("results","Fx-Exc","Esc-A18","Base00-125K")  

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
Resultados de Evaluación de los vectores de exclusión 10 a 20 

MATLAB
Vector de Exclusión -> [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 Exclusiones)
MSE = 0.777

JULIA, con 10_000 simulaciones
Vector de Exclusión ->  [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 Exclusiones)
MSE = 0.7750067f0

JULIA, con 125_000 simulaciones
Vector de Exclusión ->  [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 Exclusiones)
MSE = 0.0.7729705f0

"""

#################  Optimización Base 2010  ###################################

# Vector óptimo base 2000 encontrado en la primera sección
exc00 =  [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] 

## Creación de vector de de gastos básicos ordenados por volatilidad, con información a Diciembre de 2018

est_10 = std(gtdata[Date(2018,12)][2].v |> capitalize |> varinteran, dims=1)

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
    :traindate => ff10) |> dict_list

savepath = datadir("results","Fx-Exc","Esc-A18","Base10-10K")  

## Lote de simulación con los primeros 100 vectores de exclusión

run_batch(gtdata, FxEx_10, savepath)

## Recolección de resultados
Exc_1018 = collect_results(savepath)

## Análisis de exploración preliminar
# obtener longitud del vector de exclusión de cada simulación
exclusiones =  getindex.(map(x -> length.(x), Exc_1018[!,:params]),1)
Exc_1018[!,:exclusiones] = exclusiones 

# Ordenamiento por cantidad de exclusiones
Exc_1018 = sort(Exc_1018, :exclusiones)

# DF ordenado por MSE
sort_1019 = sort(Exc_1018, :mse)

## Exctracción de vector de exclusión  y MSE
a = collect(sort_1019[1,:params])
sort_1019[1,:mse]


# Evaluación con 125_000 simulaciones al rededor del vector encontrado en la exploración inicial  (del 10 al 20)
FxEx_10 = Dict(
    :inflfn => InflationFixedExclusionCPI.(total[10:20]), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 125_000
    :traindate => ff10) |> dict_list

savepath = datadir("results","Fx-Exc","Esc-A18","Base10-125K")  

## Lote de simulación con los primeros 100 vectores de exclusión

run_batch(gtdata, FxEx_10, savepath)

## Recolección de resultados
Exc_1018 = collect_results(savepath)

## Análisis de exploración preliminar
# obtener longitud del vector de exclusión de cada simulación
exclusiones =  getindex.(map(x -> length.(x), Exc_1018[!,:params]),1)
Exc_1018[!,:exclusiones] = exclusiones 

# Ordenamiento por cantidad de exclusiones
Exc_1018 = sort(Exc_1018, :exclusiones)

# DF ordenado por MSE
sort_1018 = sort(Exc_1018, :mse)

## Exctracción de vector de exclusión  y MSE
a = collect(sort_1018[1,:params])
sort_1018[1,:mse]

##

fres = @chain Exc_1018 begin 
    sort(:mse)
    select(:mse, 
        :inflfn => ByRow(fn -> fn.v_exc[2]) => :excb10,
        :inflfn => ByRow(fn -> length(fn.v_exc[2])) => :excb10_length
    ) 
end

## 14 Gastos básicos a excluir en base 2010, a diciembre de 2018

# "Tomate"
# "Gas propano"
# "Chile pimiento"
# "Culantro"
# "Cebolla"
# "Papa"
# "Diesel"
# "Güisquil"
# "Lechuga"
# "Gasolina regular"
# "Servicio de transporte aéreo"
# "Repollo"
# "Otras legumbres y hortalizas"
# "Gasolina superior"
# 
# [29, 116, 31, 46, 39, 40, 186, 30, 35, 185, 197, 34, 48, 184]
