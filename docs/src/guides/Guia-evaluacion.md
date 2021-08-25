# Guía de evaluación

En esta sección se documentan las configuraciones generales para la generación de distintos escenarios de evaluación.

## Escenario A: replica del trabajo efectuado en 2020 (criterios básicos a dic-19)

### Nombre para los directorios

- Directorio principal: `data\results\<nombre-medida>\Esc-A\`

### Descripción 
Este escenario pretende replicar los resultados obtenidos utilizando el lenguaje de programación MATLAB, el cual se utilizó en el año 2020 para realizar la evaluación con información hasta diciembre de 2019.

Los parámetros de configuración en este caso son los siguientes:

 1. Período de Evaluación: Diciembre 2001 - Diciembre 2019, `ff = Date(2019, 12)`.
 2. Trayectoria de inflación paramétrica con cambio de base sintético: 2 cambios de base cada 3 años,  [`InflationTotalRebaseCPI(36, 2)`].
 3. Método de remuestreo de extracciones estocásticas independientes (Remuestreo por meses de ocurrencia), [`ResampleScrambleVarMonths()`].
 4. Muestra completa para evaluación, [`SimConfig`].

!!! note 
    
    En este escenario **no** es necesario llevar a cabo el proceso de optimización, ya que es un escenario de comparación para replicar los resultados obtenidos con la versión anterior de la herramienta.

En este caso, una configuración de simulación, para evaluar el Percentil Equiponderado 69, estaría dada por:

```julia
# Instacias para Escenario A
inflfn     = InflationPercentileEq(69)
resamplefn = ResampleScrambleVarMonths()
trendfn    = TrendRandomWalk()
paramfn    = InflationTotalRebaseCPI(36, 2)
nsim       = 125_000
ff         = Date(2019, 12)

 # Configuración de simulación
config = SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, ff)
```
```julia
julia> config = SimConfig(InflationPercentileEq(69), ResampleScrambleVarMonths(), TrendRandomWalk(), InflationTotalRebaseCPI(36, 2), 125_000, Date(2019, 12))      
SimConfig{InflationPercentileEq, ResampleScrambleVarMonths, TrendRandomWalk{Float32}}
|─> Función de inflación            : Percentil equiponderado 69.0
|─> Función de remuestreo           : Bootstrap IID por meses de ocurrencia
|─> Función de tendencia            : Tendencia de caminata aleatoria
|─> Método de inflación paramétrica : Variación interanual IPC con cambios de base sintéticos (36, 2)
|─> Número de simulaciones          : 10000
|─> Fin set de entrenamiento        : 2019-12-01
```



## Escenario B: extender el trabajo efectuado en 2020 (criterios básicos a dic-20)

### Nombre para los directorios

- Directorio principal: `data\results\<nombre-medida>\Esc-B\`

### Descripción 

Este escenario pretende evaluar las medidas de inflación utilizando la información hasta diciembre de 2020, utilizando los mismos parámetros de configuración que en el escenario A.

Los parámetros de configuración en este caso son los siguientes:

1. Período de Evaluación: Diciembre 2001 - Diciembre 2020, `ff = Date(2020, 12)`.
 1. Trayectoria de inflación paramétrica con cambio de base sintético: 2 cambios de base cada 3 años,  [`InflationTotalRebaseCPI(36, 2)`].
 2. Método de remuestreo de extracciones estocásticas independientes (Remuestreo por meses de ocurrencia), [`ResampleScrambleVarMonths()`].
 3. Muestra completa para evaluación, [`SimConfig`].


!!! note

    A diferencia del Escenario A, en este escenario **sí** se debe llevar a cabo la
    optimización de la medida, ya que se ha agregado un conjunto de nuevos datos
    correspondientes al año 2020.

En este caso, una configuración de simulación, para evaluar el Percentil Equiponderado 69, estaría dada por:

```julia
# Instacias para Escenario B
inflfn     = InflationPercentileEq(69)
resamplefn = ResampleScrambleVarMonths()
trendfn    = TrendRandomWalk()
paramfn    = InflationTotalRebaseCPI(36, 2)
nsim       = 125_000
ff         = Date(2020, 12)

 # Configuración de simulación
config = SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, ff)
```
```julia
julia> config = SimConfig(InflationPercentileEq(69), ResampleScrambleVarMonths(), TrendRandomWalk(), InflationTotalRebaseCPI(36, 2), 125_000, Date(2020,12))       
SimConfig{InflationPercentileEq, ResampleScrambleVarMonths, TrendRandomWalk{Float32}}
|─> Función de inflación            : Percentil equiponderado 69.0
|─> Función de remuestreo           : Bootstrap IID por meses de ocurrencia
|─> Función de tendencia            : Tendencia de caminata aleatoria
|─> Método de inflación paramétrica : Variación interanual IPC con cambios de base sintéticos (36, 2)
|─> Número de simulaciones          : 10000
|─> Fin set de entrenamiento        : 2020-12-01
```


## Escenario C: Evaluación de criterios básicos con cambio de parámetro de evaluación

### Nombre para los directorios

Es requerido llevar a cabo la optimización de la medida, para ambos períodos de evaluación. Se debe nombrar cada escenario como `C19` y `C20`.

- Directorio principal: `data\results\<nombre-medida>\Esc-C\`
  - Escenario hasta diciembre 2019: `C19`
  - Escenario hasta diciembre 2020: `C20`

### Descripción 

Este escenario pretende evaluar las medidas de inflación cambiando la trayectoria de inflación paramétrica por una con cambio de base sintético cada cinco años, respecto a la configuración del escenario A.

Los parámetros de configuración en este caso son los siguientes:

 1. Período de Evaluación: 
    1.   Diciembre 2001 - Diciembre 2019, `ff = Date(2019, 12)`
    2.   Diciembre 2001 - Diciembre 2020, `ff = Date(2020, 12)`
 2. Trayectoria de inflación paramétrica con cambios de base cada 5 años, [`InflationTotalRebaseCPI(60)`].
 3.  Método de remuestreo de extracciones estocásticas independientes (Remuestreo por meses de ocurrencia), [`ResampleScrambleVarMonths()`].
 4. Muestra completa para evaluación [`SimConfig`].

En este caso, una configuración de simulación, para evaluar el Percentil Equiponderado 69, estaría dada por:

```julia
## Definición de parámetros de simulación
inflfn     = InflationPercentileEq(69)
resamplefn = ResampleScrambleVarMonths()
trendfn    = TrendRandomWalk()
paramfn    = InflationTotalRebaseCPI(60)
nsim       = 125_000
ff19       = Date(2019, 12)
ff20       = Date(2020, 12)

 # Configuración de simulación*
 
config19 = SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, ff19)
config20 = SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, ff20)
```

```julia
julia> config19 = SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, ff19)
SimConfig{InflationPercentileEq, ResampleScrambleVarMonths, TrendRandomWalk{Float32}}
|─> Función de inflación            : Percentil equiponderado 69.0
|─> Función de remuestreo           : Bootstrap IID por meses de ocurrencia
|─> Función de tendencia            : Tendencia de caminata aleatoria
|─> Método de inflación paramétrica : Variación interanual IPC con cambios de base sintéticos (60, 0)
|─> Número de simulaciones          : 10000
|─> Fin set de entrenamiento        : 2019-12-01

julia> config20 = SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, ff20)
SimConfig{InflationPercentileEq, ResampleScrambleVarMonths, TrendRandomWalk{Float32}}
|─> Función de inflación            : Percentil equiponderado 69.0
|─> Función de remuestreo           : Bootstrap IID por meses de ocurrencia
|─> Función de tendencia            : Tendencia de caminata aleatoria
|─> Método de inflación paramétrica : Variación interanual IPC con cambios de base sintéticos (60, 0)
|─> Número de simulaciones          : 10000
|─> Fin set de entrenamiento        : 2020-12-01
```


## Escenario D: Evaluación de criterios básicos con cambio en metodología de remuestreo

### Nombre para los directorios

- Directorio principal: `data\results\<nombre-medida>\Esc-D\`
  - Escenario hasta diciembre 2019 y cambios de base cada 3 años: `D19-36`
  - Escenario hasta diciembre 2020 y cambios de base cada 5 años: `D19-60`
  - Escenario hasta diciembre 2019 y cambios de base cada 3 años: `D20-36`
  - Escenario hasta diciembre 2020 y cambios de base cada 5 años: `D20-60`

### Descripción 
Este escenario pretende evaluar las medidas de inflación cambiando el método de remuestreo por el de extracciones estocásticas por bloques estacionarios. 

Los parámetros de configuración en este caso son los siguientes:
 1. Período de Evaluación: 
    1.   Diciembre 2001 - Diciembre 2019, `ff = Date(2019, 12)`
    2.   Diciembre 2001 - Diciembre 2020, `ff = Date(2020, 12)`
 2. Trayectoria de inflación paramétrica 
    1. Con cambios de base cada 3 años, [`InflationTotalRebaseCPI(36, 2)`].
    2. Con cambios de base cada 5 años, [`InflationTotalRebaseCPI(60)`].
 3.  Método de remuestreo Remuestreo bloques estacionarios, [`ResampleSBB(36)`].
 4. Muestra completa para evaluación [`SimConfig`].

En este caso, una configuración de simulación, para evaluar el Percentil Equiponderado 69, estaría dada por:

```julia
## Definición de parámetros de simulación
inflfn     = InflationPercentileEq(69)
resamplefn = ResampleSBB(36)
trendfn    = TrendRandomWalk()
paramfn1    = InflationTotalRebaseCPI(36, 2)
paramfn2    = InflationTotalRebaseCPI(60)
nsim       = 125_000
ff19       = Date(2019,12)
ff20       = Date(2020, 12)

 # Configuración de simulación*

