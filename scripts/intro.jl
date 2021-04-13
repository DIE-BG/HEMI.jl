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

# Computar inflación de Guatemala
totalfn = TotalCPI()
tray_infl_gt = totalfn(gtdata)