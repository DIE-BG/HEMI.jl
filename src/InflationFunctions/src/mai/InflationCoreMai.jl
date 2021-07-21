## Función de inflación subyacente MAI (muestra ampliada implícitamente)

## Grilla de variaciones intermensuales
# const V = range(-200, 200, step=0.01f0) # -100:0.01:100
const V = StepRangeLen(
    Base.TwicePrecision(-100f0, -100f0), 
    Base.TwicePrecision(0f0, 0.01f0), 
    40001)

## Algoritmos de cómputo MAI

abstract type AbstractMaiMethod end 

# Algoritmo de cómputo de MAI-G con n segmentos
struct MaiG <: AbstractMaiMethod
    n::Int
end

Base.string(::MaiG) = "(" * string(n) * ", G)"



## Definición de la función de inflación 
#=
Base.@kwdef struct InflationCoreMai <: InflationFunction
    vspace::StepRangeLen{T<:AbstractFloat, B, B} where {T,B} = V
    method::AbstractMaiMethod = MaiG(4)
end

# Nombre de la medida 
measure_name(inflfn::InflationCoreMai) = "MAI " + string(inflfn.method)

# Operación sobre CountryStructure para obtener variaciones intermensuales de la
# estructura de país
function (inflfn::InflationCoreMai)(cs::CountryStructure, ::CPIVarInterm)

    vspace = inflfn.vspace

    # Computar flp y glp 
    # lastbase = cs.base[end]
    # T_lp = periods(lastbase) ÷ 12
    # vlast = lastbase.v[1 : 12*T_lp, :];
    # all_v = vcat(cs[1][:], vlast[:])

    gt00 = cs[1]
    gt10 = cs[2]
    all_v = vcat(gt00.v[:], gt10.v[1:120, :][:])
    all_w = vcat(repeat(gt00.w', 120)[:], repeat(gt10.w', 120)[:])

    flp = ObservationsDistr(all_v, vspace)
    glp = WeightsDistr(all_v, all_w, vspace)

    # Obtener distribuciones acumuladas
    FLP = cumsum(flp)
    GLP = cumsum(glp)


end

# Variaciones intermensuales resumen con método de MAI-G
function (inflfn::InflationCoreMai)(base::VarCPIBase{T}, method::MaiG) where T

    
end

=#