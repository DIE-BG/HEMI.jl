# Guía de Evaluación

En esta sección se documentan configuraciones generales para la generación de distintos escenarios de evaluación.

## Escenario 1: Evaluación 2019 variante 1

Este escenario pretende replicar los resultados obtenidos utilizando el lenguaje de programación Matlab, el cual se utilizó en el año 2020 para realizar la evaluación con información hasta diciembre de 2019.

Los parámetros de configuración en este caso son los siguientes:

 1. Período de Evaluación: Diciembre 2000 - Diciembre 2019. `gtdata[Date(2019, 12)]`
 2. Trayectoria de inflación paramétrica con cambio de base sintético, con hasta dos cambios de base [`InflationTotalRebaseCPI(36, 2)`].
 3. Método de remuestreo de extracciones estocásticas independientes [`ResampleScrambleVarMonths()`].
 4. Muestra completa para evaluación [`SimConfig`].

En este caso, una configuración de simulación, para evaluar el Percentil Equiponderado 69, estaría dada por:

```
## Definición de instancias generales

gtdata19   = gtdata[Date(2019, 12)]
inflfn     = InflationPercentileEq(69)
trendfn    = TrendRandomWalk()
resamplefn = ResampleScrambleVarMonths()
paramfn    = InflationTotalRebaseCPI(36, 2)

 # Configuración de simulación
config = SimConfig(inflfn, trendfn, resamplefn, paramfn, 10_000)
```
## Escenario 2: Evaluación 2020 variante 1

Este escenario pretende evaluar las medidas de inflación utilizando la información hasta diciembre de 2020, utilizando los mismos parámetros de configuración que en el escenario 1.

Los parámetros de configuración en este caso son los siguientes:

 1. **Período de Evaluación: Diciembre 2000 - Diciembre 2020. `gtdata[Date(2020, 12)]`**
 2. Trayectoria de inflación paramétrica con cambio de base sintético, con hasta dos cambios de base [`InflationTotalRebaseCPI(36, 2)`].
 3. Método de remuestreo de extracciones estocásticas independientes [`ResampleScrambleVarMonths()`].
 4. Muestra completa para evaluación [`SimConfig`].

En este caso, una configuración de simulación, para evaluar el Percentil Equiponderado 69, estaría dada por:

```
## Definición de instancias generales

gtdata19   = gtdata[Date(2020, 12)]
inflfn     = InflationPercentileEq(69)
trendfn    = TrendRandomWalk()
resamplefn = ResampleScrambleVarMonths()
paramfn    = InflationTotalRebaseCPI(36, 2)

 # Configuración de simulación
config = SimConfig(inflfn, trendfn, resamplefn, paramfn, 10_000)
```

## Escenario 4: Evaluación 2019 con cambio en Inflación Paramétrica

Este escenario pretende evaluar las medidas de inflación utilizando la configuración utilizada para la evaluación 2019 en Matlab, cambiando la trayectoria de inflación paramétrica por una con cambio de base sintético cada cinco años. 

Los parámetros de configuración en este caso son los siguientes:

 1. Período de Evaluación: Diciembre 2000 - Diciembre 2020. `gtdata[Date(2020, 12)]`
 2. Trayectoria de inflación paramétrica con cambio de base sintético, con hasta dos cambios de base [`InflationTotalRebaseCPI(60)`].
 3. Método de remuestreo de extracciones estocásticas independientes [`ResampleScrambleVarMonths()`].
 4. Muestra completa para evaluación [`SimConfig`].

En este caso, una configuración de simulación, para evaluar el Percentil Equiponderado 69, estaría dada por:

```
## Definición de instancias generales

gtdata19   = gtdata[Date(2020, 12)]
inflfn     = InflationPercentileEq(69)
trendfn    = TrendRandomWalk()
resamplefn = ResampleScrambleVarMonths()
paramfn    = InflationTotalRebaseCPI(60)

 # Configuración de simulación
config = SimConfig(inflfn, trendfn, resamplefn, paramfn, 10_000)
```

## Escenario 3: Evaluación 2019 con cambio en Método de remuestreo

Este escenario pretende evaluar las medidas de inflación utilizando la configuración utilizada para la evaluación 2019 en Matlab, cambiando el método de remuestreo por el de extracciones estocásticas por bloques estacionarios

Los parámetros de configuración en este caso son los siguientes:

 1. Período de Evaluación: Diciembre 2000 - Diciembre 2020. `gtdata[Date(2020, 12)]`
 2. Trayectoria de inflación paramétrica con cambio de base sintético, con hasta dos cambios de base [`InflationTotalRebaseCPI(60)`].
 3. **Método de remuestreo de extracciones estocásticas independientes [`ResampleSBB(36)`].**
 4. Muestra completa para evaluación [`SimConfig`].

En este caso, una configuración de simulación, para evaluar el Percentil Equiponderado 69, estaría dada por:

```
## Definición de instancias generales

gtdata19   = gtdata[Date(2020, 12)]
inflfn     = InflationPercentileEq(69)
trendfn    = TrendRandomWalk()
resamplefn = ResampleSBB(36)
paramfn    = InflationTotalRebaseCPI(36, 2)

 # Configuración de simulación
config = SimConfig(inflfn, trendfn, resamplefn, paramfn, 10_000)
```