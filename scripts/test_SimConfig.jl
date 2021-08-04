# # Script de prueba para tipos que especifican variantes de simulación
using DrWatson
@quickactivate "HEMI"

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI


# CountryStructure con datos hasta diciembre de 2020
gtdata_eval = gtdata[Date(2020, 12)]

## Definición de Parámetros de simulación

# Funciones de inflación
# Inflación Total
totalfn = InflationTotalCPI()
# Percentiles
percEq = InflationPercentileEq(80)
percPond = InflationPercentileWeighted(20)
# Exclusión Fija 
excOpt00 = [35,30,190,36,37,40,31,104,162,32,33,159,193,161]
excOpt10 = [29,31,116,39,46,40,30,35,186,47,197,41,22,48,185,34,184]
fxEx = InflationFixedExclusionCPI(excOpt00, excOpt10)

# Funciones de remuestreo y tendencia
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()
paramfn = InflationTotalRebaseCPI(60)

# Otros parametros (para CrossEvalConfig)
ff = Date(2020, 12)
sz = 24


## Creación de configuraciones de prueba usando objetos AbstractConfig.

configA = SimConfig(totalfn, resamplefn, trendfn, paramfn, 1000, ff)
configB = SimConfig(fxEx, resamplefn, trendfn, paramfn, 1000, ff)
configC = SimConfig(percEq, resamplefn, trendfn, paramfn, 1000, ff)
configC = CrossEvalConfig(percEq, resamplefn, trendfn, paramfn, 1000, ff, sz)


# Algunas utilidades relacionadas con los objetos AbstractConfig
# Creación de nombres para almacenar archivos (función savename de DrWatson)
savename(configA)
savename(configB)
savename(configC)

# Conversión de AbstractConfig a Diccionario (función de DrWatson)
dic_a = struct2dict(configA)
dic_b = struct2dict(configB)
dic_c = struct2dict(configC)

## Ejemplos de creacion de diccionarios para Evaluación
# Estos diccionarios contienen n vectores, en donde cada uno contiene una parametrización de simulación, 
# la cual posteriormente es convertida a un objeto AbstractConfig y utilizada para generar una simulación.

# Diccionario de prueba 1: utilizando la función dict_list (DrWatson), 
# crea un vector con 21 diccionarios con todas las opciones de percentiles desde el 60 hasta el 80
dict_prueba = Dict(
    :inflfn => InflationPercentileEq.(60:80), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 100, 
    :traindate => ff) |> dict_list

# Diccionario de prueba 2: utilizando dict_list (DrWatson), 
# Este ejemplo crea un vector con un único diccionario con la función de inflación total instanciada al inicio de este script
dict_pruebaB = Dict(
    :inflfn => totalfn, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 10_000,
    :traindate => ff) |> dict_list

# Diccionario de prueba 3: utilizando dict_list (DrWatson), 
# Este ejemplo crea un vector con un único diccionario con la función Exclusión Fija instanciada al inicio de este script. 
# En este caso se puede instanciar dentro del diccionario como se hizo con los percentiles.     
dict_pruebaC = Dict(
        :inflfn => fxEx, 
        :resamplefn => resamplefn, 
        :trendfn => trendfn,
        :paramfn => paramfn,
        :nsim => 1000, 
        :traindate => ff) |> dict_list


# la función dict_config nos permite convertir un Diccionario a un objeto AbstractConfig, 
# se utiliza dentro de la función run_batch, previo a darle la información a la información
# a la función makesim.

configD_a = dict_config(dict_prueba)
configC_a = dict_config(dict_pruebaC)
configE = dict_config(dict_pruebaB)


## FUNCIONES DE EVALUACI��N

# 1. Función evalsim(). 
# Esta función recibe un CountryStructure y un AbstractConfig.
# Esta función realiza todos los cálculos asociados a la evaluación y devuelve las métricas de 
# evaulación y las trayectorias simuladas.

evalsim(gtdata, configA)

# 2. Función MakeSim 
# Esta función recibe un CountryStructure y un AbstractConfig. 
# Realiza los cálculos de evaluación por medio de la función evalsim y devuelve un diccionario con 
# las métricas de evaluación y un "cubo" con las trayectorias de inflación.

results, tray_infl = makesim(gtdata, configB)
results

# 3. Función run_batch 

# Esta función recibe un CountryStructure, un vector con diccionarios con
# parámetros de evaluación y una ruta para almacenar los resultados.

# Por ejemplo, podemos concatenar dict_prueba (percentiles), dict_pruebaB
# (Inflación Total) y dict_pruebaC (Exclusión Fija)

sims = vcat(dict_prueba, dict_pruebaB, dict_pruebaC)

# Path para almacenamiento de resultados.
savepath = datadir("results", "testSimConfig")

# Prueba de run_batch unicamente con el vector de configuraciones para los
# percentiles del 60 al 80
run_batch(gtdata_eval, dict_prueba, savepath)


# Revisión de resultados
# La función collect_results recoje todos los resultados almacenados en savepath
# y los almacena en un DataFrame

df = collect_results(savepath)

# Revisamos el elemento del DataFrame con el valor mínimo de mse
minimum(df[!,"mse"])

# Podemos ordenar el DataFrame respecto al mse.
sorted_df = sort(df, "mse")

# Revisión gráfica: ScaterPlot con valores de mse 
using Plots

scatter(60:80, df.mse, 
    label = " MSE Percentiles equiponderados", 
    legend = :topleft, 
    xlabel= "Percentil equiponderado", ylabel = "MSE")

##
# ## Ejemplo del flujo de trabajo para generar una evaluación

# 1. Definir los parámetros de evaluación. 

# Asumimos que queremos evaluar los percentiles ponderados del 50 al 80. 
# Generamos el diccionario con los parámetros de evaluación.
# utilizamos los mismos datos gtdata_eval = gtdata[Date(2020, 12)]
# Funciones de remuestreo y tendencia
resamplefn = ResampleSBB(36)
resamplefn2 = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()
paramfn = InflationTotalRebaseCPI(36, 2)
# la función de inflación, la instanciamos dentro del diccionario.

dict_percW = Dict(
    :inflfn => InflationPercentileWeighted.(50:80), 
    :resamplefn => [resamplefn2],
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 100, 
    :traindate => ff) |> dict_list


# 2. Definimos el folder para almacenar los resultados 
savepath_pw = datadir("results", "PercWeigthed-scramble")

# 3. Usamos run_batch, para gnenerar la evluación de los percentiles del 50 al 80
run_batch(gtdata_eval, dict_percW, savepath_pw)

# 4. Revisión de resultados, usando collect_results
df_pw = collect_results(savepath_pw);

using DataFrames
select(df_pw, :measure, :mse)
# revisión gráfica
scatter(60:80, df_pw.mse, 
    ylims = (0, 15),
    label = " MSE Percentiles Ponderados", 
    legend = :topleft, 
    xlabel= "Percentil equiponderado", ylabel = "MSE")


##
# ## Ejemplo de evaluación con parámetros de evaluación 2019 
# Datos a diciembre 2019
gtdata_eval19 = gtdata[Date(2019, 12)]

# Configuración para percentil equiponderado 69, Metodo de selección por meses, Caminata aleatoria e Inflación de evaluación con hasta 2 cambios de base.
config = SimConfig(InflationPercentileEq(69), ResampleScrambleVarMonths(), TrendRandomWalk(), InflationTotalRebaseCPI(36, 2), 10_000, Date(2019, 12))

results, tray_infl = evalsim(gtdata_eval19, config)
results
