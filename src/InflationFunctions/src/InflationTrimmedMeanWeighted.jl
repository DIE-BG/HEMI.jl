"""
    InflationTrimmedMeanWeighted <: InflationFunction
Función de inflación para computar la media truncada ponderada
"""
Base.@kwdef struct InflationTrimmedMeanWeighted <: InflationFunction
    l1::Float32
    l2::Float32
end

# Métodos para crear funciones de inflación a partir de enteros
InflationTrimmedMeanWeighted(l1::Real,l2::Real) = InflationTrimmedMeanWeighted(l1 = Float32(l1), l2 = Float32(l2))

measure_name(inflfn::InflationTrimmedMeanWeighted) = "Media Truncada Ponderada (" * string(round(inflfn.l1, digits=2)) * " , " * string(round(inflfn.l2, digits=2)) * ")"


"""
    (inflfn::InflationTrimmedMeanWeighted)(base::VarCPIBase{T}) where T
Define cómo opera InflationTrimmedMeanWeighted sobre un objeto de tipo VarCPIBase.
"""
function (inflfn::InflationTrimmedMeanWeighted)(base::VarCPIBase{T}) where T     
    l1 = inflfn.l1
    l2 = inflfn.l2                                        
    L1,L2 = min(l1,l2),max(l1,l2)                                   # de esta forma no importa el orden de los percentiles
    Q1    = Int(ceil(length(base.w)*L1/100))                        # --|
    Q2    = Int(floor(length(base.w)*L2/100))                       # --|obtenemos los numeros correspondientes de elementos para los percentiles
    OUT   = Vector{T}(undef,size(base.v)[1])                        # nuestro vector de salida sin valores asignados
    for i in 1:size(base.v)[1]                                      # Para cada fila (es decir para cada t), hacemos lo siguiente:
        temp        = hcat(base.v[i,:],base.w)                      # creamos un array con las variaciones y con sus pesos
        temp        = temp[sortperm(temp[:,1]),:]                   # reordenamos el array segun variaciones 
        temp        = temp[Q1:Q2,:]                                 # truncamos
        temp[:,2]   = temp[:,2] .* 1/sum(temp[:,2])                 # renormalizamos
        OUT[i]      = sum(temp[:,1] .* temp[:,2])                   # multiplicamos variacion por peso
    end
    return OUT
end 
 