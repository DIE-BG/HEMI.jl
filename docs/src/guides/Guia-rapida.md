# Guía rápida

En esta sección se documentan instrucciones generales para agregar nuevas funcionalidades al proyecto. 

## Cómo instanciar el proyecto en mi computadora

Seguir las instrucciones en [Inicio](@ref).


## Cómo generar un nuevo script para jugar con el proyecto 

1. Ejecutar el archivo `scripts/load_data.jl` para generar el archivo binario de datos en formato JLD2. Este programa se debe ejecutar una sola vez o cada vez que se desean actualizar los datos. 
2. Se debe crear un script en el directorio `scripts`. Por ejemplo, `scripts/test_funcionalidad.jl`. 
3. Activar el proyecto y cargar los datos. Véase la sección [Utilización en scripts de evaluación](@ref).


## Cómo computar una trayectoria de inflación con los datos

1. Ejecutar el archivo `scripts/load_data.jl` para generar el archivo binario de datos en formato JLD2. Este programa se debe ejecutar una sola vez o cada vez que se desean actualizar los datos. 
2. Crear un archivo de prueba en `scripts` llamado `testHEMI.jl` e incluir el siguiente código para computar la variación interanual del IPC.

```julia 
## Activar el entorno del proyecto y cargar los datos
using DrWatson
@quickactivate :HEMI

## Utilizar la función de inflación InflationTotalCPI sobre gtdata
totalfn = InflationTotalCPI()
traj_infl = totalfn(gtdata)
```


## Cómo crear una función de inflación

Para crear una nueva función de inflación en `InflationFunctions`: 

1. Crear un tipo concreto que sea subtipo de `InflationFunction`. 
2. Extender el método `measure_name`.
3. Extender el método que opera sobre objetos `VarCPIBase`. 
   * Dependiendo de la medida de la cual se trate, podría ser necesario redefinir el comportamiento del método con argumentos `(::CountryStructure, ::CPIVarInterm)`. Esto podría ser necesario si la función de inflación utiliza sus parámetros de manera diferente para cada base de tipo `VarCPIBase`, por ejemplo, en la medida de inflación subyacente MAI o en la medida de exclusión fija de gastos básicos. 
4. Se debe incluir el archivo de código fuente con la nueva función de inflación y agregar la sentencia `export` en el archivo principal del módulo: `InflationFunctions.jl`.

Para agregar las pruebas sobre el nuevo tipo, el script principal se encuentra en `InflationFunctions/test/runtests.jl`. Ver el ejemplo con la función `InflationSimpleMean`
