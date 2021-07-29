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
function (inflfn::InflationCoreMai)(cs::CountryStructure, ::CPIVarInterm)
    inflfn(cs, CPIVarInterm(), inflfn.method)
end 

function (inflfn::InflationCoreMai{T})(cs::CountryStructure, ::CPIVarInterm, method::MaiG) where T
    # Computar flp y glp, tomando en cuenta observaciones de años completos en
    # la última base del CountryStructure
    V_star = _get_vstar(cs)
    W_star = _get_wstar(cs)
    glp = WeightsDistr(V_star, W_star, inflfn.vspace)

    # Obtener distribuciones acumuladas y sus percentiles 
    GLP = cumsum(glp)
    p = (0:method.n) / method.n
    q_glp::Vector{T} = quantile(GLP, p)

    # Llamar al método de cómputo de inflación intermensual
    vm_fn = base -> inflfn(base, inflfn.method, glp, GLP, q_glp)
    vm = mapfoldl(vm_fn, vcat, cs.base)
    vm
end

function (inflfn::InflationCoreMai{T})(cs::CountryStructure, ::CPIVarInterm, method::MaiF) where T

    # Grilla de variaciones, número de segmentos, cuantiles
    p = (0:method.n) / method.n
    
    # Intuitivamente, las distribuciones de largo plazo podrían computarse más
    # sencillamente de esta forma. Sin embargo, parece que hay problemas de
    # precisión en los vectores dispersos al agregar las distribuciones de cada
    # base de esta manera.

    # flp_bases = ObservationsDistr.(cs.base, Ref(vspace))
    # glp_bases = WeightsDistr.(cs.base, Ref(vspace))
    # flp = sum(flp_bases)
    # glp = sum(glp_bases)

    # Computar flp y glp, tomando en cuenta observaciones de años completos en
    # la última base del CountryStructure
    V_star = _get_vstar(cs)
    W_star = _get_wstar(cs)
    flp = ObservationsDistr(V_star, inflfn.vspace)
    glp = WeightsDistr(V_star, W_star, inflfn.vspace)


    # Obtener distribuciones acumuladas y sus percentiles 
    FLP = cumsum(flp)
    GLP = cumsum(glp)
    # q_glp::Vector{T} = quantile(GLP, p)
    q_flp::Vector{T} = quantile(FLP, p)

    # Llamar al método de cómputo de inflación intermensual
    vm_fn = base -> inflfn(base, inflfn.method, glp, GLP, q_flp)
    vm = mapfoldl(vm_fn, vcat, cs.base)
    vm
end

# Función de apoyo para obtener V_star, la ventana histórica con todas las
# variaciones intermensuales. Utilizada para cómputos de distribuciones de largo
# plazo 
function _get_vstar(cs::CountryStructure)
    # Revisar paquete CatViews para ahorrar un poco más de memoria, to-do...
    lastbase = cs.base[end]
    T_lp = periods(lastbase) ÷ 12
    v_last = view(lastbase.v[1 : 12*T_lp, :], :)
    v_first = map(base -> view(base.v, :), cs.base[1:end-1])
    V_star = vcat(v_first..., v_last)
    V_star
end

# Función de apoyo para obtener W_star, vector de ponderaciones asociado a las
# variaciones intermensuales históricas
function _get_wstar(cs::CountryStructure)
    # Ponderaciones de toda la base
    lastbase = cs.base[end]
    T_lp = periods(lastbase) ÷ 12
    w_first = map(base -> view(repeat(base.w', periods(base)), :), cs.base[1:end-1])
    w_last = view(repeat(lastbase.w', 12*T_lp), :)
    W_star = vcat(w_first..., w_last)
    W_star
end

## Métodos de cómputo MAI sobre VarCPIBase,
# Se utiliza información de largo plazo provista por el método que opera sobre
# CountryStructure y CPIVarInterm

# Variaciones intermensuales resumen con método de MAI-G
function (inflfn::InflationCoreMai)(base::VarCPIBase{T}, method::MaiG, glp, GLP, q_glp) where T

    mai_m = Vector{T}(undef, periods(base))
    q_g_list = [zeros(T, method.n+1) for _ in 1:Threads.nthreads()]

    # Utilizar la glp y la GLP para computar el resumen intermensual por
    # metodología de inflación subyacente MAI-G
    Threads.@threads for t in 1:periods(base)

        # Obtener lista de percentiles para el hilo
        j = Threads.threadid() 
        q_g = q_g_list[j]

        # Computar distribución g y acumularla 
        g = WeightsDistr((@view base.v[t, :]), base.w, inflfn.vspace)
        g_acum = cumsum!(g)

        # Computar percentiles de distribución g
        n = method.n
        p = (0:n) / n
        quantile!(q_g, g_acum, p)

        # Computar resumen intermensual basado en glpₜ
        mai_m[t] = renorm_g_glp_perf(g_acum, GLP, glp, q_g, q_glp, n)
    end

    mai_m
end

# Variaciones intermensuales resumen con método de MAI-F
function (inflfn::InflationCoreMai)(base::VarCPIBase{T}, method::MaiF, glp, GLP, q_flp) where T

    mai_m = Vector{T}(undef, periods(base))
    q_f_list = [zeros(T, method.n+1) for _ in 1:Threads.nthreads()]

    # Utilizar la glp y (FLP, GLP) para computar el resumen intermensual por
    # metodología de inflación subyacente MAI-F
    Threads.@threads for t in 1:periods(base)

        # Obtener lista de percentiles para el hilo
        j = Threads.threadid() 
        q_f = q_f_list[j]

        # Computar distribución f y acumularla 
        f = ObservationsDistr((@view base.v[t, :]), inflfn.vspace)
        f_acum = cumsum!(f)
        
        # Computar percentiles de distribución f
        n = method.n
        p = (0:n) / n
        quantile!(q_f, f_acum, p)

        # Computar resumen intermensual basado en flpₜ
        mai_m[t] = renorm_f_flp_perf(f_acum, GLP, glp, q_f, q_flp, method.n)
    end

    mai_m
end

