"""
    CPIDataBase

    Librería base para tipos y funcionalidad básica para manejo de datos del IPC a nivel desagregado de gastos básicos
"""
module CPIDataBase

greet() = print("Hello World!")
f(x) = 2x+1
g(x) = 2x^2+2

# export f

include("types.jl")
export CPIBase

end # module
