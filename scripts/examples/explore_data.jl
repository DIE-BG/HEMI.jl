# # Cargar y explorar las estructuras de datos del IPC

# Cargamos DrWatson y activamos el proyecto. Esto a su vez, carga los datos del
# IPC de Guatemala en las variables `GT00`, `GT10` y `GTDATA`. Las primeras dos
# representan las bases del IPC 2000 y 2010. La estructura `GTDATA` representa
# una colección de bases del IPC, la cual conforma la estructura del IPC del
# país (`GTDATA` es de tipo `UniformCountryStructure`, el cual es un tipo
# concreto del tipo `CountryStructure`).
using DrWatson
@quickactivate :HEMI 

# Veamos la estructura de GT00: 
GT00

# Este tipo contiene los siguientes campos: 
# - la matriz de variaciones intermensuales de índices de precios en el campo `v`. 
propertynames(GT00)

# De manera similar, los datos de la base 2010 del IPC: 
GT10 

#-
propertynames(GT10)

# Ahora utilizamos el contenedor `UniformCountryStructure`, el cual contiene una tupla de objetos `VarCPIBase`: 
GTDATA

# ## Obteniendo datos en direferentes rangos
# Esta estructura de país puede ser indexada para obtener las bases de tipo
# `VarCPIBase` que contiene. Por ejemplo: 
GTDATA[1]

# También puede ser indexada por la fecha inicial y final, o bien, únicamente por la fecha final: 
GTDATA[Date(2005, 1), Date(2019, 12)]
#-
GTDATA[Date(2019, 12)]

# Al indexar de esta manera se crea una copia del `UniformCountryStructure`.


# ## Funciones de utilidad
# Para obtener el número de períodos de una base de tipo `VarCPIBase` utilizamos la función `periods`: 
periods(GT00)

# De igual forma, este método aplica para un `CountryStructure`:
periods(GTDATA)