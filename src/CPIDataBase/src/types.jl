# types.jl - Type definitions and structure
import Base: show, summary, convert, getindex

# Tipo abstracto para definir contenedores del IPC
abstract type AbstractCPIBase end

# Tipos para los vectores de fechas
const DATETYPE = Union{Vector{Date}, StepRange{Date, Month}}

"""
    FullCPIBase{T<:AbstractFloat} <: AbstractCPIBase

Contenedor completo para datos del IPC de un país. Se representa por:
- Matriz de índices de precios `ipc` que incluye la fila con los índices del númbero base. 
- Matriz de variaciones intermensuales `v`. En las filas contiene los períodos y en las columnas contiene los gastos básicos.
- Vector de ponderaciones `w` de los gastos básicos.
- Fechas correspondientes `fechas` (por meses).
"""
Base.@kwdef struct FullCPIBase{T<:AbstractFloat} <: AbstractCPIBase
    ipc::Matrix{T}
    v::Matrix{T}
    w::Vector{T}
    fechas::DATETYPE

    function FullCPIBase(ipc::Matrix{T}, v::Matrix{T}, w::Vector{T}, fechas::DATETYPE) where T
        size(ipc, 2) == size(v, 2) || throw(ArgumentError("número de columnas debe coincidir entre matriz de índices y variaciones"))
        size(ipc, 2) == length(w) || throw(ArgumentError("número de columnas debe coincidir con vector de ponderaciones"))
        size(ipc, 1) == size(v, 1)+1 == length(fechas) || throw(ArgumentError("número de filas de `ipc` debe coincidir con vector de fechas"))
        new{T}(ipc, v, w, fechas)
    end
end


"""
    IndexCPIBase{T<:AbstractFloat} <: AbstractCPIBase

Contenedor genérico de índices de precios del IPC de un país. Se representa por:
- Matriz de índices de precios `ipc` que incluye la fila con los índices del númbero base. 
- Vector de ponderaciones `w` de los gastos básicos.
- Fechas correspondientes `fechas` (por meses).
"""
Base.@kwdef struct IndexCPIBase{T<:AbstractFloat} <: AbstractCPIBase
    ipc::Matrix{T}
    w::Vector{T}
    fechas::DATETYPE

    function IndexCPIBase(ipc::Matrix{T}, w::Vector{T}, fechas::DATETYPE) where T
        size(ipc, 2) == length(w) || throw(ArgumentError("número de columnas debe coincidir con vector de ponderaciones"))
        size(ipc, 1) == length(fechas) || throw(ArgumentError("número de filas debe coincidir con vector de fechas"))
        new{T}(ipc, w, fechas)
    end
end


"""
    VarCPIBase{T<:AbstractFloat} <: AbstractCPIBase

Contenedor genérico para de variaciones intermensuales de índices de precios del IPC de un país. Se representa por:
- Matriz de variaciones intermensuales `v`. En las filas contiene los períodos y en las columnas contiene los gastos básicos.
- Vector de ponderaciones `w` de los gastos básicos.
- Fechas correspondientes `fechas` (por meses).
"""
Base.@kwdef struct VarCPIBase{T<:AbstractFloat} <: AbstractCPIBase
    v::Matrix{T}
    w::Vector{T}
    fechas::DATETYPE
    baseindex::Union{T, Vector{T}}

    function VarCPIBase(v::Matrix{T}, w::Vector{T}, fechas::DATETYPE, baseindex::Union{T, Vector{T}}=100) where T
        size(v, 2) == length(w) || throw(ArgumentError("número de columnas debe coincidir con vector de ponderaciones"))
        size(v, 1) == length(fechas) || throw(ArgumentError("número de filas debe coincidir con vector de fechas"))
        new{T}(v, w, fechas, baseindex)
    end
end


## Constructores

"""
    FullCPIBase(df::DataFrame, gb::DataFrame)

Este constructor devuelve una estructura `FullCPIBase` a partir del DataFrame 
de índices de precios `df`, que contiene en las columnas las categorías o gastos 
básicos del IPC y en las filas los períodos por meses. Las ponderaciones se obtienen 
de la estructura `gb`, en la columna denominada `:Ponderacion`.
"""
function FullCPIBase(df::DataFrame, gb::DataFrame)
    # Obtener matriz de índices de precios
    ipc_mat = convert(Matrix, df[!, 2:end])
    # Matrices de variaciones intermensuales de índices de precios
    v_mat = 100 .* (ipc_mat[2:end, :] ./ ipc_mat[1:end-1, :] .- 1)
    # Ponderación de gastos básicos o categorías
    w = gb[!, :Ponderacion]
    # Actualización de fechas
    fechas = df[1, 1]:Month(1):df[end, 1] 
    # Estructura de variaciones intermensuales de base del IPC
    return FullCPIBase(ipc_mat, v_mat, w, fechas)
end


