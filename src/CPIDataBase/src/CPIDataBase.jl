"""
    CPIDataBase

    Librería base para tipos y funcionalidad básica para manejo de datos del IPC a nivel desagregado de gastos básicos
"""
module CPIDataBase

    using Dates
    using DataFrames

    # Export types
    export CPIBase, VarCPIBase, CountryStructure

    # Export functions
    export capitalize

    # Definición de tipos para bases del IPC
    include("types.jl")

    # Basic operations
    include("operations.jl")

end # module
