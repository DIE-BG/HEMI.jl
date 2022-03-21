# Guía rápida

En esta sección se documentan instrucciones generales para utilizar el proyecto y agregar nuevas funcionalidades. 

## Cómo instanciar el proyecto en mi computadora

Para trabajar con este proyecto de manera local, realiza lo siguiente:

1. Agrega el registro de la organización a tu instalación de Julia. En cualquier terminal interactiva (REPL) de Julia ejecuta el comando: 
```julia-repl
julia> ]
(@v1.6) pkg> registry add https://github.com/DIE-BG/RegistryDIE
    Cloning registry from "https://github.com/DIE-BG/RegistryDIE"
    (...)
``` 
Esto es necesario para obtener los paquetes [`CPIDataBase`](https://github.com/DIE-BG/CPIDataBase.jl), e [`InflationFunctions`](https://github.com/DIE-BG/InflationFunctions.jl), ya que estos no se encuentran en el registro [`General`](https://github.com/JuliaRegistries/General) de Julia.
 
2. Descarga o clona este repositorio. Ten en cuenta que los datos brutos de simulaciones normalmente no están incluidos en la historia de Git y se deben obtener de manera independiente o generar nuevamente con los programas de simulación.

3. Abre una terminal interactiva de Julia y haga: 
```julia-repl
julia> using Pkg
julia> Pkg.add("DrWatson") # instalar globalmente, para utilizar `quickactivate`
julia> Pkg.activate("ruta/hacia/el/proyecto")
julia> Pkg.instantiate()
```

Este último comando instalará todos los paquetes necesarios para poder ejecutar los scripts y todo lo demás debería funcionar inmediatamente. Notar que esto instala [`DrWatson`](https://juliadynamics.github.io/DrWatson.jl/stable/) en el entorno global de Julia, lo que permite utilizar la macro `@quickactivate` para activar el entorno del proyecto al ejecutar cualquier *script* desde la terminal del sistema. 

Una vez el proyecto se haya instanciado correctamente, podemos ejecutar un *script* de prueba. Por ejemplo, podemos ejecutar el archivo `scripts/intro.jl` o bien, crear uno nuevo siguiendo las instrucciones en [Ejemplo para computar trayectoria de inflación](@ref).

## Trabajando en Visual Studio Code
Para trabajar en el proyecto utilizando [Visual Studio Code](https://code.visualstudio.com/) es necesario tener instalada la [extensión de Julia](https://www.julia-vscode.org/). Usualmente, abrimos el directorio raíz del proyecto en el editor con la opción `File -> Open Folder...` y la extensión de Julia se encarga automáticamente de activar el entorno de paquetes del proyecto, denominado también como `HEMI`. A su vez, en la primera vez que se trabaje en el proyecto es necesario instanciarlo de la siguiente manera:

```julia-repl
julia> ]
(HEMI) pkg> instantiate
(...)
```

El gestor de paquetes integrado de Julia (`Pkg`) se encargará de instalar todos los paquetes automáticamente. El detalle de los paquetes se encuentra en el archivo `Manifest.toml`. Este archivo de manifiesto de versiones de los paquetes permite que todos los integrantes del equipo puedan trabajar sobre un proyecto reproducible. 


## Cómo cargar los datos
Ejecutar el archivo `scripts/load_data.jl` para generar los archivos binarios de datos en formato JLD2. Este programa se debe ejecutar una sola vez o cada vez que se desean actualizar los datos. Este programa genera los archivos `gtdata64.jld2` y `gtdata32.jld2`. El último corresponde a los datos con precisión de punto flotante de 32 bits, cuya precisión es suficiente para representar los valores de las medidas de inflación y ayuda a generar los cálculos más rápidamente. 

El archivo `gtdata32.jld2` es cargado automáticamente al utilizar el módulo `HEMI`. Este módulo carga los datos del IPC de Guatemala en el objeto `GTDATA`, el cual es un objeto de tipo [`UniformCountryStructure`](@ref). Provee además los objetos `GT00` y `GT10`, los cuales son de tipo [`VarCPIBase`](@ref) y los objetos `FGT00` y `FGT10`, los cuales son de tipo [`FullCPIBase`](@ref).

Por ejemplo, ejecute las siguientes instrucciones en un *script* de pruebas: 

```julia 
# Activa el entorno del proyecto y ejecuta `using HEMI` para cargar los datos
using DrWatson
@quickactivate :HEMI

# Variables exportadas por el módulo HEMI para utilizar en el script
GTDATA
GT00
GT10
FGT00
FGT10
```

## Qué son los módulos

Los módulos permiten empaquetar funciones y datos para ser cargados en un
archivo con la instrucción `using` de Julia. En este proyecto, los módulos más importantes son: 
- `HEMI`: es un módulo envolvente (*wrapper*), que carga los paquetes más utilizados en el proyecto. Actualmente carga y reexporta los paquetes `Dates`, `CPIDataBase`, `Statistics`, `JLD2`, `InflationFunctions` e `InflationEvalTools`. Además, carga y exporta los datos del IPC en las variables `GT00`, `GT10`, `FGT00`, `FGT10` y `GTDATA`. Revisar el archivo `src/HEMI.jl`.
- `CPIDataBase`: este módulo provee los tipos y su funcionalidad básica para manejar los datos del IPC. También define la interfaz principal para extender y crear nuevas funciones de inflación. 
- `InflationFunctions`: este módulo extiende la funcionalidad de `CPIDataBase` y exporta nuevas metodologías de cómputo de inflación interanual. 
- `InflationEvalTools`: este módulo contiene los tipos y funciones necesarias para definir los ejercicios de simulación y evaluación estadística de las medidas de inflación. 

## Cómo generar un nuevo *script* para jugar con el proyecto 

1. Se debe crear un script en el directorio `scripts`. Por ejemplo, `scripts/test_funcionalidad.jl`. 
2. Activar el proyecto y cargar los datos. Véase la sección [Utilización en scripts de evaluación](@ref).


## Cómo computar una trayectoria de inflación con los datos

Crear un archivo de prueba en `scripts` llamado `test_hello_HEMI.jl` e incluir el siguiente código para computar la variación interanual del IPC.

```julia 
## Activar el entorno del proyecto y cargar los datos
using DrWatson
@quickactivate :HEMI

## Utilizar la función de inflación InflationTotalCPI sobre GTDATA
totalfn = InflationTotalCPI()
traj_infl = totalfn(GTDATA)
```


## Cómo crear una función de inflación

Para crear una nueva función de inflación en `InflationFunctions`: 

1. Crear un tipo concreto que sea subtipo de `InflationFunction`. Como convención, hemos escogido utilizar el prefijo `Inflation` como parte del nombre del tipo y escribir este en inglés. Por ejemplo `InflationNewMethodology`.
2. Extender el método `measure_name` para el nuevo tipo.
3. Extender el método que opera sobre objetos `VarCPIBase`. 
   * Dependiendo de la medida de la cual se trate, podría ser necesario redefinir el comportamiento del método con argumentos `(::CountryStructure, ::CPIVarInterm)`. Esto podría ser necesario si la función de inflación utiliza sus parámetros de manera diferente para cada base de tipo `VarCPIBase`, por ejemplo, en la medida de inflación subyacente MAI o en la medida de exclusión fija de gastos básicos. 
4. Se debe incluir el archivo de código fuente con la nueva función de inflación y agregar la sentencia `export` en el archivo principal del módulo: `InflationFunctions.jl`.

Para agregar las pruebas sobre el nuevo tipo, el script principal se encuentra en `InflationFunctions/test/runtests.jl`. Ver el ejemplo con la función `InflationSimpleMean`.
