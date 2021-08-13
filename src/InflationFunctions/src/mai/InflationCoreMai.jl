## Función de inflación subyacente MAI (muestra ampliada implícitamente)

## Grilla de variaciones intermensuales
const V = range(-200, 200, step=0.01f0) # -100:0.01:100

## Algoritmos de cómputo MAI


abstract type AbstractMaiMethod end 

# Algoritmo de cómputo de MAI-G con n segmentos marcados en las posiciones p
"""
    MaiG{P} <: AbstractMaiMethod

    MaiG(n::Int)
    MaiG(p::AbstractArray)

Tipo para englobar la metodología de cómputo de inflación subyacente MAI-G, en
la cual se transforma la distribución ponderada de variaciones intermensuales
utilizando la distribución histórica de variaciones intermensuales ponderadas. 

Se proporciona el número de segmentos de normalización, o bien, las posiciones
de los cuantiles utilizados para llevar a cabo la transformación. Si se
proporcionan las posiciones, la primera y la última posición deben ser el
cuantil 0 y 1, respectivamente.

## Ejemplos 

1. Utilizar los quintiles como puntos de referencia para normalización 
```jldoctest 
julia> method = MaiG(5)
MaiG{StepRangeLen{Float64, Base.TwicePrecision{Float64}, Base.TwicePrecision{Float64}}}(5, 0.0:0.2:1.0)
```

2. Utilizar tres segmentos de normalización, en el primer y tercer cuartil: 
```jldoctest 
julia> method = MaiG([0, 0.25, 0.75, 1])
MaiG{Vector{Float64}}(3, [0.0, 0.25, 0.75, 1.0])
```
"""
struct MaiG{P} <: AbstractMaiMethod
    n::Int
    p::P

    function MaiG(n, p)
        _checkmethod(n, p)
        new{typeof(p)}(n, p)
    end
end

# Algoritmo de cómputo de MAI-F con n segmentos marcados en las posiciones p
"""
    MaiF{P} <: AbstractMaiMethod

    MaiF(n::Int)
    MaiF(p::AbstractArray)

Tipo para englobar la metodología de cómputo de inflación subyacente MAI-F, en
la cual se transforma la distribución **de ocurrencias** (o equiponderada) de
variaciones intermensuales utilizando la distribución histórica de variaciones
intermensuales ponderadas. 

Se proporciona el número de segmentos de normalización, o bien, las posiciones
de los cuantiles utilizados para llevar a cabo la transformación. Si se
proporcionan las posiciones, la primera y la última posición deben ser el
cuantil 0 y 1, respectivamente.

## Ejemplos 

1. Utilizar los quintiles como puntos de referencia para normalización 
```jldoctest 
julia> method = MaiF(5)
MaiF{StepRangeLen{Float64, Base.TwicePrecision{Float64}, Base.TwicePrecision{Float64}}}(5, 0.0:0.2:1.0)
```

2. Utilizar tres segmentos de normalización, en el primer y tercer cuartil: 
```jldoctest 
julia> method = MaiF([0, 0.25, 0.75, 1])
MaiF{Vector{Float64}}(3, [0.0, 0.25, 0.75, 1.0])
```
"""
struct MaiF{P} <: AbstractMaiMethod
    n::Int
    p::P

    function MaiF(n, p)
        _checkmethod(n, p)
        new{typeof(p)}(n, p)
    end
end

