using DrWatson
@quickactivate "HEMI"

## TODO 
# Script de lectura de datos de CSV ✔
# Trabajar en los tipos para representar los datos ✔
# Funciones básicas de índices y variaciones ✔
# Función básica para variación interanual del IPC con varias bases ✔
# Simulación básica en serie con replicación y benchmark vs MATLAB
# Simulación en paralelo con replicación y benchmark vs MATLAB
# Agregar funciones de inflación adicionales
# ... (mucho más)

using Dates, CPIDataBase
using JLD2

@load datadir("guatemala", "gtdata.jld2") gt00 gt10

const gtdata = CountryStructure(gt00, gt10)

## Computar inflación de Guatemala

fgt00 = convert(Float32, gt00) 
fgt10 = convert(Float32, gt10) 
gtdata32 = CountryStructure(fgt00, fgt10)

totalfn = TotalCPI()
tray_infl_gt = totalfn(gtdata)

# 102.300 μs (13 allocations: 239.78 KiB)


## Inplace intermediate

fgt00 = convert(Float32, gt00) 
fgt10 = convert(Float32, gt10) 
gtdata32 = CountryStructure(fgt00, fgt10)

totalfn_in = CPIDataBase.TotalEvalCPI()
totalfn_in(gtdata32)

# 92.100 μs (11 allocations: 4.52 KiB)

# + el tiempo de copiado para el muestreo: se está copiando todo, hasta 
# los vectores de ponderaciones, por eso la suma es mayor
# julia> @btime deepcopy($gtdata32);
#   23.100 μs (23 allocations: 238.75 KiB)


## Inplace extreme reutilization of memory

totalfn_in = CPIDataBase.TotalExtremeCPI()
tray_infl_gt = zeros(Float32, sum(size(b.v, 1) for b in gtdata.base))

fgt00 = convert(Float32, gt00) 
fgt10 = convert(Float32, gt10) 
gtdata32 = CountryStructure(fgt00, fgt10)
totalfn_in(tray_infl_gt, gtdata32)
tray_infl_gt

# 92.000 μs (6 allocations: 384 bytes)
# 89.800 μs (6 allocations: 384 bytes)
# Sí es el método más rápido
# Aunque, al parecer, no siempre es bueno hacer todo in-place, la ganancia es de alrededor de 
# 10μs respecto al método más sencillo, pero se mueve muchísima menos memoria 