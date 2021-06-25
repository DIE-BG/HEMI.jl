# Herramienta de evaluación de medidas de inflación (HEMI)

[![Build Status](https://github.com/DIE-BG/HEMI/workflows/CI/badge.svg)](https://github.com/DIE-BG/HEMI/actions)

Repositorio del proyecto de evaluación estadística de medidas de inflación
subyacente de Guatemala empleando una metodología de simulación con
*bootstrapping*. El proyecto ha sido realizado utilizando el [lenguaje de
programación Julia](https://julialang.org/) y el paquete
[DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/) para crear un
proyecto reproducible.

Para reproducir localmente este proyecto, haga lo siguiente:

1. Descarga o clona el repositorio. Tenga en cuenta que los datos brutos de
    simulaciones normalmente no se incluyen en la historia de git y es posible
    que deban obtenerse de forma independiente.
2. Abra una consola de Julia y haga: 
   ```
   julia> using Pkg
   julia> Pkg.add("DrWatson") # instalar globalmente, para utilizar `quickactivate`
   julia> Pkg.activate("ruta/hacia/el/proyecto")
   julia> Pkg.instantiate()
   ```

Este último comando instalará todos los paquetes necesarios para poder ejecutar
los scripts y todo lo demás debería funcionar inmediatamente. 