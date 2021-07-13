# Función de inflación subyacente MAI (muestra ampliada implícitamente)

# Grilla de variaciones intermensuales
const V = range(-100, 100, step=0.01f0) # -100:0.01:100

const WN = 1

# Función de posición en grilla discreta vspace. Esta función requiere que la
# grilla sea definida de forma simétrica, ya que la posición del cero está fija 
function vposition(v, vspace)
	v0 = (length(vspace) + 1) ÷ 2
	eps = step(vspace) 
	pos = v0 + round(Int, v / eps)
end

# Tipo abstracto para representar las distribuciones empíricas, dispersas o
# acumuladas de variaciones intermensuales, equiponderadas y ponderadas
abstract type TransversalDistr{T <: AbstractFloat} end
		
# Distribución de observaciones 
struct ObservationsDistr{T} <: TransversalDistr{T}
    distr::SparseVector{T, Int}
    vspace::StepRangeLen{T, Float64, Float64}
end

function ObservationsDistr(v::AbstractVector{T}, vspace) where T
    # Obtener posiciones de variaciones en vspace
    vpos = vposition.(v, Ref(vspace))
    # Obtener las ponderaciones 
    l = length(v)
    w = ones(T, l) * T(WN / l)
    
    # Obtener distribución dispersa
    distr = sparsevec(vpos, w, length(vspace))
    ObservationsDistr(distr, vspace)
end

# Distribución de ponderaciones 
struct WeightsDistr{T} <: TransversalDistr{T}
    distr::SparseVector{T, Int}
    vspace::StepRangeLen{T, Float64, Float64}
end

function WeightsDistr(v::AbstractVector{T}, w::AbstractVector{T}, vspace) where T
    # Obtener posiciones de variaciones en vspace
    vpos = vposition.(v, Ref(vspace))
    # Obtener las ponderaciones 
    l = length(v)
    
    w = WN * w / sum(w)
    # Obtener distribución dispersa
    distr = sparsevec(vpos, w, length(vspace))
    WeightsDistr(distr, vspace)
end

# Distribución acumulada (sin diferenciar?) 
struct AccumulatedDistr{T} <: TransversalDistr{T}
    distr::SparseVector{T, Int}
    vspace::StepRangeLen{T, Float64, Float64}
end

# Función para mostrar
function Base.show(io::IO, tdistr::TransversalDistr)
    println(io, "Sparse ", typeof(tdistr))
    println(io, "|─> Distribution : ", summary(tdistr.distr))
    println(io, "|─> Support      : ", tdistr.vspace, " ─ Step: ", step(tdistr.vspace))
    println(io, "|─> Elements     : ", nnz(tdistr.distr))

    # Imprimir la distribución, con índices y posiciones en la grilla 
    n = length(tdistr.distr)
    pad = ndigits(n)
    limit = get(io, :limit, false)::Bool
    half_screen_rows = limit ? div(displaysize(io)[1] - 10, 2) : typemax(Int)
    nzind = tdistr.distr.nzind
    nzval = tdistr.distr.nzval

    for k = eachindex(nzind)
        if k < half_screen_rows || k > length(nzind) - half_screen_rows
            print(io, "    ", '[', rpad(nzind[k], pad), "]  => ", lpad(tdistr.vspace[nzind[k]], 7), "  =>  ", round(nzval[k], digits=5))
            k != length(nzind) && println(io)
        elseif k == half_screen_rows
            println(io, "   ", " "^pad, "   \u22ee")
        end
    end
end


## Métodos para distribuciones transversales 

# Obtener el promedio
function Statistics.mean(tdistr::TransversalDistr) 
    tdistr.vspace' * tdistr.distr / WN
end

# Suma de la distribución
Base.sum(tdistr::TransversalDistr) = sum(tdistr.distr)

# Obtener valor distribución en una variación intermensual 
function (tdistr::TransversalDistr)(v::Real) 
    # Obtener la posición en la grilla de variaciones intermensuales y devolver
    # el valor almacenado en esa posición en el vector disperso 
    vpos = vposition(v, tdistr.vspace)
    tdistr.distr[vpos]
end


## Métodos para distribución acumulada

# Obtener distribución acumulada de distribución dispersa
function Base.cumsum(tdistr::TransversalDistr)
    AccumulatedDistr(
        sparsevec(tdistr.distr.nzind, cumsum(tdistr.distr.nzval), tdistr.distr.n), 
        tdistr.vspace) 
end