"""
    MaiFP{P} <: AbstractMaiMethod

    MaiFP(n::Int)
    MaiFP(p::AbstractArray)

Tipo para englobar la metodología de cómputo de inflación subyacente MAI-FP, en
la cual se transforma la distribución **de ocurrencias** de variaciones
intermensuales utilizando la distribución histórica de variaciones
intermensuales equiponderadas. Esta es la versión equivalente a la MAI-G, que
utiliza **todas las distribuciones de ocurrencias**.  

Se proporciona el número de segmentos de normalización, o bien, las posiciones
de los cuantiles utilizados para llevar a cabo la transformación. Si se
proporcionan las posiciones, la primera y la última posición deben ser el
cuantil 0 y 1, respectivamente.

## Ejemplos 

1. Utilizar los quintiles como puntos de referencia para normalización 
```jldoctest 
julia> method = MaiFP(5)
MaiFP{StepRangeLen{Float64, Base.TwicePrecision{Float64}, Base.TwicePrecision{Float64}}}(5, 0.0:0.2:1.0)
```

2. Utilizar tres segmentos de normalización, en el primer y tercer cuartil: 
```jldoctest 
julia> method = MaiFP([0, 0.25, 0.75, 1])
MaiFP{Vector{Float64}}(3, [0.0, 0.25, 0.75, 1.0])
```
"""
struct MaiFP{P} <: AbstractMaiMethod
    n::Int
    p::P

    function MaiFP(n, p)
        _checkmethod(n, p)
        new{typeof(p)}(n, p)
    end
end


# Revisión de condiciones para aplicación de métodos MAI 
function _checkmethod(n, p)
    length(p) == n+1 || error("Distribución de percentiles de tamaño incorrecto")
    issorted(p) || error("Distribución de percentiles debe estar ordenada")
    all(0 .<= p .<= 1) || error("Cuantiles deben estar entre cero y uno")
    (first(p) == 0 && last(p) == 1) || error("Primer y último cuantil deben ser 0, 1")
end

# Constructores para división equitativa de posiciones p
MaiF(n::Int) = MaiF(n, (0:n)/n)
MaiG(n::Int) = MaiG(n, (0:n)/n)
MaiFP(n::Int) = MaiFP(n, (0:n)/n)
MaiF(p::AbstractArray) = MaiF(length(p)-1, p)
MaiG(p::AbstractArray) = MaiG(length(p)-1, p)
MaiFP(p::AbstractArray) = MaiFP(length(p)-1, p)

function Base.string(method::AbstractMaiMethod)
    algorithm = method isa MaiG ? "G" : (method isa MaiF ? "F" : "FP")
    if method.p isa StepRangeLen 
        return "($algorithm," * string(method.n) * ")"
    else
        return "($algorithm," * string(method.n) * "," * string(round.(method.p[2:end-1], digits=2)) * ")"
    end
end


## Definición de la función de inflación 
"""
    InflationCoreMai{T <: AbstractFloat, B, M <:AbstractMaiMethod} 
        <: InflationFunction

    InflationCoreMai(vspace::StepRangeLen{T, B, B}, method::M)

Función de inflación de la metodología de muestra ampliada implicítamente (MAI).
Se parametriza en el tipo flotante `T` de los datos, `B` el tipo para
representar la precisión de la grilla `vspace` en el algoritmo de cómputo y el
método `M` de cómputo. 

Los métodos de cómputo disponibles son: 
- Metodología MAI-G: se transforma la distribución **ponderada** de variaciones
  intermensuales utilizando la distribución histórica de variaciones
  intermensuales ponderadas. Se debe dar como argumento el método
  [`MaiG`](@ref).
- Metodología MAI-F: se transforma la distribución **de ocurrencias** de
  variaciones intermensuales utilizando la distribución histórica de variaciones
  intermensuales ponderadas. Se debe dar como argumento el método
  [`MaiF`](@ref).
- Metodología MAI-FP: se transforma la distribución **de ocurrencias** de
  variaciones intermensuales utilizando la distribución histórica de variaciones
  intermensuales **equiponderadas**. Es un equivalente directo de la metodología
  MAI-G, reemplazando todas las distribuciones por las versiones de ocurrencias.
  Se debe dar como argumento el método [`MaiFP`](@ref).
"""
Base.@kwdef struct InflationCoreMai{T <: AbstractFloat, B, M <:AbstractMaiMethod} <: InflationFunction
    vspace::StepRangeLen{T, B, B} = V
    method::M = MaiG(4)
end

# Constructor de conveniencia para especificar V por defecto 
InflationCoreMai(method::AbstractMaiMethod) = InflationCoreMai(V, method)

# Nombre de la medida 
measure_name(inflfn::InflationCoreMai) = "MAI " * string(inflfn.method)

# Parámetros 
CPIDataBase.params(inflfn::InflationCoreMai) = (inflfn.method, )


