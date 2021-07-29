# ExpSmoothing.jl - Tipo para computar medias móviles 
# con suavizamiento exponencial de medidas de inflación

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
struct InflationExpSmoothing{F <: InflationFunction} <: InflationFunction
    inflfn::F
    alpha::Float64
end

# Método que opera sobre CountryStructure: computa la trayectoria de inflación
# con la función inflfn y luego computa el promedio móvil de k períodos
function (esfn::InflationExpSmoothing)(cs::CountryStructure)

    # Cómputo usual de inflación
    tray_infl = esfn.inflfn(cs)

    # Algoritmo de promedio móvil 
    k = esfn.alpha
    k == 1 && return tray_infl

    # Computar el promedio con suavizamiento exponencial (in-place)
    es_tray_infl = smoothing_exponential(tray_infl, k)

    # Devolver la trayectoria de inflación
    es_tray_infl
end

# Actualmente, se define el resumen intermensual por el obtenido con la función
# de inflación interna
# function (mafn::InflationMovingAverage)(base::VarCPIBase)
#     # Obtener resumen intermensual y aplicarle media móvil
#     vm = mafn.inflfn(base)
#     moving_average!(vm, mafn.periods)
#     vm
# end

# Función para computar el promedio con suavizamiento exponencial de la serie `v` con `k` como valor de suavizamiento 
# que pondera la historia 0<=k<=1.  
# Esta función modifica los elementos de `v` con el promedio de suavizmiento exponencial con lambda dada. 
# El tipo de suavizamiento que se utiliza es SES (Simple Exponential Smoothing, o Suavizamiento Exponencial Simple en español)

function smoothing_exponential(v, k)
    es = similar(v)
    es = reverse(es)
    es[1] = v[1]
    n = length(es)
    for j = 2:(n-1)
        a = j-1
        es[j] = es[j-1] + (v[j] - es[a])*k
    end
    es
end 
