## Función de inflación subyacente MAI (muestra ampliada implícitamente)

## Grilla de variaciones intermensuales
const V = range(-200, 200, step=0.01f0) # -100:0.01:100

## Algoritmos de cómputo MAI


abstract type AbstractMaiMethod end 

# Algoritmo de cómputo de MAI-G con n segmentos
struct MaiG <: AbstractMaiMethod
    n::Int
end

# Algoritmo de cómputo de MAI-F con n segmentos
struct MaiF <: AbstractMaiMethod
    n::Int
end

Base.string(method::MaiG) = "(G," * string(method.n) * ")"
Base.string(method::MaiF) = "(F," * string(method.n) * ")"



## Definición de la función de inflación 

Base.@kwdef struct InflationCoreMai{T <: AbstractFloat, B} <: InflationFunction
    vspace::StepRangeLen{T, B, B} = V
    method::AbstractMaiMethod = MaiG(4)
end

# Nombre de la medida 
measure_name(inflfn::InflationCoreMai) = "MAI " * string(inflfn.method)

# Operación sobre CountryStructure para obtener variaciones intermensuales de la
# estructura de país
function (inflfn::InflationCoreMai)(cs::CountryStructure, ::CPIVarInterm)

    # method = inflfn.method
    vspace = inflfn.vspace

    # Computar flp y glp 
    # lastbase = cs.base[end]
    # T_lp = periods(lastbase) ÷ 12
    # vlast = lastbase.v[1 : 12*T_lp, :];
    # all_v = vcat(cs[1][:], vlast[:])

    # gt00 = cs[1]
    # gt10 = cs[2]
    # all_v = vcat(gt00.v[:], gt10.v[1:120, :][:])
    # all_w = vcat(repeat(gt00.w', 120)[:], repeat(gt10.w', 120)[:])

    # flp = ObservationsDistr(all_v, vspace)
    # glp = WeightsDistr(all_v, all_w, vspace)

    flp_bases = ObservationsDistr.(cs.base, Ref(vspace))
    glp_bases = WeightsDistr.(cs.base, Ref(vspace))

    flp = sum(flp_bases)
    glp = sum(glp_bases)

    # Obtener distribuciones acumuladas
    FLP = cumsum(flp)
    GLP = cumsum(glp)

    # Llamar al método de cómputo de inflación intermensual
    vm_fn = base -> inflfn(base, inflfn.method, glp, FLP, GLP)
    vm = mapfoldl(vm_fn, vcat, cs.base)
    vm
end

# Variaciones intermensuales resumen con método de MAI-G
function (inflfn::InflationCoreMai)(base::VarCPIBase{T}, method::MaiG, glp, FLP, GLP) where T

    mai_m = Vector{T}(undef, periods(base))

    # Utilizar la glp y la GLP para computar el resumen intermensual por
    # metodología de inflación subyacente MAI-G
    Threads.@threads for t in 1:periods(base)
        # Computar distribución g y acumularla 
        g = WeightsDistr((@view base.v[t, :]), base.w, inflfn.vspace)
        g_acum = cumsum!(g)
        glpt = renorm_g_glp(g_acum, GLP, glp, method.n)

        mai_m[t] = mean(glpt)
    end

    mai_m
end

# Variaciones intermensuales resumen con método de MAI-F
function (inflfn::InflationCoreMai)(base::VarCPIBase{T}, method::MaiF, glp, FLP, GLP) where T

    mai_m = Vector{T}(undef, periods(base))

    # Utilizar la glp y (FLP, GLP) para computar el resumen intermensual por
    # metodología de inflación subyacente MAI-F
    for t in 1:periods(base)
        # Computar distribución f y acumularla 
        f = ObservationsDistr((@view base.v[t, :]), inflfn.vspace)
        f_acum = cumsum!(f)
        flpt = renorm_f_flp(f_acum, FLP, GLP, glp, method.n)

        mai_m[t] = mean(flpt)
    end

    mai_m
end

