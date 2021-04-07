# types.jl - Type definitions and structure
import Base: show, summary, convert, getindex

# Tipo abstracto para definir contenedores del IPC
abstract type AbstractCPIBase end

# Tipos para los vectores de fechas
const DATETYPE = Union{Vector{Date}, StepRange{Date, Month}}

"""
    CPIBase{T<:AbstractFloat} <: AbstractCPIBase

Contenedor completo para datos del IPC de un país. Se representa por:
- Matriz de índices de precios `ipc` que incluye la fila con los índices del númbero base. 
- Matriz de variaciones intermensuales `v`. En las filas contiene los períodos y en las columnas contiene los gastos básicos.
- Vector de ponderaciones `w` de los gastos básicos.
- Fechas correspondientes `fechas` (por meses).
"""
Base.@kwdef struct CPIBase{T<:AbstractFloat} <: AbstractCPIBase
    ipc::Matrix{T}
    v::Matrix{T}
    w::Vector{T}
    fechas::DATETYPE
end


"""
    VarCPIBase{T<:AbstractFloat} <: AbstractCPIBase

Contenedor genérico para datos del IPC. Se representa por:
- Matriz de índices de precios `ipc` que incluye la fila con los índices del númbero base. 
- Matriz de variaciones intermensuales `v`. En las filas contiene los períodos y en las columnas contiene los gastos básicos.
- Vector de ponderaciones `w` de los gastos básicos.
- Fechas correspondientes `fechas` (por meses).
"""
Base.@kwdef struct VarCPIBase{T<:AbstractFloat} <: AbstractCPIBase
    v::Matrix{T}
    w::Vector{T}
    fechas::DATETYPE

    function VarCPIBase(v::Matrix{T}, w::Vector{T}, fechas::DATETYPE) where T
        size(v, 2) == length(w) || throw(ArgumentError("número de columnas debe coincidir con vector de ponderaciones"))
        size(v, 1) == length(fechas) || throw(ArgumentError("número de filas debe coincidir con vector de fechas"))
        new{T}(v, w, fechas)
    end
end


## Constructores

"""
    CPIBase(df::DataFrame, gb::DataFrame)

Este constructor devuelve una estructura `CPIBase` a partir del DataFrame 
de índices de precios `df`, que contiene en las columnas las categorías o gastos 
básicos del IPC y en las filas los períodos por meses. Las ponderaciones se obtienen 
de la estructura `gb`, en la columna denominada `:Ponderacion`.
"""
function CPIBase(df::DataFrame, gb::DataFrame)
    # Obtener matriz de índices de precios
    ipc_mat = convert(Matrix, df[!, 2:end])
    # Matrices de variaciones intermensuales de índices de precios
    v_mat = 100 .* (ipc_mat[2:end, :] ./ ipc_mat[1:end-1, :] .- 1)
    # Ponderación de gastos básicos o categorías
    w = gb[!, :Ponderacion]
    # Actualización de fechas
    fechas = df[1, 1]:Month(1):df[end, 1] 
    # Estructura de variaciones intermensuales de base del IPC
    return CPIBase(ipc_mat, v_mat, w, fechas)
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
    cpi_base = CPIBase(df, gb)
    # Estructura de variaciones intermensuales de base del IPC
    return VarCPIBase(cpi_base.v, cpi_base.w, cpi_base.fechas)
end


"""
    CountryStructure{N, T<:AbstractFloat}

Estructura que representa el conjunto de bases del IPC de un país, 
posee el campo `base`, que es un vector de la estructura `CPIBase`
"""
struct CountryStructure{N, T<:AbstractFloat}
    base::NTuple{N, VarCPIBase{T}}
end

## Conversión

convert(::Type{T}, base::VarCPIBase) where {T <: AbstractFloat} = 
    VarCPIBase(convert.(T, base.v), convert.(T, base.w), base.fechas)


## Métodos para mostrar los tipos

function summary(io::IO, base::AbstractCPIBase)
    periodos = typeof(base) == CPIBase ? size(base.v, 1) : size(base.v, 1) + 1
    print(io, typeof(base), ": ", periodos, " períodos × ", size(base.v)[2], " gastos básicos")
end

function show(io::IO, base::AbstractCPIBase)
    periodos = typeof(base) <: VarCPIBase ? size(base.v, 1) : size(base.v, 1) + 1
    print(io, typeof(base), ": ", periodos, " períodos × ", size(base.v)[2], " gastos básicos ")
    datestart = Dates.format(base.fechas[begin], dateformat"u-yyyy")
    dateend = Dates.format(base.fechas[end], dateformat"u-yyyy")
    print(io, datestart, "-", dateend)
end

function summary(io::IO, cst::CountryStructure)
    datestart = Dates.format(cst.base[begin].fechas[begin], dateformat"u-yyyy")
    dateend = Dates.format(cst.base[end].fechas[end], dateformat"u-yyyy")
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