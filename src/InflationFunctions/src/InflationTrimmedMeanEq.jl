
"""
    InflationTrimmedMeanEq <: InflationFunction
Función de inflación para computar la media truncada equiponderada
"""
Base.@kwdef struct InflationTrimmedMeanEq <: InflationFunction
    l1::Float32
    l2::Float32
end

# Métodos para crear funciones de inflación a partir de enteros
InflationTrimmedMeanEq(l1::Real,l2::Real) = InflationTrimmedMeanEq(l1 = Float32(l1), l2 = Float32(l2))


measure_name(inflfn::InflationTrimmedMeanEq) = "Media Truncada Equiponderada (" * string(round(100inflfn.l1, digits=2)) * " , " * string(round(100inflfn.l2, digits=2)) * ")"

"""
    (inflfn::InflationTrimmedMeanEq)(base::VarCPIBase{T}) where T
Define cómo opera InflationTrimmedMeanEq sobre un objeto de tipo VarCPIBase.
"""
function (inflfn::InflationTrimmedMeanEq)(base::VarCPIBase{T}) where T 
    l1 = inflfn.l1
    l2 = inflfn.l2                                          
    L1,L2 = min(l1,l2),max(l1,l2)                                   # de esta forma no importa el orden de los percentilesmedia
    Q1    = Int(ceil(length(base.w)*L1/100))                        # --|
    Q2    = Int(floor(length(base.w)*L2/100))                       # --|obtenemos los numeros correspondientes de elementos para los percentiles
    OUT   = Vector{T}(undef,size(base.v)[1])                        # nuestro vector de salida sin valores asignados
    for i in 1:size(base.v)[1]                                      # para cada t:
        temp    = base.v[i,:]                                       # creamos un array con variaciones
        temp    = sort(temp)                                        # ordenamos
        temp    = temp[Q1:Q2]                                       # truncamos 
        OUT[i]  = mean(temp)                                        # obtenemos la media 
    end
    return OUT
end


