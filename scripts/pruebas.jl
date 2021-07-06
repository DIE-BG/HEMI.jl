using DrWatson
@quickactivate "HEMI"

using HEMI
using InflationFunctions
using Test
using BenchmarkTools


## 
v_exc00 = [35,30,190,36,37,40,31,104,162,32,33,159,193,161,218]
v_exc10 = [25, 40, 45, 50, 55, 70, 75, 80, 85, 275, 279]

##
fxEx = InflationFixedExclusionCPI(v_exc00, v_exc10)
fxEx(gt10,2)
fxEx(gt00,1)
fxEx(gtdata)



## Pruebas
# Estable en tipo sobre VarCPIBase?
@code_warntype fxEx(gt10,2)
# Sobre CS?
@code_warntype fxEx(gtdata)

# Tiempo y memoria de ejecución?
@btime fxEx($gtdata)
@btime fxEx($gt00,1) 
