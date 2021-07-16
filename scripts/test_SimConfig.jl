# # Script de prueba para tipos que especifican variantes de simulación
using DrWatson
@quickactivate "HEMI"

# ## Cargamos paquete de evaluación
using HEMI


## Obtener un ejemplo 

# Datos hasta diciembre 2020
gtdata_eval = gtdata[Date(2020, 12)]

## Parámetros de simulación

# Funciones de inflación
# Inflación Total
totalfn = InflationTotalCPI()
# Percentil Equiponderado
percEq = InflationPercentileEq(80)
# Exclusión Fija 
excOpt00 = [35,30,190,36,37,40,31,104,162,32,33,159,193,161]
excOpt10 = [29,31,116,39,46,40,30,35,186,47,197,41,22,48,185,34,184]
fxEx = InflationFixedExclusionCPI(excOpt00, excOpt10)

# Funciones de remuestreo y tendencia
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()

# Otros parametros (para CrossEvalConfig)
# ff = Date(2020, 12)
# sz = 24


## Crear una configuraciones de pruebaa 
configA = SimConfig(totalfn, resamplefn, trendfn, 1000)
configB = SimConfig(fxEx, resamplefn, trendfn, 1000)
configC = SimConfig(percEq, resamplefn, trendfn, 1000)

## Función savename (DrWatson), para mnombres de archivos de resultados 
savename(configA, connector=" | ", equals=" = ")
savename(configB, connector=" | ", equals=" = ")
savename(configC, connector=" | ", equals=" = ")

## Conversión de AbstractConfig a Diccionario (función de DrWatson)

dic_a = struct2dict(configA)
dic_b = struct2dict(configB)
dic_c = struct2dict(configC)

## Ejemplos de creacion de diccionarios para Evaluación

# Diccionario de prueba 1: utilizando la función dict_list (DrWatson), 
# crea un vector con 21 diccionarios con todas las opciones de percentiles desde el 60 hasta el 80
dict_prueba = Dict(
    :inflfn => InflationPercentileEq.(60:80), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 1000) |> dict_list

# Diccionario de prueba 2: utilizando dict_list (DrWatson), 
# Este ejemplo crea un vector con un único diccionario con la función de inflación total instanciada al inicio de este script
dict_pruebaB = Dict(
    :inflfn => totalfn, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 10_000) |> dict_list

# Diccionario de prueba 3: utilizando dict_list (DrWatson), 
# Este ejemplo crea un vector con un único diccionario con la función Exclusión Fija instanciada al inicio de este script. 
# En este caso se puede instanciar dentro del diccionario como se hizo con los percentiles.     
dict_pruebaC = Dict(
        :inflfn => fxEx, 
        :resamplefn => resamplefn, 
        :trendfn => trendfn,
        :nsim => 1000) |> dict_list

# Función dict_config para pasar de Diccionario a AbstractConfig, se utilizará dentro de la función run_batch, 
# previo a darle la información a la información a la función makesim.

    configD_a = dict_config(dict_prueba)
    configC_a = dict_config(dict_pruebaC)
    configE = dict_config(dict_pruebaB)


## FUNCIONES 

# 1. Prueba de función evalsim (). 
# Esta función recibe un CountryStructure y un AbstractConfig.
# Esta función realiza todos los cálculos asociados a la evaluación.

    evalsim(gtdata_eval, configA)

# 2. Prueba de Función MakeSim 
# Esta función recibe un CountryStructure y un AbstractConfig
# Realiza los cálculos por medio de la función evalsim y devuelve un diccionario con las métricas de evaluación y un "cubo" con las trayectorias de inflación.
    dict_out, tray_inflacion = makesim(gtdata_eval, configA)
    dict_out


# 3. Función run_batch
## Esta función recibe un CountryStructure y un vector con diccionarios con parámetros de evaluación 

# Por ejemplo, podemos concatenar dict_prueba (percentiles) y dict_pruebaC (Exclusión Fija)
sims = vcat(dict_prueba, dict_pruebaC)

# Paths de prueba
savepath = "C:\\Users\\MJGM\\Desktop\\prueba"
savepath2 = "C:\\Users\\MJGM\\Desktop\\prueba2"


run_batch(gtdata_eval, dict_prueba, savepath)


df = collect_results(savepath)

sort!(df, "mse")
