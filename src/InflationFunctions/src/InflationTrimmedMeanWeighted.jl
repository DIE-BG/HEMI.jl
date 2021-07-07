"""
    InflationTrimmedMeanWeighted <: InflationFunction
Función de inflación para computar la media truncada ponderada

## Utilización
    (inflfn::InflationTrimmedMeanWeighted)(base::VarCPIBase{T}) where T
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

Nos indica que medida se utiliza para una instancia de una función de inflación.

# Ejemplo:  
```julia-repl
julia> mtfn = InflationTrimmedMeanWeighted(15.5,75.5)
julia> measure_name(mtfn)
"Media Truncada Ponderada (15.5 , 75.5)"
```
"""
measure_name(inflfn::InflationTrimmedMeanWeighted) = "Media Truncada Ponderada (" * string(round(inflfn.l1, digits=2)) * " , " * string(round(inflfn.l2, digits=2)) * ")"


function (inflfn::InflationTrimmedMeanWeighted)(base::VarCPIBase{T}) where T     
    l1 = inflfn.l1
    l2 = inflfn.l2                                                                          
    # determinamos donde truncar
    q1    = Int(ceil(length(base.w)*min(l1,l2)/100))                       
    q2    = Int(floor(length(base.w)*max(l1,l2)/100))                       
    outVec   = Vector{T}(undef,periods(base))                         
    # para cada t: creamos parejas de variaciones con pesos,
    # ordenamos de acuerdo a variaciones, truncamos
    # renormalizamos para que los pesos sumen 1
    # sumamos el producto de variaciones con pesos
    for i in 1:periods(base)                                     
        temporal        = hcat((@view base.v[i,:]),base.w)                      
        temporal        = temporal[sortperm(temporal[:,1]),:]                    
        temporal        = @view temporal[q1:q2,:]                                 
        temporal[:,2]   = temporal[:,2] .* 1/sum(temporal[:,2])                 
        outVec[i]       = sum(temporal[:,1] .* temporal[:,2])                   
    end
    return outVec
end 