"""
    VarCPIBase(df::DataFrame, gb::DataFrame)

Este constructor devuelve una estructura `VarCPIBase` a partir del DataFrame 
de índices de precios `df`, que contiene en las columnas las categorías o gastos 
básicos del IPC y en las filas los períodos por meses. Las ponderaciones se obtienen 
de la estructura `gb`, en la columna denominada `:Ponderacion`.
"""
function VarCPIBase(df::DataFrame, gb::DataFrame)
    # Obtener estructura completa
    cpi_base = FullCPIBase(df, gb)
    # Estructura de variaciones intermensuales de base del IPC
    VarCPIBase(cpi_base)
end

function VarCPIBase(base::FullCPIBase) 
    # Obtener índice(s) base
    baseindex = base.ipc[1, :]
    if length(unique(baseindex)) == 1
        return VarCPIBase(base.v, base.w, base.fechas[2:end], baseindex[1])
    end
    VarCPIBase(base.v, base.w, base.fechas[2:end], baseindex)
end

## Obtener VarCPIBase de IndexCPIBase con variaciones intermensuales
## TODO

"""
    IndexCPIBase(df::DataFrame, gb::DataFrame)

Este constructor devuelve una estructura `IndexCPIBase` a partir del DataFrame 
de índices de precios `df`, que contiene en las columnas las categorías o gastos 
básicos del IPC y en las filas los períodos por meses. Las ponderaciones se obtienen 
de la estructura `gb`, en la columna denominada `:Ponderacion`.
"""
function IndexCPIBase(df::DataFrame, gb::DataFrame)
    # Obtener estructura completa
    cpi_base = FullCPIBase(df, gb)
    # Estructura de índices de precios de base del IPC
    return IndexCPIBase(cpi_base.ipc, cpi_base.w, cpi_base.fechas)
end

IndexCPIBase(base::FullCPIBase) = IndexCPIBase(base.ipc, base.w, base.fechas)
IndexCPIBase(base::VarCPIBase) = capitalize(base)

"""
    CountryStructure{N, T<:AbstractFloat}

Estructura que representa el conjunto de bases del IPC de un país, 
posee el campo `base`, que es un vector de la estructura `VarCPIBase`
"""
struct CountryStructure{N, T<:AbstractFloat}
    base::NTuple{N, VarCPIBase{T}}
end

## Conversión

convert(::Type{T}, base::VarCPIBase) where {T <: AbstractFloat} = 
    VarCPIBase(convert.(T, base.v), convert.(T, base.w), base.fechas, convert.(T, base.baseindex))
convert(::Type{T}, base::IndexCPIBase) where {T <: AbstractFloat} = 
    IndexCPIBase(convert.(T, base.ipc), convert.(T, base.w), base.fechas)
convert(::Type{T}, base::FullCPIBase) where {T <: AbstractFloat} = 
    IndexCPIBase(convert.(T, base.ipc), convert.(T, base.v), convert.(T, base.w), base.fechas)


## Métodos para mostrar los tipos

function _formatdate(fecha)
    Dates.format(fecha, dateformat"u-yyyy")
end

function summary(io::IO, base::IndexCPIBase)
    periodos = size(base.ipc, 1)
    print(io, typeof(base), ": ", periodos, " períodos × ", size(base.ipc)[2], " gastos básicos")
end

function summary(io::IO, base::AbstractCPIBase)
    periodos = typeof(base) == VarCPIBase ? size(base.v, 1) : size(base.v, 1) + 1
    print(io, typeof(base), ": ", periodos, " períodos × ", size(base.v)[2], " gastos básicos")
end

function show(io::IO, base::IndexCPIBase)
    periodos = size(base.ipc, 1)
    print(io, typeof(base), ": ", periodos, " períodos × ", size(base.ipc)[2], " gastos básicos ")
    datestart, dateend = _formatdate.((base.fechas[begin], base.fechas[end]))
    print(io, datestart, "-", dateend)
end

function show(io::IO, base::AbstractCPIBase)
    periodos = typeof(base) <: VarCPIBase ? size(base.v, 1) : size(base.v, 1) + 1
    print(io, typeof(base), ": ", periodos, " períodos × ", size(base.v)[2], " gastos básicos ")
    datestart, dateend = _formatdate.((base.fechas[begin], base.fechas[end]))
    print(io, datestart, "-", dateend)
end

function summary(io::IO, cst::CountryStructure)
    datestart, dateend = _formatdate.((cst.base[begin].fechas[begin], cst.base[end].fechas[end]))
    print(io, typeof(cst), ": ", datestart, "-", dateend)
end

function show(io::IO, cst::CountryStructure)
    l = length(cst.base)
    println(io, typeof(cst), " con ", l, " bases")
    for base in cst.base
        println(io, "|-> ", sprint(show, base))
    end
end

## getindex

getindex(cst::CountryStructure{N, T}, i::Int) where {N, T} = cst.base[i]