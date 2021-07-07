# # Cargar y explorar las estructuras de datos del IPC

# Cargamos DrWatson y activamos el proyecto. Esto a su vez, carga los datos del
# IPC de Guatemala en las variables `gt00`, `gt10` y `gtdata`. Las primeras dos
# representan las bases del IPC 2000 y 2010. La estructura `gtdata` representa
# una colección de bases del IPC, la cual conforma la estructura del IPC del
# país (`gtdata` es de tipo `UniformCountryStructure`, el cual es un tipo
# concreto del tipo `CountryStructure`).
using DrWatson
@quickactivate :HEMI 

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

# ## Obteniendo datos en direferentes rangos
# Esta estructura de país puede ser indexada para obtener las bases de tipo
# `VarCPIBase` que contiene. Por ejemplo: 
gtdata[1]

# También puede ser indexada por la fecha inicial y final, o bien, únicamente por la fecha final: 
gtdata[Date(2005, 1), Date(2019, 12)]
#-
gtdata[Date(2019, 12)]

# Al indexar de esta manera se crea una copia del `UniformCountryStructure`.


# ## Funciones de utilidad
# Para obtener el número de períodos de una base de tipo `VarCPIBase` utilizamos la función `periods`: 
periods(gt00)

# De igual forma, este método aplica para un `CountryStructure`:
periods(gtdata)