
"""
    InflationTrimmedMeanEq <: InflationFunction
Función de inflación para computar la media truncada equiponderada
"""
Base.@kwdef struct InflationTrimmedMeanEq <: InflationFunction
    l1::Float32
    l2::Float32
end

# Métodos para crear funciones de inflación a partir de enteros
"""
    InflationTrimmedMeanEq(l1::Real,l2::Real)
Nos permite utilizar valores que no necesariamente son Float32, como enteros o Float64.

ejemplo: InflationTrimmedMeanEq(25,75.5)
"""
InflationTrimmedMeanEq(l1::Real,l2::Real) = InflationTrimmedMeanEq(l1 = Float32(l1), l2 = Float32(l2))

"""
    measure_name(inflfn::InflationTrimmedMeanEq)

Nos indica que medida se utiliza para una instancia.

ejemplo:  

julia> instancia = InflationTrimmedMeanEq(15.5,75.5); \\
julia> measure_name(instancia) \\
"Media Truncada Equiponderada (15.5 , 75.5)"
"""
measure_name(inflfn::InflationTrimmedMeanEq) = "Media Truncada Equiponderada (" * string(round(inflfn.l1, digits=2)) * " , " * string(round(inflfn.l2, digits=2)) * ")"

"""
    (inflfn::InflationTrimmedMeanEq)(base::VarCPIBase{T}) where T
Define cómo opera InflationTrimmedMeanEq sobre un objeto de tipo VarCPIBase.
"""
function (inflfn::InflationTrimmedMeanEq)(base::VarCPIBase{T}) where T 
    l1 = inflfn.l1
    l2 = inflfn.l2                                          
    leftPercentile,rightPercentile = min(l1,l2),max(l1,l2)   
    # determinanmos en donde tuncar                                 
    q1    = Int(ceil(length(base.w)*leftPercentile/100))                        
    q2    = Int(floor(length(base.w)*rightPercentile/100))                       
    outVec   = Vector{T}(undef,size(base.v)[1]) 
    # para cada t: ordenamos, truncamos y obtenemos la media.                      
    for i in 1:size(base.v)[1]                                      
        temporal    = base.v[i,:]                                      
        temporal    = sort(temporal)                                        
        temporal    = temporal[q1:q2]                                       
        outVec[i]  = mean(temporal)                                       
    end
    return outVec
end


