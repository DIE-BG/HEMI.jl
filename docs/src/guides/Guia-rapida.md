# Guía rápida

En esta sección se documentan instrucciones generales para utilizar el proyecto y agregar nuevas funcionalidades. 

## Cómo instanciar el proyecto en mi computadora

Seguir las instrucciones en [Inicio](@ref). Al abrir el directorio `HEMI/` en Visual Studio Code, el proyecto se activa automáticamente, por lo que solamente es necesario instanciar el proyecto y cargar los datos para empezar a trabajar. 

## Qué son los módulos

Los módulos permiten empaquetar funciones y datos para ser cargados en un
archivo con la instrucción `using` de Julia. En este proyecto, los módulos más importantes son: 
- `HEMI`: es un módulo envolvente (*wrapper*), que carga los paquetes más utilizados en el proyecto. Actualmente carga y reexporta los paquetes `Dates`, `CPIDataBase`, `Statistics` y `JLD2`. Además, carga y exporta los datos del IPC en las variables `gt00`, `gt10` y `gtdata`. Revisar el archivo `src/HEMI.jl`.
- `CPIDataBase`: este módulo provee los tipos y su funcionalidad básica para manejar los datos del IPC. También define la interfaz principal para extender y crear nuevas funciones de inflación. 
- `InflationFunctions`: este módulo extiende la funcionalidad de `CPIDataBase` y exporta nuevas metodologías de cómputo de inflación interanual. 
- `InflationEvalTools`: este módulo contiene los tipos y funciones necesarias para definir los ejercicios de simulación y evaluación estadística de las medidas de inflación. 


## Cómo cargar los datos
Ejecutar el archivo `scripts/load_data.jl` para generar el archivo binario de datos en formato JLD2. Este programa se debe ejecutar una sola vez o cada vez que se desean actualizar los datos. Este programa genera los archivos `gtdata.jld2` y `gtdata32.jld2`. El último corresponde a los datos con precisión de punto flotante de 32 bits, cuya precisión es suficiente para representar los valores de las medidas de inflación y ayuda a generar los cálculos más rápidamente. 

El archivo `gtdata32.jld2` es cargado automáticamente al utilizar el módulo `HEMI`, ejecutando las siguientes instrucciones: 

```julia 
## Activar el entorno del proyecto y ejecuta `using HEMI` para cargar los datos
using DrWatson
@quickactivate :HEMI

# Variables exportadas por el módulo HEMI para utilizar en el script
gtdata
gt00
gt10
```

Este módulo carga los datos del IPC de Guatemala en el objeto `gtdata`, el cual es un objeto de tipo [`UniformCountryStructure`](@ref). Provee además los objetos `gt00` y `gt10`, los cuales son de tipo [`VarCPIBase`](@ref).

## Cómo generar un nuevo script para jugar con el proyecto 

1. Se debe crear un script en el directorio `scripts`. Por ejemplo, `scripts/test_funcionalidad.jl`. 
2. Activar el proyecto y cargar los datos. Véase la sección [Utilización en scripts de evaluación](@ref).


## Cómo computar una trayectoria de inflación con los datos

Crear un archivo de prueba en `scripts` llamado `testHEMI.jl` e incluir el siguiente código para computar la variación interanual del IPC.

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

1. Crear un tipo concreto que sea subtipo de `InflationFunction`. Como convención, hemos escogido utilizar el prefijo `Inflation` como parte del nombre del tipo y escribir este en inglés. Por ejemplo `InflationNewMethodology`.
2. Extender el método `measure_name` para el nuevo tipo.
3. Extender el método que opera sobre objetos `VarCPIBase`. 
   * Dependiendo de la medida de la cual se trate, podría ser necesario redefinir el comportamiento del método con argumentos `(::CountryStructure, ::CPIVarInterm)`. Esto podría ser necesario si la función de inflación utiliza sus parámetros de manera diferente para cada base de tipo `VarCPIBase`, por ejemplo, en la medida de inflación subyacente MAI o en la medida de exclusión fija de gastos básicos. 
4. Se debe incluir el archivo de código fuente con la nueva función de inflación y agregar la sentencia `export` en el archivo principal del módulo: `InflationFunctions.jl`.

Para agregar las pruebas sobre el nuevo tipo, el script principal se encuentra en `InflationFunctions/test/runtests.jl`. Ver el ejemplo con la función `InflationSimpleMean`.
