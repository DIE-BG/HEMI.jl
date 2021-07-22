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

Base.@kwdef struct InflationCoreMai{T <: AbstractFloat, B, M} <: InflationFunction
    vspace::StepRangeLen{T, B, B} = V
    method::M = MaiG(4)
end

# Constructor de conveniencia para especificar V por defecto 
InflationCoreMai(method::AbstractMaiMethod) = InflationCoreMai(V, method)

# Nombre de la medida 
measure_name(inflfn::InflationCoreMai) = "MAI " * string(inflfn.method)
measure_tag(inflfn::InflationCoreMai) = string(nameof(inflfn)) * string(inflfn.method)


# Operación sobre CountryStructure para obtener variaciones intermensuales de la
# estructura de país
function (inflfn::InflationCoreMai{T})(cs::CountryStructure, ::CPIVarInterm) where T

    # Grilla de variaciones, número de segmentos, cuantiles
    vspace = inflfn.vspace
    n::Int = inflfn.method.n
    p = (0:n) / n
    
    # Computar flp y glp, tomando en cuenta observaciones de años completos en
    # la última base del CountryStructure
    # Revisar paquete CatViews para ahorrar un poco más de memoria, to-do...
    lastbase = cs.base[end]
    T_lp = periods(lastbase) ÷ 12
    v_last = view(lastbase.v[1 : 12*T_lp, :], :)
    v_first = map(base -> view(base.v, :), cs.base[1:end-1])
    all_v = vcat(v_first..., v_last)
    # Ponderaciones de toda la base
    w_first = map(base -> view(repeat(base.w', periods(base)), :), cs.base[1:end-1])
    w_last = view(repeat(lastbase.w', 12*T_lp), :)
    all_w = vcat(w_first..., w_last)

    flp = ObservationsDistr(all_v, vspace)
    glp = WeightsDistr(all_v, all_w, vspace)

    # Intuitivamente, las distribuciones de largo plazo podrían computarse más
    # sencillamente de esta forma. Sin embargo, parece que hay problemas de
    # precisión en los vectores dispersos al agregar las distribuciones de cada
    # base de esta manera. Por lo que se computan las distribuciones de largo
    # plazo con el código de arriba.

    # flp_bases = ObservationsDistr.(cs.base, Ref(vspace))
    # glp_bases = WeightsDistr.(cs.base, Ref(vspace))
    # flp = sum(flp_bases)
    # glp = sum(glp_bases)

    # Obtener distribuciones acumuladas y sus percentiles 
    FLP = cumsum(flp)
    GLP = cumsum(glp)

    q_glp::Vector{T} = quantile(GLP, p)
    q_flp::Vector{T} = quantile(FLP, p)

    # Llamar al método de cómputo de inflación intermensual
    vm_fn = base -> inflfn(base, inflfn.method, glp, FLP, GLP, q_glp, q_flp)
    vm = mapfoldl(vm_fn, vcat, cs.base)
    vm
end

# Variaciones intermensuales resumen con método de MAI-G
function (inflfn::InflationCoreMai)(base::VarCPIBase{T}, method::MaiG, glp, FLP, GLP, q_glp, q_flp) where T

    mai_m = Vector{T}(undef, periods(base))

    # Utilizar la glp y la GLP para computar el resumen intermensual por
    # metodología de inflación subyacente MAI-G
    Threads.@threads for t in 1:periods(base)
        # Computar distribución g y acumularla 
        g = WeightsDistr((@view base.v[t, :]), base.w, inflfn.vspace)
        g_acum = cumsum!(g)

        # Computar resumen intermensual basado en glpₜ
        mai_m[t] = renorm_g_glp2(g_acum, GLP, glp, q_glp, method.n)
    end

    mai_m
end

# Variaciones intermensuales resumen con método de MAI-F
function (inflfn::InflationCoreMai)(base::VarCPIBase{T}, method::MaiF, glp, FLP, GLP, q_glp, q_flp) where T

    mai_m = Vector{T}(undef, periods(base))

    # Utilizar la glp y (FLP, GLP) para computar el resumen intermensual por
    # metodología de inflación subyacente MAI-F
    Threads.@threads for t in 1:periods(base)
        # Computar distribución f y acumularla 
        f = ObservationsDistr((@view base.v[t, :]), inflfn.vspace)
        f_acum = cumsum!(f)
        
        # Computar resumen intermensual basado en flpₜ
        mai_m[t] = renorm_f_flp2(f_acum, FLP, GLP, glp, q_flp, method.n)
    end

    mai_m
end

