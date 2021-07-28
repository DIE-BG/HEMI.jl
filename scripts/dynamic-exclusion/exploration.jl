# # Script de prueba para tipos que especifican variantes de simulación
using DrWatson
using Chain
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

# Funciones de remuestreo y tendencia
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()

## Ejemplos de creacion de diccionarios para Evaluación
# Estos diccionarios contienen n vectores, en donde cada uno contiene una parametrización de simulación, 
# la cual posteriormente es convertida a un objeto AbstractConfig y utilizada para generar una simulación.

# Diccionario de prueba 1: utilizando la función dict_list (DrWatson), 
# crea un vector de tuplas con el producto cartesiano de ...

dict_config_dynEx = Dict(
    :inflfn => InflationDynamicExclusion.(
            @chain range(0, 3, length = 70) ((i, j) for i in _ for j in _) 
       ),
    #:inflfn => InflationDynamicExclusion(2,2),
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 10_000) |> dict_list


## FUNCIONES DE EVALUACIÓN

# run_batch 

# Esta función recibe un CountryStructure, un vector con diccionarios con
# parámetros de evaluación y una ruta para almacenar los resultados.

# Path para almacenamiento de resultados.
savepath = datadir("results", "dynamic-exclusion")

run_batch(gtdata_eval, dict_config_dynEx, savepath)

# Revisión de resultados
# La función collect_results recoje todos los resultados almacenados en savepath
# y los almacena en un DataFrame

df = collect_results(savepath)
df = df[.!isnan.(df.rmse), :]
df = df[df.nsim .== 10_000, :]

df.factor_inf = [df.params[i][1] for i in 1:size(df)[1]]
df.factor_sup = [df.params[i][2] for i in 1:size(df)[1]]

CSV.write(datadir(savepath, "resultados_parse_2021-07-27.csv"), df)
