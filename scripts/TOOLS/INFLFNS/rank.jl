# Funcion para ordenar las medidas de inflacion en un orden establecido
function rank(inflfn::InflationFunction)
    if inflfn isa InflationPercentileEq
        return 1
    elseif inflfn isa InflationPercentileWeighted
        return 2
    elseif inflfn isa InflationTrimmedMeanEq
        return 3
    elseif inflfn isa InflationTrimmedMeanWeighted
        return 4
    elseif inflfn isa InflationDynamicExclusion
        return 5
    elseif inflfn isa InflationFixedExclusionCPI
        return 6
    elseif inflfn isa InflationCoreMai
        if inflfn.method isa MaiFP
            return 7
        elseif inflfn.method isa MaiF
            return 8
        else 
            return 9
        end
    elseif inflfn isa Splice
        return rank(inflfn.f[1])
    end
end

function inflfn_tag(inflfn)
    if inflfn == InflationPercentileEq
        return "PerEq"
    elseif inflfn == InflationPercentileWeighted
        return "PerW"
    elseif inflfn == InflationTrimmedMeanEq
        return "MTEq"
    elseif inflfn == InflationTrimmedMeanWeighted
        return "MTW"
    elseif inflfn == InflationDynamicExclusion
        return "DynEx"
    elseif inflfn <: InflationFixedExclusionCPI{T} where T
        return "FxExc"
    elseif inflfn == InflationCoreMai{Float32, Float64, MaiFP{Vector{Float64}}}
        return "MaiFP"
    elseif inflfn == InflationCoreMai{Float32, Float64, MaiF{Vector{Float64}}}
        return "MaiF"
    elseif inflfn == InflationCoreMai{Float32, Float64, MaiG{Vector{Float64}}}
        return "MaiG"
    end
end

function inflfn_name(inflfn)
    if inflfn == InflationPercentileEq
        return "Percentil Equiponderado"
    elseif inflfn == InflationPercentileWeighted
        return "Percentil Ponderado"
    elseif inflfn == InflationTrimmedMeanEq
        return "Media Truncada Equiponderada"
    elseif inflfn == InflationTrimmedMeanWeighted
        return "Media Truncada Ponderada"
    elseif inflfn == InflationDynamicExclusion
        return "Exclusion Dinámica"
    elseif inflfn <: InflationFixedExclusionCPI{T} where T
        return "Exclusion Fija"
    elseif inflfn == InflationCoreMai{Float32, Float64, MaiFP{Vector{Float64}}}
        return "Mai FP"
    elseif inflfn == InflationCoreMai{Float32, Float64, MaiF{Vector{Float64}}}
        return "Mai F"
    elseif inflfn == InflationCoreMai{Float32, Float64, MaiG{Vector{Float64}}}
        return "Mai G"
    end
end