# Guía de Evaluación

En esta sección se documentan configuraciones generales para la generación de distintos escenarios de evaluación.

## Escenario 1: Replicar el trabajo efectuado en 2020 (criterios básicos a dic-19)

### **Nombre para carpeta: "data\results\nombre-medida\Esc-1\"**
Este escenario pretende replicar los resultados obtenidos utilizando el lenguaje de programación Matlab, el cual se utilizó en el año 2020 para realizar la evaluación con información hasta diciembre de 2019.

Los parámetros de configuración en este caso son los siguientes:

 1. Período de Evaluación: Diciembre 2000 - Diciembre 2019, `ff = Date(2019, 12)`.
 2. Trayectoria de inflación paramétrica con cambio de base sintético: 2 cambios de base cada 3 años,  [`InflationTotalRebaseCPI(36, 2)`].
 3. Método de remuestreo de extracciones estocásticas independientes (Remuestreo por meses de ocurrencia), [`ResampleScrambleVarMonths()`].
 4. Muestra completa para evaluación, [`SimConfig`].

En este escenario no es necesario llevar a cabo el proceso de optimización. 

En este caso, una configuración de simulación, para evaluar el Percentil Equiponderado 69, estaría dada por:

``` julia
# Instacias para Escenario 1

inflfn     = InflationPercentileEq(69)
resamplefn = ResampleScrambleVarMonths()
trendfn    = TrendRandomWalk()
paramfn    = InflationTotalRebaseCPI(36, 2)
nsim       = 10_000
ff         = Date(2019, 12)

 # Configuración de simulación
config = SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, ff)
```
```julia-repl
julia> config = SimConfig(InflationPercentileEq(69), ResampleScrambleVarMonths(), TrendRandomWalk(), InflationTotalRebaseCPI(36, 2), 10_000, Date(2019, 12))      
SimConfig{InflationPercentileEq, ResampleScrambleVarMonths, TrendRandomWalk{Float32}}
|─> Función de inflación            : Percentil equiponderado 69.0
|─> Función de remuestreo           : Bootstrap IID por meses de ocurrencia
|─> Función de tendencia            : Tendencia de caminata aleatoria
|─> Método de inflación paramétrica : Variación interanual IPC con cambios de base sintéticos (36, 2)
|─> Número de simulaciones          : 10000
|─> Fin set de entrenamiento        : 2019-12-01
```

## Escenario 2 -> Explicar diferencias *****

## Escenario 3: Extender el trabajo efectuado en 2020 (criterios básicos a dic-20)

### **Nombre para carpeta: "data\results\nombre-medida\Esc-3\"**
Este escenario pretende evaluar las medidas de inflación utilizando la información hasta diciembre de 2020, utilizando los mismos parámetros de configuración que en el escenario 1.

Los parámetros de configuración en este caso son los siguientes:

1. Período de Evaluación: Diciembre 2000 - Diciembre 2020, `ff = Date(2020, 12)`.
 2. Trayectoria de inflación paramétrica con cambio de base sintético: 2 cambios de base cada 3 años,  [`InflationTotalRebaseCPI(36, 2)`].
 3. Método de remuestreo de extracciones estocásticas independientes (Remuestreo por meses de ocurrencia), [`ResampleScrambleVarMonths()`].
 4. Muestra completa para evaluación, [`SimConfig`].

A diferencia del Escenario 1, en este escenario si se debe llevar a cabo la optimización de la medida.

En este caso, una configuración de simulación, para evaluar el Percentil Equiponderado 69, estaría dada por:

``` julia
# Instacias para Escenario 3

inflfn     = InflationPercentileEq(69)
resamplefn = ResampleScrambleVarMonths()
trendfn    = TrendRandomWalk()
paramfn    = InflationTotalRebaseCPI(36, 2)
nsim       = 10_000
ff         = Date(2020, 12)

 # Configuración de simulación
config = SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, ff)
```
```julia-repl
julia> config = SimConfig(InflationPercentileEq(69), ResampleScrambleVarMonths(), TrendRandomWalk(), InflationTotalRebaseCPI(36, 2), 10_000, Date(2020,12))       
SimConfig{InflationPercentileEq, ResampleScrambleVarMonths, TrendRandomWalk{Float32}}
|─> Función de inflación            : Percentil equiponderado 69.0
|─> Función de remuestreo           : Bootstrap IID por meses de ocurrencia
|─> Función de tendencia            : Tendencia de caminata aleatoria
|─> Método de inflación paramétrica : Variación interanual IPC con cambios de base sintéticos (36, 2)
|─> Número de simulaciones          : 10000
|─> Fin set de entrenamiento        : 2020-12-01
```

