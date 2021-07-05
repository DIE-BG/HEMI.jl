# # Cargar y explorar las estructuras de datos del IPC

# Cargamos DrWatson y activamos el proyecto
using DrWatson
@quickactivate :HEMI 

# Cargamos los datos del IPC de Guatemala
using JLD2
@load datadir("guatemala", "gtdata32.jld2") gt00 gt10

# Veamos la estructura de gt00: 
gt00

# Este tipo contiene los siguientes campos: 
# - la matriz de variaciones intermensuales de índices de precios en el campo `v`. 
propertynames(gt00)

# De manera similar, los datos de la base 2010 del IPC: 
gt10 

#-
propertynames(gt10)

# Ahora utilizamos el contenedor `UniformCountryStructure`, el cual contiene una tupla de objetos `VarCPIBase`: 
gtdata