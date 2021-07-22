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
using Plots

"""
ref: https://github.com/DIE-BG/EMI/blob/master/%2BEMI/%2Bexclusion_fija/exclusion_alternativas.m
1. Evaluación de medidas de exclusión fija 
 - DIE Exclusión óptima
Procedimiento general:
 - Base 2000
  - Definición de volatilidad para los 218 gastos básicos
  - Ordenamiento de mayor a menor
  - Proceso de optimización (desde 1 hasta N con menor MSE)
 - Base completa
  - Una vez optimizada la base 2000, se procede con el mismo procedimiento para la base completa, optimizando el 
    vector de exclusión de la base 2010, dejando fijo el de la base 2000 encontrado en la primera sección.

Vectores de exclusión actuales

Base 2000: [35,30,190,36,37,40,31,104,162,32,33,159,193,161]
Base 2010: [29,31,116,39,46,40,30,35,186,47,197,41,22,48,185,34,184]} 

"""

## Instancias generales
gtdata_00 = gtdata[Date(2010, 12)]
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()

## BASE 2000 
## Cálculo de volatilidad histórica por gasto básico
# Volatilidad = desviación estándar de la variación intermensual por cada gasto básico 


estd = std(gtdata_00[1].v, dims=1)

df = DataFrame(num = collect(1:218), Desv = vec(estd))

sorted_std = sort(df, "Desv", rev=true)

vec_v = sorted_std[!,:num]

# Creación de vectores de exclusión
# Se crearán 20 vectores para la exploración inicial
v_ecx = []
for i in 1:50#length(vec_v)
   exc = vec_v[1:i]
   v_exc = append!(v_ecx, [exc])
end


## Creación de diccionario para simulación y savepath
# Exploración inicial con 10000 simulaciones

FxEx_00 = Dict(
    :inflfn => InflationFixedExclusionCPI.(v_exc), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 10000) |> dict_list

savepath = datadir("fixed-exclusion","Base2000")    

## lote de simulación 

run_batch(gtdata_00, FxEx_00, savepath)

## resultados

dfExc_00 = collect_results(savepath)

sort_00 = sort(dfExc_00, "mse")

scatter(1:length(v_exc), dfExc_00.mse, 
    ylims = (0, 15),
    label = " MSE Exclusión fija Óptima Base 2000", 
    legend = :topleft, 
    xlabel= "Longitud del vector de exclusión", ylabel = "MSE")
