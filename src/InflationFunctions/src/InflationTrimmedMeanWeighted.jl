"""
    InflationTrimmedMeanWeighted <: InflationFunction

Función de inflación para computar la media truncada ponderada

## Utilización
    function (inflfn::InflationTrimmedMeanWeighted)(base::VarCPIBase{T}) where T

Define cómo opera InflationTrimmedMeanWeighted sobre un objeto de tipo VarCPIBase.
"""
Base.@kwdef struct InflationTrimmedMeanWeighted <: InflationFunction
    l1::Float32
    l2::Float32
end

# Métodos para crear funciones de inflación a partir de enteros
"""
    InflationTrimmedMeanWeighted(l1::Real,l2::Real)
Nos permite utilizar valores que no necesariamente son Float32, como enteros o Float64.

# Ejemplo: 
```julia-repl
julia> mtfn = InflationTrimmedMeanWeighted(25,75.5)
(::InflationTrimmedMeanWeighted) (generic function with 5 methods)
```
"""
InflationTrimmedMeanWeighted(l1::Real,l2::Real) = InflationTrimmedMeanWeighted(l1 = Float32(l1), l2 = Float32(l2))

"""
    measure_name(inflfn::InflationTrimmedMeanWeighted)

Nos indica qué medida se utiliza para una instancia de una función de inflación.

# Ejemplo:  
```julia-repl
julia> mtfn = InflationTrimmedMeanWeighted(15.5,75.5)
julia> measure_name(mtfn)
"Media Truncada Ponderada (15.5 , 75.5)"
```
"""
function measure_name(inflfn::InflationTrimmedMeanWeighted) 
    l1 = string(round(inflfn.l1, digits=2))
    l2 = string(round(inflfn.l2, digits=2))
    "Media Truncada Ponderada (" * l1 * ", " * l2 * ")"
end

# Extendemos `params`, que devuelve los parámetros de la medida de inflación
CPIDataBase.params(inflfn::InflationTrimmedMeanWeighted) = (inflfn.l1, inflfn.l2)


# Operación de InflationTrimmedMeanWeighted sobre VarCPIBase para obtener el
# resumen intermensual de esta metodología
function (inflfn::InflationTrimmedMeanWeighted)(base::VarCPIBase{T}) where T     
    l1 = inflfn.l1
    l2 = inflfn.l2
    # l1 = min(inflfn.l1, inflfn.l2) 
    # l2 = max(inflfn.l1, inflfn.l2)  
    outVec   = Vector{T}(undef, periods(base))                         
    # para cada t: creamos parejas de variaciones con pesos,
    # ordenamos de acuerdo a variaciones, truncamos
    # renormalizamos para que los pesos sumen 1
    # sumamos el producto de variaciones con pesos

    # Número de gastos básicos
    g = size(base.v, 2)

    # Reservar la memoria para cómputos de media truncada 
    sort_ids = [zeros(Int, g) for _ in 1:Threads.nthreads()]
    w_sorted_list = [zeros(T, g) for _ in 1:Threads.nthreads()]
    w_sorted_renorm_list = [zeros(T, g) for _ in 1:Threads.nthreads()]

    Threads.@threads for i in 1:periods(base)
        
        # Obtener los vectores de cada hilo 
        j = Threads.threadid() 
        sort_idx = sort_ids[j]
        w_sorted_acum = w_sorted_list[j]
        w_sorted_renorm = w_sorted_renorm_list[j]

        # Obtener índices de orden en sort_idx
        v_month = @view base.v[i, :]
        sortperm!(sort_idx, v_month)

        # Acumular las ponderaciones en w_sorted_acum
        w_sorted = @view base.w[sort_idx]
        cumsum!(w_sorted_acum, w_sorted)

        # Poner a cero las ponderaciones fuera de límites 
        @inbounds for x in 1:g 
            if w_sorted_acum[x] < l1 || w_sorted_acum[x] > l2
                w_sorted_acum[x] = 0
            else
                w_sorted_acum[x] = 1
            end
        end

        # Renormalizar las ponderaciones dentro de los límites 
        w_sorted_renorm .= (w_sorted .* w_sorted_acum) 
        w_sorted_renorm ./= sum(w_sorted_renorm)

        # Computar promedio ponderado de variaciones dentro de límites
        @inbounds outVec[i] = sum((@view v_month[sort_idx]) .* w_sorted_renorm)
    end
    
    outVec
end
# Método para recibir argumentos en forma de tupla
InflationTrimmedMeanWeighted(factors::Tuple{Real, Real}) = InflationTrimmedMeanWeighted(
    convert(Float32, factors[1]), 
    convert(Float32, factors[2])
)

# Método para recibir argumentos en forma de vector
function InflationTrimmedMeanWeighted(factor_vec::Vector{<:Real})
    length(factor_vec) != 2 && return @error "Dimensión incorrecta del vector"
    InflationTrimmedMeanWeighted(
        convert(Float32, factor_vec[1]),
        convert(Float32, factor_vec[2])
    )
end