## Métodos de cómputo intermensual 

# Operación sobre CountryStructure para obtener variaciones intermensuales de la
# estructura de país. Esta función llama a los métodos que reciben el método de
# cómputo MAI
function (inflfn::InflationCoreMai)(cs::CountryStructure, ::CPIVarInterm)
    inflfn(cs, CPIVarInterm(), inflfn.method)
end 

# Función de resumen intermensual para metodología MAI-G
function (inflfn::InflationCoreMai{T})(cs::CountryStructure, ::CPIVarInterm, method::MaiG) where T
    # Computar flp y glp, tomando en cuenta observaciones de años completos en
    # la última base del CountryStructure
    V_star = _get_vstar(cs)
    W_star = _get_wstar(cs)
    glp = WeightsDistr(V_star, W_star, inflfn.vspace)

    # Obtener distribuciones acumuladas y sus percentiles 
    GLP = cumsum(glp)
    q_glp::Vector{T} = quantile(GLP, method.p)

    # Llamar al método de cómputo de inflación intermensual
    vm_fn = base -> inflfn(base, inflfn.method, glp, GLP, q_glp)
    vm = mapfoldl(vm_fn, vcat, cs.base)
    vm
end

# Función de resumen intermensual para metodología MAI-F
function (inflfn::InflationCoreMai{T})(cs::CountryStructure, ::CPIVarInterm, method::MaiF) where T
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
    # q_glp::Vector{T} = quantile(GLP, method.p)
    q_flp::Vector{T} = quantile(FLP, method.p)

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


## Métodos de cómputo MAI sobre VarCPIBase

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
        quantile!(q_g, g_acum, method.p)

        # Computar resumen intermensual basado en glpₜ
        mai_m[t] = renorm_g_glp_perf(g_acum, GLP, glp, q_g, q_glp, method.n)
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
        quantile!(q_f, f_acum, method.p)

        # Computar resumen intermensual basado en flpₜ
        mai_m[t] = renorm_f_flp_perf(f_acum, GLP, glp, q_f, q_flp, method.n)
    end

    mai_m
end


## Metodología MAI-FP

# Aplicación directa de las fórmulas de normalización de la
# metodología MAI-G, utilizando las distribuciones de ocurrencias 

# Función de resumen intermensual para metodología MAI-FP
function (inflfn::InflationCoreMai{T})(cs::CountryStructure, ::CPIVarInterm, method::MaiFP) where T
    # Computar flp, tomando en cuenta observaciones de años completos en
    # la última base del CountryStructure
    V_star = _get_vstar(cs)
    flp = ObservationsDistr(V_star, inflfn.vspace)

    # Obtener distribuciones acumuladas y sus percentiles 
    FLP = cumsum(flp)
    q_flp::Vector{T} = quantile(FLP, method.p)

    # Llamar al método de cómputo de inflación intermensual
    vm_fn = base -> inflfn(base, inflfn.method, flp, FLP, q_flp)
    vm = mapfoldl(vm_fn, vcat, cs.base)
    vm
end

# Variaciones intermensuales resumen con método de MAI-FP
function (inflfn::InflationCoreMai)(base::VarCPIBase{T}, method::MaiFP, flp, FLP, q_flp) where T

    mai_m = Vector{T}(undef, periods(base))
    q_f_list = [zeros(T, method.n+1) for _ in 1:Threads.nthreads()]

    # Utilizar la flp y la FLP para computar el resumen intermensual por
    # metodología de inflación subyacente MAI-G
    Threads.@threads for t in 1:periods(base)

        # Obtener lista de percentiles para el hilo
        j = Threads.threadid() 
        q_f = q_f_list[j]

        # Computar distribución f y acumularla 
        f = ObservationsDistr((@view base.v[t, :]), inflfn.vspace)
        f_acum = cumsum!(f)

        # Computar percentiles de distribución f
        quantile!(q_f, f_acum, method.p)

        # Computar resumen intermensual basado en flpₜ
        mai_m[t] = renorm_g_glp_perf(f_acum, FLP, flp, q_f, q_flp, method.n)
    end

    mai_m
end