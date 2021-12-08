# MovingAverageFunction.jl - Tipo para computar medias móviles de medidas de inflación

"""
    InflationMovingAverage{F <: InflationFunction} <: InflationFunction
Función de inflación que computa el promedio móvil de `k` períodos de la
trayectoria interanual de la medida de inflación `inflfn` almacenada. 

## Ejemplo

Para computar la media móvil de 6 meses de la variación interanual del IPC: 
```julia-repl 
julia> inflfn = InflationMovingAverage(InflationTotalCPI(), 6)
(::InflationMovingAverage{InflationTotalCPI}) (generic function with 5 methods)
```
"""
struct InflationMovingAverage{F <: InflationFunction} <: InflationFunction
    inflfn::F
    periods::Int
end

# 2. Extender el método de nombre 
measure_name(mafn::InflationMovingAverage) = "Promedios Móvil de $(mafn.periods) períodos de " * measure_name(mafn.inflfn)

# Método que opera sobre CountryStructure: computa la trayectoria de inflación
# con la función inflfn y luego computa el promedio móvil de k períodos
function (mafn::InflationMovingAverage)(cs::CountryStructure)

    # Cómputo usual de inflación
    tray_infl = mafn.inflfn(cs)

    # Algoritmo de promedio móvil 
    k = mafn.periods
    k == 1 && return tray_infl

    # Computar el promedio móvil (in-place)
    ma_tray_infl = moving_average(tray_infl, k)

    # Devolver la trayectoria de inflación
    ma_tray_infl
end

# Actualmente, se define el resumen intermensual por el obtenido con la función
# de inflación interna
# function (mafn::InflationMovingAverage)(base::VarCPIBase)
#     # Obtener resumen intermensual y aplicarle media móvil
#     vm = mafn.inflfn(base)
#     moving_average!(vm, mafn.periods)
#     vm
# end

# Función para computar el promedio móvil de la serie `v` con `k` períodos. Esta
# función modifica los elementos de `v` con el promedio móvil. 
function moving_average(v, k)
    ma = similar(v)
    ma[1] = v[1]
    for j = 2:k-1
        ma[j] = mean(@view v[1:j])
    end
    for t = k:length(v)
        ma[t] = mean(@view v[t-k+1:t])
    end    

    ma
end 
