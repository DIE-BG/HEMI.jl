## ## Carga de Paquetes
using DrWatson
@quickactivate "HEMI"

using HEMI
using InflationFunctions
using Test
using BenchmarkTools


## ## Pruebas para función de Exclusión Fija

### Prueba Inicial
# ### Vectores de exclusión aleatorios para prueba
v_exc00 = [35,30,190,36,37,40,31,104,162,32,33,159,193,161,218]
v_exc10 = [25, 40, 45, 50, 55, 70, 75, 80, 85, 275, 279]

fxEx = InflationFixedExclusionCPI(v_exc00, v_exc10)
fxEx(gt10,2)
fxEx(gt00,1)
fxEx(gtdata)

# ### Exclusión óptima DIE 2020
#  Vectores de exclsión óptimos según Evaluación 2020.
excOpt00 = [35,30,190,36,37,40,31,104,162,32,33,159,193,161]
excOpt10 = [29,31,116,39,46,40,30,35,186,47,197,41,22,48,185,34,184]

fxEx = InflationFixedExclusionCPI(excOpt00, excOpt10)
fxEx(gt10,2)
fxEx(gt00,1)
fxEx(gtdata)

## ## Exclusión Alimentos y Energéticos
AEExc_00 = vcat(collect(23:41), 104, 159)
AEExc_10 = vcat(collect(22:48), 116, collect(184:186))

fxEx = InflationFixedExclusionCPI(AEExc_00, AEExc_10)
fxEx(gt10,2)
fxEx(gt00,1)
fxEx(gtdata)

## ## Exclusión solo energéticos
EExc_00 = [104, 159]
EExc_10 = vcat(116, collect(184:186))

fxEx = InflationFixedExclusionCPI(EExc_00, EExc_00)
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
