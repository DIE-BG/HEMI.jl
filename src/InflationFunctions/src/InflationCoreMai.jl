# Función de inflación subyacente MAI (muestra ampliada implícitamente)

# Grilla de variaciones intermensuales
const V = range(-100, 100, step=0.01f0) # -100:0.01:100

const WN = 1

# Función de posición en grilla discreta vspace
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
    println(io, typeof(tdistr))
    println(io, "|─> Distribución: ", summary(tdistr.distr))
    println(io, "|─> Grilla  : ", tdistr.vspace)
    println(io, "|───> vspace: ", summary(tdistr.vspace))
    println(io, tdistr.distr)
end


## Métodos para distribuciones transversales 

# Obtener el promedio
function Statistics.mean(tdistr::TransversalDistr) 
    tdistr.vspace' * tdistr.distr / WN
end

# Suma de la distribución
Base.sum(tdistr::TransversalDistr) = sum(tdistr.distr)

# Obtener valor distribución en una variación 
function (tdistr::TransversalDistr)(v::Real) 
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

# Obtener valor distribución acumulada en una variación intermensual 
function (tdistr::AccumulatedDistr{T})(v::Real) where T
    vpos = vposition(v, tdistr.vspace)
    
    l = findlast(vpos .>= tdistr.distr.nzind)
    l === nothing && return zero(T)
    m = tdistr.distr.nzval[l]
    
    m
end

# Algoritmo de percentil próximo para distribuciones 
function Statistics.quantile(cdistr::AccumulatedDistr, p::Real)
    # Obtener el vector disperso subyacente
    sparse_cdistr = cdistr.distr.nzval

    # Aplicar el algoritmo de percentil próximo para obtener índice de variación
    # intermensual correspondiente al cuantil p
    i_p = argmin(abs.(sparse_cdistr .- p))

    # Devolver la variación intermensual asociada
    cdistr.vspace[cdistr.distr.nzind[i_p]]
end

# Definición para varios percentiles 
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

        # Factor de normalización 
        # norm_c = (G(q_g[k]) - G(q_g[t])) / (GLP(q_g[k]) - GLP(q_g[t]))

        # isnan(norm_c) && continue # error("Error en normalización")

        @info "Renormalizando segmento $i" t k q_g[t] q_g[k]

        # Renormalizar el segmento 
        
        if i == 2
            v1 = min(q_g[t], q_glp[t])
            norm_c = (G(q_g[k]) - G(v1)) / (GLP(q_g[k]) - GLP(v1))
            renormalize!(glpₜ, v1, q_g[k], norm_c)    
        elseif i == length(segments)
            vl = max(q_g[k], q_glp[k])
            norm_c = (G(vl) - G(q_g[t])) / (GLP(vl) - GLP(q_g[t]))
            renormalize!(glpₜ, q_g[t] + ε, vl, norm_c)   
        else
            norm_c = (G(q_g[k]) - G(q_g[t])) / (GLP(q_g[k]) - GLP(q_g[t]))
            renormalize!(glpₜ, q_g[t] + ε, q_g[k], norm_c)     
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
    @show ia ib 

    # Renormalizar el vector de distribución subyacente 
    @show sum(tdistr.distr[ia:ib])
    @views tdistr.distr[ia:ib] .*= k
    @show sum(tdistr.distr[ia:ib])

    nothing
end

# Función para obtener segmento especial de renormalización 
function get_special_segment(q_g, q_glp)
    k̄ = findfirst(q_glp .> 0)
    k̲ = findlast(q_glp .< 0)

    s̄ = findfirst(q_g .> 0)
    s̲ = findlast(q_g .< 0)
    
    r̲ = min(k̲, s̲)
    r̄ = max(k̄, s̄)
    
    r̲, r̄
end