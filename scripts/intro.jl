using DrWatson
@quickactivate "HEMI"

## Script de lectura de datos de CSV ✔
# Trabajar en los tipos para representar los datos ✔
# Funciones básicas de índices y variaciones
# Función básica para variación interanual del IPC con varias bases
# ... (mucho más)

using Dates, CPIDataBase
using JLD2

@load datadir("guatemala", "gtdata.jld2") gt00 gt10

gtdata = CountryStructure(gt00, gt10)