# Para período Diciembre 2001 - Diciembre 2019
config19_1 = SimConfig(inflfn, resamplefn, trendfn, paramfn1, nsim, ff19)
config19_2 = SimConfig(inflfn, resamplefn, trendfn, paramfn2, nsim, ff19)
# Para período Diciembre 2001 - Diciembre 2020
config20_1 = SimConfig(inflfn, resamplefn, trendfn, paramfn1, nsim, ff20)
config20_2 = SimConfig(inflfn, resamplefn, trendfn, paramfn2, nsim, ff20)
```

!!! note 

    Las configuraciones anteriores se hacen manualmente. También se puede
    utilizar `dict_list` para crear diccionarios de simulación con las distintas
    variantes de funciones o fechas finales.
    
    ```julia
    inflfn     = InflationPercentileEq(69)
    resamplefn = ResampleSBB(36)
    trendfn    = TrendRandomWalk()
    
    paramfn1    = InflationTotalRebaseCPI(36, 2)
    paramfn2    = InflationTotalRebaseCPI(60)
    
    dict_eval = Dict(
       :inflfn => inflfn, 
       :resamplefn => resamplefn, 
       :trendfn => trendfn,
       :paramfn => [paramfn1, paramfn2],
       :nsim => 125_000,
       :traindate => [Date(2019, 12), Date(2020, 12)]) |> dict_list
    ```



## Escenario E: Evaluación con nuevos criterios para evaluación de combinación lineal fuera de muestra

### Nombre para los directorios

- Directorio principal: `data\results\<nombre-medida>\Esc-E\`
  - Escenario hasta diciembre 2018 y cambios de base cada 5 años. 

### Descripción 
Este escenario pretende evaluar las medidas de inflación cambiando la metodología de remuestreo y la trayectoria paramétrica para obtener las mejores medidas en el período de evaluación de diciembre de 2001 a diciembre de 2018. La idea es obtener los mejores estimadores en la mayor parte de la muestra, pero al mismo tiempo, no sobreajustar los parámetros de las medidas sobre el período completo. El resto de la muestra se utiliza para obtener una combinación lineal de estimadores óptimos en la base 2010 del IPC.

Los parámetros de configuración en este caso son los siguientes:
 1. Período de Evaluación: 
    - Diciembre 2001 - Diciembre 2018, `ff = Date(2018, 12)`
 2. Trayectoria de inflación paramétrica 
    - Con cambios de base cada 5 años, [`InflationTotalRebaseCPI(60)`].
 3.  Método de remuestreo Remuestreo bloques estacionarios, [`ResampleSBB(36)`], con tamaño de bloque esperado igual a 36.
 4. Muestra completa para evaluación [`SimConfig`].

En este caso, una configuración de simulación, para evaluar el Percentil Equiponderado 69, estaría dada por:

```julia
## Definición de parámetros de simulación
inflfn     = InflationPercentileEq(69)
resamplefn = ResampleSBB(36)
trendfn    = TrendRandomWalk()
paramfn    = InflationTotalRebaseCPI(60)
nsim       = 125_000
evaldate   = Date(2018,12)

# Configuración de simulación período Diciembre 2001 - Diciembre 2018
config = SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, evaldate)
```

