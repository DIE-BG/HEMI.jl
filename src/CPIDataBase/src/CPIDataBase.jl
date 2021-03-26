"""
    CPIDataBase

    Librería base para tipos y funcionalidad básica para manejo de datos del IPC a nivel desagregado de gastos básicos
"""
module CPIDataBase

using Dates

export CPIBase, CPIFullBase


# Definición de tipos para bases del IPC
include("types.jl")

# Métodos para carga de datos
include("loading.jl")

end # module
