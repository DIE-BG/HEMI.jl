## MEDIA TRUNCADA PONDERADA

#using Statistics
#using CPIDataBase

Base.@kwdef struct InflationTrimmedMeanEq <: InflationFunction
    l1::Float32
    l2::Float32
end

#measure_name(inflfn::InflationTrimmedMeanEq) = "Percentil equiponderado " * string(round(100inflfn.k, digits=2))


#= function (inflfn::InflationTrimmedMeanEq)(base::VarCPIBase{T}) where T                                           
    L1,L2 = min(l1,l2),max(l1,l2)                                   # de esta forma no importa el orden de los percentiles
    Q1    = Int(ceil(quantile(1:length(base.w),L1)))                # --|
    Q2    = Int(floor(quantile(1:length(base.w),L2)))               # --|obtenemos los numeros correspondientes de elementos para los percentiles
    OUT   = Vector{T}(undef,size(base.v)[1])                  # nuestro vector de salida sin valores asignados
    for i in 1:size(base.v)[1]                                      # Para cada fila (es decir para cada t), hacemos lo siguiente:
        temp        = hcat(base.v[i,:],base.w)                      # creamos un array con las variaciones y con sus pesos
        temp        = temp[sortperm(temp[:,1]),:]                   # reordenamos el array segun variaciones 
        temp        = temp[Q1:Q2,:]                                 # truncamos
        temp[:,2]   = temp[:,2] .* 1/sum(temp[:,2])                 # renormalizamos
        OUT[i]      = sum(temp[:,1] .* temp[:,2])                   # multiplicamos variacion por peso
    end
    return OUT
end
 =#


function (inflfn::InflationTrimmedMeanEq)(base::VarCPIBase{T}) where T 
    l1 = inflfn.l1
    l2 = inflfn.l2                                          
    L1,L2 = min(l1,l2),max(l1,l2)                                   # de esta forma no importa el orden de los percentilesmedia
    Q1    = Int(round(quantile(1:length(base.w),L1)))               # --|
    Q2    = Int(round(quantile(1:length(base.w),L2)))               # --|obtenemos los numeros correspondientes de elementos para los percentiles
    OUT   = Vector{T}(undef,size(base.v)[1])                  # nuestro vector de salida sin valores asignados
    for i in 1:size(base.v)[1]                                      # para cada t:
        temp    = base.v[i,:]                                       # creamos un array con variaciones
        temp    = sort(temp)                                        # ordenamos
        temp    = temp[Q1:Q2]                                       # truncamos 
        OUT[i]  = mean(temp)                                        # obtenemos la media 
    end
    return OUT
end


