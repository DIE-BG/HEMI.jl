# Definiciones para distribuciones dispersas de variaciones intermensuales
# utilizadas en el cómputo de la medida de inflación subyacente MAI (muestra
# ampliada implícitamente)

# Constante de normalización para ponderaciones 
const WN = 1

# Función de posición en grilla discreta vspace. Esta función requiere que la
# grilla sea definida de forma simétrica, ya que la posición del cero está fija 
function vposition(v, vspace)
	v0 = (length(vspace) + 1) ÷ 2
	eps = step(vspace) 
	pos = v0 + round(Int, v / eps)
    pos 
end

# Tipo abstracto para representar las distribuciones empíricas, dispersas o
# acumuladas de variaciones intermensuales, equiponderadas y ponderadas
abstract type TransversalDistr{T <: AbstractFloat} end
		
# Distribución de observaciones 
struct ObservationsDistr{T, R} <: TransversalDistr{T}
    distr::SparseVector{T, Int}
    vspace::StepRangeLen{T, R, R}
end

function ObservationsDistr(v::AbstractVector{T}, vspace) where T
    # Obtener posiciones de variaciones en vspace
    vpos = vposition.(v, Ref(vspace))
    # Obtener las ponderaciones 
    l = length(v)
    w = WN * one(T) / l
    # Obtener distribución dispersa
    distr = sparsevec(vpos, w, length(vspace))
    ObservationsDistr(distr, vspace)
end

# Distribución de ponderaciones 
struct WeightsDistr{T, R} <: TransversalDistr{T}
    distr::SparseVector{T, Int}
    vspace::StepRangeLen{T, R, R}
end

function WeightsDistr(v::AbstractVector{T}, w::AbstractVector{T}, vspace) where T
    # Obtener posiciones de variaciones en vspace
    vpos = vposition.(v, Ref(vspace))
    # Obtener las ponderaciones 
    w = WN * w / sum(w)
    # Obtener distribución dispersa
    distr = sparsevec(vpos, w, length(vspace))
    WeightsDistr(distr, vspace)
end

# Distribución transversal acumulada 
struct AccumulatedDistr{T, R} <: TransversalDistr{T}
    distr::SparseVector{T, Int}
    vspace::StepRangeLen{T, R, R}
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


## Extendiendo métodos para distribuciones transversales 

# Método para sumar dos distribuciones f o g. 
# ¡Supone que a y b tienen el mismo vspace!
function Base.:+(a::TransversalDistr, b::TransversalDistr)
    # Combinar los vectores de distribución y normalizar
    sparsedistr = (a.distr + b.distr) / 2
    # Obtener el tipo concreto para la distribución 
    TypeDistr = typeof(a)
    TypeDistr(sparsedistr, a.vspace)
end

# Obtener el promedio simple o ponderado según la distribución
function Statistics.mean(tdistr::TransversalDistr) 
    tdistr.vspace' * tdistr.distr / WN
end

# Suma de los valores en la distribución
Base.sum(tdistr::TransversalDistr) = sum(tdistr.distr)

# Obtener valor distribución en una variación intermensual 
function (tdistr::TransversalDistr)(v::Real) 
    # Obtener la posición en la grilla de variaciones intermensuales y devolver
    # el valor almacenado en esa posición en el vector disperso 
    vpos = vposition(v, tdistr.vspace)
    tdistr.distr[vpos]
end


## Extendiendo métodos para distribuciones acumuladas

# Obtener distribución acumulada de distribución dispersa
function Base.cumsum(tdistr::TransversalDistr)
    AccumulatedDistr(
        sparsevec(tdistr.distr.nzind, cumsum(tdistr.distr.nzval), tdistr.distr.n), 
        tdistr.vspace) 
end

function Base.cumsum!(tdistr::TransversalDistr)
    v_values = tdistr.distr.nzval
    cumsum!(v_values, v_values)
    AccumulatedDistr(
        sparsevec(tdistr.distr.nzind, v_values, tdistr.distr.n), 
        tdistr.vspace)
end

# Obtener valor de distribución acumulada en una variación intermensual 
function (tdistr::AccumulatedDistr{T})(v::Real) where T
    # Obtener posición en la grilla 
    vpos = vposition(v, tdistr.vspace)
    
    # Obtener índice de última variacióni intermensual guardada que sea mayor o
    # igual a la buscada
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
    i_p = cdistr_inds[1]
    mindist = one(T)
    @inbounds for i in 1:length(sparse_cdistr)
        dist = abs(sparse_cdistr[i] - p)
        if dist < mindist 
            mindist = dist
            i_p = i
        end
    end

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

    q_p::T
end

# Definición para cómputo de varios percentiles a la vez
Statistics.quantile(cdistr::AccumulatedDistr{T}, p::AbstractVector) where T = 
    quantile.(Ref(cdistr), p)::Vector{T}

# Función de cómputo de percentiles in-place
function Statistics.quantile!(q, cdistr::AccumulatedDistr, p)
    for i in eachindex(p)
        q[i] = quantile(cdistr, p[i])
    end
end


## Métodos para generar distribuciones a partir de VarCPIBase y CountryStructure

function ObservationsDistr(base::VarCPIBase{T}, vspace) where T
    # Obtener años completos en la base
    full_years = periods(base) ÷ 12

    v = view(base.v[1:12*full_years, :], :)

    # Obtener posiciones de variaciones en vspace
    vpos = vposition.(v, Ref(vspace))
    # Obtener las ponderaciones 
    l = length(v)
    w = WN * one(T) / l
    
    # # Obtener distribución dispersa
    distr = sparsevec(vpos, w, length(vspace))
    ObservationsDistr(distr, vspace)
end


function WeightsDistr(base::VarCPIBase{T}, vspace) where T
    # Obtener años completos en la base
    full_years = periods(base) ÷ 12

    v = view(base.v[1:12*full_years, :], :)
    weights = repeat(base.w', 12*full_years)

    # Obtener posiciones de variaciones en vspace
    vpos = vposition.(v, Ref(vspace))
    # Obtener las ponderaciones 
    w = WN * (@view weights[:]) / sum(weights)
    
    # # Obtener distribución dispersa
    distr = sparsevec(vpos, w, length(vspace))
    WeightsDistr(distr, vspace)
end


## RecipesBase

@recipe function plot(tdistr::TransversalDistr)
    
    # Etiqueta
    if tdistr isa ObservationsDistr
        lbl = "Distribución de observaciones f"
    elseif tdistr isa WeightsDistr
        lbl = "Distribución de pesos g"
    else 
        lbl = "Distribución acumulada"
    end
    label --> lbl
    legend --> :topleft

    # Tipo de gráfica 
    # ptype = tdistr isa AccumulatedDistr ? :line : :bar
    # seriestype --> ptype

    # Límites
    xlims --> (-10, 20)

    tdistr.vspace, tdistr.(tdistr.vspace)
end