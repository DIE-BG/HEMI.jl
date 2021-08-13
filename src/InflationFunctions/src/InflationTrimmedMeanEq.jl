
"""
    InflationTrimmedMeanEq <: InflationFunction

Función de inflación para computar la media truncada equiponderada

## Utilización
    function (inflfn::InflationTrimmedMeanEq)(base::VarCPIBase{T}) where T

Define cómo opera InflationTrimmedMeanEq sobre un objeto de tipo VarCPIBase.

### Ejemplo 
```julia-repl
julia> mtfn = InflationTrimmedMeanEq(25, 75.5)
(::InflationTrimmedMeanEq) (generic function with 5 methods)
julia> mtfn(gt00) # gt00 es de tipo VarCPIBase
120-element Vector{Float32}:
 1.3350569
 0.81459785
 0.5427902
 0.44377768
 0.3310551
 0.6161327
 ⋮
 0.284297
 0.20947386
 0.298732
 0.25540668
 0.2260508
 0.3456037
```
"""
Base.@kwdef struct InflationTrimmedMeanEq <: InflationFunction
    l1::Float32
    l2::Float32
end


# Métodos para crear funciones de inflación a partir de enteros
"""
    InflationTrimmedMeanEq(l1::Real,l2::Real)
Nos permite utilizar recortes que no necesariamente son de tipos de punto flotante, como por ejemplo: enteros, fracciones, Float32 y Float64.

# Ejemplo: 
```julia-repl
julia> mtfn = InflationTrimmedMeanEq(25, 75.5)
(::InflationTrimmedMeanEq) (generic function with 5 methods)
```
"""
function InflationTrimmedMeanEq(l1::Real,l2::Real) 
    # Obtener los recortes adecuados en tiempo de construcción
    InflationTrimmedMeanEq(Float32(l1), Float32(l2))
end

"""
    measure_name(inflfn::InflationTrimmedMeanEq)

Nos indica qué medida se utiliza para una instancia de una función de inflación.

# Ejemplo:  

```julia-repl
julia> mtfn = InflationTrimmedMeanEq(15.5,75.5)
julia> measure_name(mtfn) 
"Media Truncada Equiponderada (15.5 , 75.5)"
```
"""
function measure_name(inflfn::InflationTrimmedMeanEq) 
    l1 = string(round(inflfn.l1, digits=2))
    l2 = string(round(inflfn.l2, digits=2))
    "Media Truncada Equiponderada (" * l1 * ", " * l2 * ")"
end

# Extendemos `params`, que devuelve los parámetros de la medida de inflación
CPIDataBase.params(inflfn::InflationTrimmedMeanEq) = (inflfn.l1, inflfn.l2)


# Operación de InflationTrimmedMeanEq sobre VarCPIBase para obtener el resumen
# intermensual de esta metodología
function (inflfn::InflationTrimmedMeanEq)(base::VarCPIBase{T}) where T 
    # Obtener los percentiles de recorte 
    l1 = inflfn.l1
    l2 = inflfn.l2
    # l1 = min(inflfn.l1, inflfn.l2) 
    # l2 = max(inflfn.l1, inflfn.l2)                                          
    
    # Determinamos en dónde truncar
    q1      = Int(ceil(length(base.w) * l1 / 100))                        
    q2      = Int(floor(length(base.w) * l2 / 100))                       
    outVec  = Vector{T}(undef, periods(base)) 
    
    if q1 == 0
        q1 = 1
    end

    # para cada t: ordenamos, truncamos y obtenemos la media.                      
    Threads.@threads for i in 1:periods(base)

        # Creamos una vista de cada fila: ahora temporal almacena una referencia
        # a la fila de base.v, sin crear nueva memoria
        temporal = @view base.v[i,:]
        # Ordenamos el vector y almacenamos en uno nuevo: `sorted_data`
        sorted  = sort(temporal)
        
        # No es necesario generar esta asignación porque la función mean puede
        # acceder a una vista del arreglo entre las posiciones q1 y q2, sin
        # alojar nueva memoria
        # temporal    = temporal[q1:q2]
        
        # Por lo que la siguiente operación es la de obtener el promedio entre
        # dichas posiciones, sin reservar nueva memoria
        @inbounds outVec[i]  = mean(@view sorted[q1:q2])                                         
    end
    return outVec
end 


# Método para recibir argumentos en forma de tupla
InflationTrimmedMeanEq(factors::Tuple{Real, Real}) = InflationTrimmedMeanEq(
    convert(Float32, factors[1]), 
    convert(Float32, factors[2])
)

# Método para recibir argumentos en forma de vector
function InflationTrimmedMeanEq(factor_vec::Vector{<:Real})
    length(factor_vec) != 2 && return @error "Dimensión incorrecta del vector"
    InflationTrimmedMeanEq(
        convert(Float32, factor_vec[1]),
        convert(Float32, factor_vec[2])
    )
end
