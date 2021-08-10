# #Inflación media ponderada
# InflationWeightedMean.jl - Función de inflación media ponderada interanual 

"""
    InflationWeightedMean <: InflationFunction
Función de inflación para computar la media ponderada.
"""
struct InflationWeightedMean <: InflationFunction
end

# 2. Extender el método de nombre 
measure_name(::InflationWeightedMean) = "Media ponderada interanual"

# Define cómo opera InflationSimpleMean sobre un objeto de tipo VarCPIBase.
function (inflfn::InflationWeightedMean)(base::VarCPIBase{T}) where T
    #Obtener el indice correspondiente a las variaciones intermensuales
    indmat = capitalize(base.v)
    #Cálculo de la variación interanual
    y2ymat = varinteran(indmat)
    #Cálculo de la media ponderada de las variaciones interanuales
    y2yweightedmean = y2ymat*base.w/100
    #Utilizar el índice de la media ponderada de las variaciones intermensuales de los primeros  
    #11 meses para completar la serie del índice de media ponderada de variaciones interanuales
    m2mweightedmean = base.v*base.w/100
    weightedmeanind = zeros(T, periods(base)+1); weightedmeanind[1]=100;
    weightedmeanind[2:12] = capitalize(m2mweightedmean[1:11])
    for j = 13:periods(base)+1
        weightedmeanind[j] = (y2yweightedmean[j-12]/100 + 1)*weightedmeanind[j-12]
    end
    #Cálculo de la variación intermensual del índice de media simple
    weightedmean = varinterm(weightedmeanind[2:end])
    weightedmean
end