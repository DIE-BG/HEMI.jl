# Herramienta de evaluación de medidas de inflación (HEMI)

Repositorio del proyecto de evaluación de medidas de inflación en el [lenguaje
de programación Julia](https://julialang.org/), utilizando
[DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/) para crear un
proyecto reproducible.

Sus autores principales son Juan Carlos Castañeda, Rodrigo Chang, Oscar Solís,
Mauricio Vargas y otros colaboradores, todos miembros del Departamento de
Investigaciones Económicas del Banco de Guatemala. 

Para reproducir localmente este proyecto, haga lo siguiente:

1. Descarga o clona el repositorio. Tenga en cuenta que los datos brutos de
    simulaciones normalmente no se incluyen en la historia de git y es posible
    que deban obtenerse de forma independiente.
2. Abra una consola de Julia y haga: 
   ```
   julia> using Pkg
   julia> Pkg.add("DrWatson") # instalar globalmente, para utilizar `quickactivate`
   julia> Pkg.activate("ruta/al/proyecto")
   julia> Pkg.instantiate()
   ```

Este último comando instalará todos los paquetes necesarios para poder ejecutar
los scripts y todo lo demás debería funcionar inmediatamente. 

---
*Este es un proyecto de investigación reproducible y no necesariamente representa la postura, políticas y/o recomendaciones del Banco de Guatemala, sus autoridades y funcionarios*. 