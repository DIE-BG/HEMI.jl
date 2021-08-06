# # Exploración de variantes para medida de exclusión dinámica
using DrWatson
using Chain
@quickactivate "HEMI"

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

# ## Definición de parámetros y variantes de simulación

# CountryStructure con datos hasta diciembre de 2020
gtdata_eval = [gtdata[Date(2020, 12)], gtdata[Date(2019, 12)]]

# Funciones de remuestreo
resamplefn = [ResampleSBB(36), ResampleScrambleVarMonths()]

# Funciones de tendencia
trendfn = TrendRandomWalk()

# Funciones de parámetros
paramfn = [ParamTotalCPIRebase, ParamTotalCPILegacyRebase]

# ## Parametrización de la evaluación
# Estos diccionarios contienen n vectores, en donde cada uno contiene una parametrización de simulación, 
# la cual posteriormente es convertida a un objeto AbstractConfig y utilizada para generar una simulación.
dict_config_dynEx = Dict(
    :inflfn => InflationDynamicExclusion.(
            @chain range(0, 3, length = 70) ((i, j) for i in _ for j in _) 
       ),
    #:dataeval => gtdata_eval,
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    #:paramfn => paramfn,
    :nsim => 100) |> dict_list


# ## Ejecución de evaluación

# Esta función recibe un CountryStructure, un vector con diccionarios con
# parámetros de evaluación y una ruta para almacenar los resultados.

# Path para almacenamiento de resultados.
savepath = datadir("results", "dynamic-exclusion")

#
run_batch(gtdata_eval, dict_config_dynEx, savepath, rndseed = 314159)

# Revisión de resultados
# La función collect_results recoje todos los resultados almacenados en savepath
# y los almacena en un DataFrame

df = collect_results(savepath)
df = df[.!isnan.(df.rmse), :]
df = df[df.nsim .== 10_000, :]

df.factor_inf = [df.params[i][1] for i in 1:size(df)[1]]
df.factor_sup = [df.params[i][2] for i in 1:size(df)[1]]

CSV.write(datadir(savepath, "resultados_parse_2021-07-27.csv"), df)