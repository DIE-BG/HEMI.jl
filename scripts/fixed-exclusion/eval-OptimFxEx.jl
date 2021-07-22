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

sorted_std[!,:num]
