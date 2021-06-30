```@meta
CurrentModule = HEMI
```

# HEMI
```@autodocs
Modules = [HEMI]
```

## Utilización en scripts de evaluación

Este módulo se utiliza para cargar los paquetes principales utilizados en la evaluación de medidas de inflación. 

Si ya se ha ejecutado el script de carga de datos `scripts/load_data.jl`, este módulo carga los datos del IPC de Guatemala en el objeto `gtdata`, el cual es un objeto de tipo [`UniformCountryStructure`](@ref). Provee además los objetos `gt00` y `gt10`, los cuales son de tipo [`VarCPIBase`](@ref). 

Como se describe en la [documentación de DrWatson](https://juliadynamics.github.io/DrWatson.jl/dev/real_world/#Making-your-project-a-usable-module-1), existen proyectos en los que se deben cargar datos y funciones al inicio de cualquier archivo del proyecto. La estructura del proyecto en Julia permite englobar los paquetes más importantes en un módulo con el mismo nombre del proyecto. Por lo tanto, podemos utilizar el siguiente código al inicio de cada script para activar el proyecto y cargar los paquetes principales: 

```julia 
using DrWatson 
@quickactivate :HEMI

## Script de evaluación o pruebas
# ...
```

el cual es equivalente a 

```julia 
using DrWatson 
@quickactivate "HEMI"
using HEMI

## Script de evaluación o pruebas
# ...
```

## Ejemplo para computar trayectoria de inflación

1. Ejecutar el archivo `scripts/load_data.jl` para generar el archivo binario de datos en formato JLD2. 
2. Crear un archivo de prueba en `scripts` llamado `testHEMI.jl` e incluir el siguiente código para computar la variación interanual del IPC.

```julia 
## Activar el entorno del proyecto y cargar los datos
using DrWatson
@quickactivate :HEMI

## Utilizar la función de inflación InflationTotalCPI sobre gtdata
totalfn = InflationTotalCPI()
traj_infl = totalfn(gtdata)
```