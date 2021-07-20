# # Pruebas de desempeño sobre funciones de medias truncadas
using DrWatson
@quickactivate :HEMI 

# Cargar las funciones de inflación 
using InflationFunctions

# El paquete `BenchmarkTools` se utiliza para medir el desempeño de las
# funciones. Este ya se encuentra en las dependencias del proyecto, ya que es
# primordial que el código sea lo más eficiente posible. 
using BenchmarkTools


## Obtenemos la función de inflación a probar 
mtfn = InflationTrimmedMeanEq(15, 95.5)


# ## Revisión de estabilidad de tipo 

# Para ver que el código sea lo más eficiente posible, debe ser estable en tipo: 
@code_warntype mtfn(gt00)
# La implementación actual parece estar bien en este respecto. También podemos
# ver que efectivamente sea óptima sobre CountryStructure: 
@code_warntype mtfn(gtdata)

# Y también está bastante bien. 


# ## Prueba de desempeño con implementación DJGM

# Probamos el tiempo y alojamiento de memoria para el método sobre VarCPIBase: 
@btime mtfn($gt00); 
## 603.400 μs (362 allocations: 332.50 KiB)

# No está mal, está operando más rápido que las funciones de percentiles.
# Probemos hacer algunos cambios en la implementación.

# ## Prueba con algunas mejoras en el algoritmo
# Al cambiar el algoritmo para reducir el alojamiento de memoria tenemos: 

@btime mtfn($gt00); 
## 594.400 μs (122 allocations: 118.75 KiB)

# Aunque hay una ligera mejora en tiempo, al reducir la utilización de memoria a
# ≈1/3, el algoritmo es más eficiente al ser llamado N-mil veces. 

# ## Prueba con dos hilos
# Al cambiar el algoritmo para utilizar dos hilos, se obtiene una considerable mejora.

@btime mtfn($gt00); 
## 285.100 μs (492 allocations: 131.08 KiB)


# ## Pruebas sobre InflationTrimmedMeanWeighted
# to-do...

# Obtenemos una función de inflación con recortes ponderados
mtwfn = InflationTrimmedMeanWeighted(15, 97)

@btime mtwfn(gt00); 
## 1.166 ms (1681 allocations: 1.75 MiB)
# 2.576 ms (1561 allocations: 1.07 MiB) - últimos cambios @djgabrielm 
# 1.979 ms (1201 allocations: 857.44 KiB) - con pequeñas mejoras 
# 992.800 μs (1211 allocations: 858.56 KiB) - dos hilos 
# 1.980 ms (1081 allocations: 739.31 KiB) - otra pequeña mejora 
# 987.500 μs (1091 allocations: 740.44 KiB) - con dos hilos 
# 838.900 μs (500 allocations: 144.91 KiB) - prueba mas reciente

# mejorar un poco esta implementación 