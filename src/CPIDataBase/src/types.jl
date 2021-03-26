import Base: show

# Tipo abstracto para definir contenedores del IPC
abstract type AbstractCPIBase end

# Tipos para los vectores de fechas
const DATETYPE = Union{Vector{Date}, StepRange{Date, Month}}

"""
    CPIFullBase{T<:AbstractFloat} <: AbstractCPIBase

Contenedor completo para datos del IPC de un país. Se representa por:
- Matriz de índices de precios `ipc` que incluye la fila con los índices del númbero base. 
- Matriz de variaciones intermensuales `v`. En las filas contiene los períodos y en las columnas contiene los gastos básicos.
- Vector de ponderaciones `w` de los gastos básicos.
- Fechas correspondientes `fechas` (por meses).
"""
Base.@kwdef struct CPIFullBase{T<:AbstractFloat} <: AbstractCPIBase
    ipc::Matrix{T}
    v::Matrix{T}
    w::Vector{T}
    fechas::DATETYPE
end


"""
    CPIBase{T<:AbstractFloat} <: AbstractCPIBase

Contenedor genérico para datos del IPC. Se representa por:
- Matriz de índices de precios `ipc` que incluye la fila con los índices del númbero base. 
- Matriz de variaciones intermensuales `v`. En las filas contiene los períodos y en las columnas contiene los gastos básicos.
- Vector de ponderaciones `w` de los gastos básicos.
- Fechas correspondientes `fechas` (por meses).
"""
Base.@kwdef struct CPIBase{T<:AbstractFloat} <: AbstractCPIBase
    v::Matrix{T}
    w::Vector{T}
    fechas::DATETYPE
end

# Métodos para mostrar los tipos
function Base.show(io::IO, base::AbstractCPIBase)
    periodos = typeof(base) == CPIBase ? size(base.v, 1) : size(base.v, 1) + 1
    println(io, typeof(base), ": ", periodos, " períodos × ", size(base.v)[2], " gastos básicos")
    println(io, "|─> Fechas: ", base.fechas[begin], " - ", base.fechas[end])
end
