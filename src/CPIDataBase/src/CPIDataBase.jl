"""
    CPIDataBase

    Librería base para tipos y funcionalidad básica para manejo de datos del IPC a nivel desagregado de gastos básicos
"""
module CPIDataBase

using Dates
using DataFrames

export CPIBase, VarCPIBase

# Definición de tipos para bases del IPC
include("types.jl")

end # module
