# Script con optimización y evaluación, con datos y configuración de simulación hasta 2019
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
Base 2000: [35,30,190,36,37,40,31,104,162,32,33,159,193,161] (14 Exclusiones)
MSE = 0.777
Base 2010 -> [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184] (17 exclusiones)
MSE = 0.64

Configuración de Simulación:

Función de inflación (inflfn): InflationFixedExclusionCPI()
Función de tendencia (trendfn): TrendRandomWalk()
Función de remuestreo (resamplefn): ResampleScrambleVarMonths() 
Inflación de Evaluación (paramfn): InflationTotalRebaseCPI(36, 2)

Número de simulaciones 
nsim: 10_000, para los primeros 100 vectores de Exclusión
nsim: 125_000, para un rango localizado de exclusiones al rededor de la exploración inicial 
addprocs
"""

## Definición de instancias principales
trendfn    = TrendRandomWalk()
resamplefn = ResampleScrambleVarMonths()
paramfn    = InflationTotalRebaseCPI(36,2)

# Para optimización Base 2000
gtdata_00 = gtdata[Date(2010, 12)]
# Para optimización Base 2010
gtdata_10 = gtdata[Date(2019, 12)]

## Optimización Base 2000
 
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
    :inflfn => InflationFixedExclusionCPI.(v_exc[1:100]), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 10_000) |> dict_list

savepath = datadir("results","fixed-exclusion","Eval-19","Base2000-ExpInicial")  


## Lote de simulación con 100 vectores de exclusión

run_batch(gtdata_00, FxEx_00, savepath)