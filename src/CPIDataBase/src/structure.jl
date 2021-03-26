# structure.jl - Objetos de estructura y funciones para su manejo

import Base: show

"""
    CountryStructure{T<:AbstractFloat}

Estructura mínima del IPC de cada una de las bases para un país. 
Se representa por:
- el vector de `fechas` de la base, 
- una matriz de índices de precios `ipc` que incluye la fila con los índices del númbero base. 
- una matriz de variaciones intermensuales de índices de precios `v`.
- un vector de ponderaciones `w` asociado a las columnas de `ipc` y `w`.
Los gastos básicos están representados en las columnas de `v` e `ipc`, mientras
que las filas representan los períodos.
"""
struct CPIBase{T<:AbstractFloat}
    fechas::Vector{Date}
    ipc::Matrix{T}
    v::Matrix{T}
    w::Vector{T}
end

"""
    CountryStructure{T<:AbstractFloat}

Estructura que representa el conjunto de bases del IPC de un país, 
posee el campo `base`, que es un vector de la estructura `CPIBase`
"""
struct CountryStructure{T<:AbstractFloat}
    base::Vector{CPIBase{T}}
end


"""
    CPIBase(df::T, gb::T, base_date::Date) where T <: AbstractDataFrame

Este constructor devuelve una estructura `CPIBase` a partir del DataFrame 
de índices de precios `df`, que contiene en las columnas las categorías o gastos 
básicos del IPC y en las filas su evolución temporal. Las ponderaciones se obtienen 
de la estructura `gb`, en la columna denominada `:Ponderacion`.
"""
function CPIBase(df::T, gb::T, base_date::Date) where T <: AbstractDataFrame
    # Obtener matriz de índices de precios
    ipc_mat = convert(Matrix, df[!, 2:end])
    # Matrices de variaciones intermensuales de índices de precios
    v_mat = 100 .* (ipc_mat[2:end, :] ./ ipc_mat[1:end-1, :] .- 1)
    # Ponderación de gastos básicos o categorías
    w = gb[!, :Ponderacion]
    # Actualización de fechas
    fechas = base_date .+ Month.(1:size(v_mat, 1))
    # Estructura de base del IPC
    return CPIBase(fechas, ipc_mat, v_mat, w)
end


"""
    CountryStructure(df_00::T, gb_00::T, df_10::T, gb_10::T) where T <: AbstractDataFrame

Constructor de estructura de país a partir de dos conjuntos de DataFrames de índices de precios
y de gastos básicos. Corresponde a la estructura actual del IPC de Guatemala. 
"""
function CountryStructure(df_00::T, gb_00::T, df_10::T, gb_10::T) where T <: AbstractDataFrame
    
    # Bases del IPC
    base_2000 = CPIBase(df_00, gb_00, Date(2000,12,1))
    base_2010 = CPIBase(df_10, gb_10, Date(2010,12,1))

    # Crear la estructura de país
    return CountryStructure([base_2000, base_2010])
end

function show(io::IO, cpi_base::CPIBase)
    println(io, "* ", typeof(cpi_base))
    println(io, "|─> Fechas: ", cpi_base.fechas[begin], " - ", cpi_base.fechas[end])
    println(io, "|─> Gastos: ", size(cpi_base.ipc))
end

function show(io::IO, country_st::CountryStructure)
    println(io, typeof(country_st), ": ", length(country_st.base), " bases") 
    for base in country_st.base
        show(io, base)
    end
end


"""
    get_base_period(cpi_base::CPIBase)
Devuelve una fecha (`Date`) con el período base utilizado por `cpi_base`
"""
function get_base_period(cpi_base::CPIBase)
    return cpi_base.fechas[begin] - Month(1)
end


"""
    GTStructure

Alias for `CountryStructure`
"""
const GTStructure = CountryStructure
