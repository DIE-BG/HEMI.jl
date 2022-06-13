# Herramienta de evaluación de medidas de inflación (HEMI)

[![Build Status](https://github.com/DIE-BG/HEMI.jl/workflows/CI/badge.svg)](https://github.com/DIE-BG/HEMI.jl/actions)
[![Dev](https://img.shields.io/badge/docs-latest-blue.svg)](https://die-bg.github.io/HEMI.jl/dev)

Repositorio del proyecto de evaluación estadística de medidas de inflación
subyacente de Guatemala empleando una metodología de simulación con
*bootstrapping*. El proyecto ha sido realizado utilizando el [lenguaje de
programación Julia](https://julialang.org/) y el paquete
[DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/) para crear un
proyecto reproducible.

Para trabajar con este proyecto de manera local, realiza lo siguiente:

1. Instalar Julia 1.7 y Visual Studio Code.
2. Agrega el registro de la organización a tu instalación de Julia. En cualquier terminal interactiva (REPL) de Julia ejecuta el comando: 
```julia-repl
julia> ]
(@v1.7) pkg> registry add https://github.com/DIE-BG/RegistryDIE
    Cloning registry from "https://github.com/DIE-BG/RegistryDIE"
    (...)
``` 
Esto es necesario para obtener los paquetes [`CPIDataBase`](https://github.com/DIE-BG/CPIDataBase.jl), e [`InflationFunctions`](https://github.com/DIE-BG/InflationFunctions.jl), ya que estos no se encuentran en el registro [`General`](https://github.com/JuliaRegistries/General) de Julia.
 
3. Descarga o clona este repositorio. Ten en cuenta que los datos brutos de simulaciones normalmente no están incluidos en la historia de Git y se deben obtener de manera independiente o generar nuevamente con los programas de simulación.

4. Abre una terminal interactiva de Julia y haga: 
```julia-repl
julia> using Pkg
julia> Pkg.add("DrWatson") # instalar globalmente, para utilizar `quickactivate`
julia> Pkg.activate("ruta/hacia/el/proyecto")
julia> Pkg.instantiate()
```

Este último comando instalará todos los paquetes necesarios para poder ejecutar los scripts y todo lo demás debería funcionar inmediatamente. Notar que esto instala [`DrWatson`](https://juliadynamics.github.io/DrWatson.jl/stable/) en el entorno global de Julia, lo que permite utilizar la macro `@quickactivate` para activar el entorno del proyecto al ejecutar cualquier *script* desde la terminal del sistema. 

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
