# Inicio

Para empezar a utilizar este proyecto, se debe clonar el repositorio e instanciar el proyecto. Para esto, debemos abrir un REPL de Julia y ejecutar: 

```
julia> using Pkg
julia> Pkg.add("DrWatson") 
julia> Pkg.activate("ruta/hacia/el/proyecto")
julia> Pkg.instantiate()
```

Notar que esto instala [`DrWatson`](https://juliadynamics.github.io/DrWatson.jl/stable/) en el entorno global de Julia, lo que permite utilizar la macro `@quickactivate` para activar el entorno del proyecto. 

Una vez el proyecto se haya instanciado correctamente, podemos ejecutar un script de prueba. Por ejemplo, podemos ejecutar el archivo `scripts/intro.jl` o bien, crear uno nuevo siguiendo las instrucciones en [Ejemplo para computar trayectoria de inflación](@ref).