## Escenario 4: Evaluación de criterios básicos con cambio de parámetro de evaluación

### **Nombre para carpeta: "data\results\nombre-medida\Esc-4\"**

Este escenario pretende evaluar las medidas de inflación utilizando la configuración utilizada para la evaluación 2019 en Matlab, cambiando la trayectoria de inflación paramétrica por una con cambio de base sintético cada cinco años. 

Los parámetros de configuración en este caso son los siguientes:

 1. Período de Evaluación: 
    1.   Diciembre 2000 - Diciembre 2019, `ff = Date(2019, 12)`
    2.   Diciembre 2000 - Diciembre 2020, `ff = Date(2020, 12)`
 2. Trayectoria de inflación paramétrica con cambios de base cada 5 años, [`InflationTotalRebaseCPI(60)`].
 3.  Método de remuestreo de extracciones estocásticas independientes (Remuestreo por meses de ocurrencia), [`ResampleScrambleVarMonths()`].
 4. Muestra completa para evaluación [`SimConfig`].

Es requerido llevar a cabo la optimización de la medida, para ambos períodos de evaluación.

En este caso, una configuración de simulación, para evaluar el Percentil Equiponderado 69, estaría dada por:

``` julia
## Definición de instancias generales


inflfn     = InflationPercentileEq(69)
resamplefn = ResampleScrambleVarMonths()
trendfn    = TrendRandomWalk()
paramfn    = InflationTotalRebaseCPI(60)
nsim       = 10_000
ff19       = Date(2019, 12)
ff20       = Date(2020, 12)

 # Configuración de simulación*
 
config19 = SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, ff19)
config20 = SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, ff20)
```

``` julia-repl
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
## Escenario 5: Evaluación de criterios básicos con cambio en Método de remuestreo

### **Nombre para carpeta: "data\results\nombre-medida\Esc-5\"**

Este escenario pretende evaluar las medidas de inflación utilizando la configuración utilizada para la evaluación 2019 en Matlab, cambiando el método de remuestreo por el de extracciones estocásticas por bloques estacionarios

Los parámetros de configuración en este caso son los siguientes:
 1. Período de Evaluación: 
    1.   Diciembre 2000 - Diciembre 2019, `ff = Date(2019, 12)`
    2.   Diciembre 2000 - Diciembre 2020, `ff = Date(2020, 12)`
 2. Trayectoria de inflación paramétrica 
    1. Con cambios de base cada 3 años, [`InflationTotalRebaseCPI(36, 2)`].
    2. Con cambios de base cada 5 años, [`InflationTotalRebaseCPI(60)`].
 3.  Método de remuestreo Remuestreo bloques estacionarios, [`ResampleSBB(36)`].
 4. Muestra completa para evaluación [`SimConfig`].

En este caso, una configuración de simulación, para evaluar el Percentil Equiponderado 69, estaría dada por:

``` julia
## Definición de instancias generales


inflfn     = InflationPercentileEq(69)
resamplefn = ResampleSBB(36)
trendfn    = TrendRandomWalk()
paramfn1    = InflationTotalRebaseCPI(36, 2)
paramfn2    = InflationTotalRebaseCPI(60)
nsim       = 10_000
ff19       = Date(2019,12)
ff20       = Date(2020, 12)

 # Configuración de simulación*

# Para período Diciembre 2000 - Diciembre 2019
config19_1 = SimConfig(inflfn, resamplefn, trendfn, paramfn1, nsim, ff19)
config19_2 = SimConfig(inflfn, resamplefn, trendfn, paramfn2, nsim, ff19)
# Para período Diciembre 2000 - Diciembre 2020
config20_1 = SimConfig(inflfn, resamplefn, trendfn, paramfn1, nsim, ff20)
config20_2 = SimConfig(inflfn, resamplefn, trendfn, paramfn2, nsim, ff20)
```

**NOTA:** Las configuraciones se muestran individuales y como ejemplo. Puede también utilizarse `dict_list` para crear diccionarios de simulación con las distintas variantes de funciones o fechas finales.

``` julia
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
    :nsim => 10_000,
    :traindate => [Date(2019, 12), Date(2020, 12)]) |> dict_list
```