# Obtener valor de distribución acumulada en una variación intermensual 
function (tdistr::AccumulatedDistr{T})(v::Real) where T
    vpos = vposition(v, tdistr.vspace)
    
    l = findlast(vpos .>= tdistr.distr.nzind)
    l === nothing && return zero(T)
    m = tdistr.distr.nzval[l]
    
    m
end

# Algoritmo de percentil próximo para distribuciones 
function Statistics.quantile(cdistr::AccumulatedDistr{T}, p::Real) where T
    # Obtener el vector disperso subyacente y sus índices
    sparse_cdistr = cdistr.distr.nzval
    cdistr_inds = cdistr.distr.nzind
    ε = step(cdistr.vspace)

    # Aplicar el algoritmo de percentil próximo para obtener índice de variación
    # intermensual correspondiente al cuantil p
    i_p = argmin(abs.(sparse_cdistr .- p))

    # Obtener la variación intermensual asociada
    q_p = cdistr.vspace[cdistr_inds[i_p]]

    # Si la variación es la última, no reajustar 
    if i_p == length(cdistr_inds)
        return q_p 
    # Si el índice es de la variación cero, devolver esta variación intermensual 
    elseif q_p == T(-0.01)
        return zero(T)
    # Si la variación del cuantil p es menor que p, obtener la máxima de las
    # variaciones intermensuales que verifica ser la más próxima al cuantil
    # buscado
    elseif cdistr(q_p) < p
        q_p = cdistr.vspace[cdistr_inds[i_p + 1]] - ε
    end

    q_p
end

# Definición para cómputo de varios percentiles a la vez
Statistics.quantile(cdistr::AccumulatedDistr, p::AbstractVector{T} where T <: Real) = 
    quantile.(Ref(cdistr), p)



## Funciones para renormalización y cómputo de MAI

# Renormalización de distribución g con distribución glp utilizando n segmentos
function renorm_g_glp(g, glp, n)

    # Percentiles con n segmentos 
    p = (0:n) ./ n
    
    # Obtener distribuciones acumuladas
    G = cumsum(g)
    GLP = cumsum(glp)

    # Obtener los percentiles de los n segmentos
    q_g = quantile(G, p)
    q_glp = quantile(GLP, p)

    r̲, r̄ = InflationFunctions.get_special_segment(q_g, q_glp)
    segments = union(1:r̲, r̄:n+1)

    # Precisión ε
    ε = step(glp.vspace)

    @sync @info "Percentiles" q_g q_glp ε segments

    # Crear una copia de la distribución glp 
    glpₜ = deepcopy(glp)

    # Renormalizar cada segmento
    for i in 2:length(segments)
        k = segments[i]
        t = segments[i-1]

        # Renormalizar el segmento 
        v1 = i == 2 ? min(q_g[t], q_glp[t]) : q_g[t]
        vl = i == length(segments) ? max(q_g[k], q_glp[k]) : q_g[k]
        norm_c = (G(vl) - G(v1)) / (GLP(vl) - GLP(v1))

        isnan(norm_c) && continue # error("Error en normalización")
        @info "Renormalizando segmento $i" t k q_g[t] q_g[k] norm_c

        # Si es el primer segmento, incluir el límite inferior.
        # De lo contrario, renormalizar a partir de la siguiente posición en la
        # grilla
        if i == 2
            renormalize!(glpₜ, v1, vl, norm_c)
        else
            renormalize!(glpₜ, v1 + ε, vl, norm_c)
        end
    end

    # Devolver la distribución renormalizada
    glpₜ
end

# Función para renormalizar segmento dado entre dos variaciones intermensuales a y b
# por el valor k
function renormalize!(tdistr::TransversalDistr, a, b, k)
    # Obtener índices de variaciones a y b en vspace
    ia = vposition(a, tdistr.vspace)
    ib = vposition(b, tdistr.vspace)

    # Renormalizar el vector de distribución subyacente 
    @views tdistr.distr[ia:ib] .*= k
    nothing
end

# Función para obtener segmento especial de renormalización 
function get_special_segment(q_cp, q_lp)
    # Obtener número de percentiles que conforman segmento especial en la
    # disribución de largo plazo
    k̄ = findfirst(q_lp .> 0)
    k̲ = findlast(q_lp .< 0)
    
    # Obtener número de percentiles que conforman segmento especial en la
    # disribución del mes o ventana
    s̄ = findfirst(q_cp .> 0)
    s̲ = findlast(q_cp .< 0)
    
    # Obtener los números comunes
    r̲ = min(k̲, s̲)
    r̄ = max(k̄, s̄)
    
    r̲, r̄
end