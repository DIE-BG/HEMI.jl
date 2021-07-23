# MovingAverageFunction.jl - Tipo para computar medias móviles de medidas de inflación

"""
    InflationMovingAverage{F <: InflationFunction} <: InflationFunction

Función de inflación que computa el promedio móvil de `k` períodos de la
trayectoria interanual de la medida de inflación `inflfn` almacenada. 

## Ejemplo

Para computar la media móvil de 6 meses de la variación interanual del IPC: 

```julia-repl 
julia> inflfn = InflationMovingAverage(InflationTotalCPI(), 6)
```
"""
struct InflationMovingAverage{F <: InflationFunction} <: InflationFunction
    inflfn::F
    periods::Int
end

# Método que opera sobre CountryStructure: computa la trayectoria de inflación
# con la función inflfn y luego computa el promedio móvil de k períodos
function (mafn::InflationMovingAverage)(cs::CountryStructure)
    
    # Cómputo usual de inflación
    tray_infl = mafn.inflfn(cs)
    
    # Algoritmo de promedio móvil 
    k = mafn.periods
    
    # Computar el promedio móvil (in-place)
    moving_average!(tray_infl, k)

    # Devolver la trayectoria de inflación
    tray_infl
end

# Actualmente, se define el resumen intermensual por el obtenido con la función
# de inflación interna
function (mafn::InflationMovingAverage)(base::VarCPIBase)
    mafn.inflfn(base)
end

# Función para computar el promedio móvil de la serie `v` con `k` períodos. Esta
# función modifica los elementos de `v` con el promedio móvil. 
function moving_average!(v, k)
    v # to-do...
end