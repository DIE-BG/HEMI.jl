# Métodos para carga de datos 

"""
    CPIBase(df::T, gb::T, base_date::Date) where T <: AbstractDataFrame

Este constructor devuelve una estructura `CPIBase` a partir del DataFrame 
de índices de precios `df`, que contiene en las columnas las categorías o gastos 
básicos del IPC y en las filas los períodos por meses. Las ponderaciones se obtienen 
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
    # modificar este código
    # agregar DataFrames a las deps de CPIDataBase
    return CPIBase(fechas, ipc_mat, v_mat, w)
end