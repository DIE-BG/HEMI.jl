# Herramienta de evaluación de medidas de inflación (HEMI)

[![Build Status](https://github.com/DIE-BG/HEMI/workflows/CI/badge.svg)](https://github.com/DIE-BG/HEMI/actions)
[![Dev](https://img.shields.io/badge/docs-latest-blue.svg)](https://die-bg.github.io/HEMI/dev)

Repositorio del proyecto de evaluación estadística de medidas de inflación
subyacente de Guatemala empleando una metodología de simulación con
*bootstrapping*. El proyecto ha sido realizado utilizando el [lenguaje de
programación Julia](https://julialang.org/) y el paquete
[DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/) para crear un
proyecto reproducible.

Para trabajar con este proyecto de manera local, realiza lo siguiente:

1. Agrega el registro de la organización a tu instalación de Julia: 
```julia-repl
julia> ]
(@v1.6) pkg> registry add https://github.com/DIE-BG/RegistryDIE
    Cloning registry from "https://github.com/DIE-BG/RegistryDIE"
    (...)
``` 
Esto es necesario para obtener los paquetes [`CPIDataBase`](https://github.com/DIE-BG/CPIDataBase.jl), `CPIDataGT`, e [`InflationFunctions`](https://github.com/DIE-BG/InflationFunctions.jl), ya que estos no se encuentran  en el registro general.
 
2. Descarga o clona este repositorio. Ten en cuenta que los datos brutos de simulaciones normalmente no están incluidos en la historia de Git y se deben obtener de manera independiente o generar nuevamente.

3. Abra una consola de Julia y haga: 
```julia-repl
julia> using Pkg
julia> Pkg.add("DrWatson") # instalar globalmente, para utilizar `quickactivate`
julia> Pkg.activate("ruta/hacia/el/proyecto")
julia> Pkg.instantiate()
```

Este último comando instalará todos los paquetes necesarios para poder ejecutar
los scripts y todo lo demás debería funcionar inmediatamente. 

## Trabajando en Visual Studio Code
Al trabajar en Visual Studio Code, únicamente es necesario abrir el directorio del proyecto y la extensión de Julia se encarga automáticamente de activar el entorno del proyecto. En este caso, únicamente es necesario instanciar el proyecto de la siguiente manera:

```julia-repl
julia> ]
(@v1.6) pkg> instantiate
(...)
```