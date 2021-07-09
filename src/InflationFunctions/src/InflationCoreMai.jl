# Función de inflación subyacente MAI (muestra ampliada implícitamente)

# Grilla de variaciones intermensuales
const V = range(-100, 100, step=0.01f0) # -100:0.01:100

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
    w = ones(T, l) * T(100 / l)
    
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
    
    w = 100 * w / sum(w)
    # Obtener distribución dispersa
    distr = sparsevec(vpos, w, length(vspace))
    WeightsDistr(distr, vspace)
end

# Función para mostrar
function Base.show(io::IO, tdistr::TransversalDistr)
    println(io, typeof(tdistr))
    println(io, "|─> Distribución: ", summary(tdistr.distr))
    println(io, "|─> Grilla  : ", tdistr.vspace)
    println(io, "|───> vspace: ", summary(tdistr.vspace))
    println(io, tdistr.distr)
end

# Obtener el promedio
function Statistics.mean(tdistr::TransversalDistr) 
    tdistr.vspace' * tdistr.distr / 100
end

# Suma de la distribución
Base.sum(tdistr::TransversalDistr) = sum(tdistr.distr)

# Obtener valor distribución en una variación 
function (tdistr::TransversalDistr)(v::Real) 
    vpos = vposition(v, tdistr.vspace)
    tdistr.distr[vpos]
end



## Distribución acumulada

# Distribución acumulada (sin diferenciar?) 
struct AccumulatedDistr{T} <: TransversalDistr{T}
    distr::SparseVector{T, Int}
    vspace::StepRangeLen{T, Float64, Float64}
end

# Obtener distribución acumulada de distribución dispersa
function Base.cumsum(tdistr::TransversalDistr)
    AccumulatedDistr(
        sparsevec(tdistr.distr.nzind, cumsum(tdistr.distr.nzval), tdistr.distr.n), 
        tdistr.vspace) 
end

# Obtener valor distribución acumulada en una variación
function (tdistr::AccumulatedDistr{T})(v::Real) where T
    vpos = vposition(v, tdistr.vspace)
    
    l = findlast(vpos .>= tdistr.distr.nzind)
    l === nothing && return zero(T)
    m = tdistr.distr.nzval[l]
    
    m
end