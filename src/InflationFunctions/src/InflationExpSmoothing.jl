# ExpSmoothing.jl - Tipo para computar suavizamiento exponencial de medidas de inflación

"""
    InflationExpSmoothing{F <: InflationFunction} <: InflationFunction
Función de inflación que computa la inflación con decaimiento exponencial con el
parámetro ```\\alpha`` (el parámetro del decaimiento ) de la trayectoria
interanual dada por la medida de inflación `inflfn` almacenada. 

## Ejemplo

Para computar la inflación con decaimiento exponencial de la variación
interanual del IPC: 
```julia-repl 
julia> inflfn = InflationExpSmoothing(InflationTotalCPI(), 0.8)
(::InflationExpSmoothing{InflationTotalCPI}) (generic function with 5 methods)
```
"""
struct InflationExpSmoothing{F <: InflationFunction} <: InflationFunction
    inflfn::F
    alpha::Float64
end

# 2. Extender el método de nombre  
measure_name(esfn::InflationExpSmoothing) = "Suavizamiento exponencial con parámetro $(round(esfn.alpha, digits=4)) parámetros de " * measure_name(esfn.inflfn) 

# Función de parámetros 
CPIDataBase.params(esfn::InflationExpSmoothing) = (esfn.alpha, )


# Método de conveniencia para definir sobre parámetro de suavizamiento Enteros
InflationExpSmoothing(inflfn::InflationFunction,alpha::Int) =
    InflationExpSmoothing(inflfn::InflationFunction, convert(Float64,alpha))

# Método que opera sobre CountryStructure: computa la trayectoria de inflación
# con la función inflfn y luego computa el promedio con suavizamiento exponencial con el parámetro
# alpha (el parámetro del decaimiento )
function (esfn::InflationExpSmoothing)(cs::CountryStructure)

    # Cómputo usual de inflación
    tray_infl = esfn.inflfn(cs)

    # Algoritmo de promedio con suavizamiento exponencial
    k = esfn.alpha
    k == 1 && return tray_infl
    k == 0 && return ones(length(tray_infl))*tray_infl[1]

    # Computar el promedio con suavizamiento exponencial (in-place)
    es_tray_infl = smoothing_exponential(tray_infl, k)

    # Devolver la trayectoria de inflación
    es_tray_infl
end

# Actualmente, se define el resumen intermensual por el obtenido con la función
# de inflación interna
# function (mafn::InflationExpSmoothing)(base::VarCPIBase)
#     # Obtener resumen intermensual y aplicarle el suavizamiento exponencial
#     vm = mafn.inflfn(base)
#     vm
# end

# Función para computar el promedio con suavizamiento exponencial de la serie `v` con `k` 
# como valor de suavizamiento que pondera la historia 0<=k<=1.  
# Esta función modifica los elementos de `v` con el promedio de suavizmiento exponencial 
# con alpha dada. 
# El tipo de suavizamiento que se utiliza es SES (Simple Exponential Smoothing, o 
# Suavizamiento Exponencial Simple en español)

function smoothing_exponential(v, k)
    es = similar(v)
    n = length(es)
    es[1] = v[1]
    for j = 2:(n)
        es[j] = es[j-1] + (v[j] - es[(j-1)])*k
    end
    es 
end 
