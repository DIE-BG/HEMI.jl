using DrWatson
@quickactivate "HEMI"

using Dates, TimeSeries, CPIDataBase

## Carga de base del IPC de prueba
gt_00 = CPIBase([Date(2010,12,1) + Month(i) for i in 1:120],
       rand(120, 279),
       [Symbol("GT", i) for i in 1:279],
       rand(279)/100)

# Mostrar base, problemas número columnas
gt_00

# Obtener ponderaciones
weights(gt_00)

# Computar IPC
values(gt_00) * weigths(gt_00)