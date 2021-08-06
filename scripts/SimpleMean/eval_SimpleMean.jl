# # Script de evaluación de metodologías de inflación total y rezagos
using DrWatson
using DataFrames
using Plots
@quickactivate "HEMI"

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI


# CountryStructure con datos hasta diciembre de 2020
gtdata_eval = gtdata[Date(2020, 12)]

# ## Media Simple

# 1. Definir los parámetros de evaluación. 

# Generamos el diccionario con los parámetros de evaluación.
# utilizamos los mismos datos gtdata_eval = gtdata[Date(2020, 12)]
# Funciones de remuestreo y tendencia
resamplefn = ResampleSBB(36)
resamplefn2 = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()
# la función de inflación, la instanciamos dentro del diccionario.

dict_sm = Dict(
    :inflfn => InflationSimpleMean(), 
    :resamplefn => [resamplefn,resamplefn2],
    :trendfn => trendfn,
    :nsim => 125000) |> dict_list


# 2. Definimos las carpetas para almacenar los resultados 
savepath_sm = datadir("SimpleMean")
savepath_plot_sm = plotsdir("InflationSimpleMean","MSE")

# 3. Usamos run_batch, para gnenerar la evluación de los percentiles del 50 al 80
run_batch(gtdata_eval, dict_sm, savepath_sm)

# 4. Revisión de resultados, usando collect_results
df_sm = collect_results(savepath_sm)

# ## Media Ponderada

# 1. Definir los parámetros de evaluación. 

# Generamos el diccionario con los parámetros de evaluación.
# utilizamos los mismos datos gtdata_eval = gtdata[Date(2020, 12)]
# Funciones de remuestreo y tendencia
resamplefn = ResampleSBB(36)
resamplefn2 = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()
# la función de inflación, la instanciamos dentro del diccionario.

dict_wm = Dict(
    :inflfn => InflationWeightedMean(), 
    :resamplefn => [resamplefn, resamplefn2],
    :trendfn => trendfn,
    :nsim => 125000) |> dict_list


# 2. Definimos las carpetas para almacenar los resultados 
savepath_wm = datadir("WeightedMean")
savepath_plot_wm = plotsdir("InflationWeightedMean","MSE")

# 3. Usamos run_batch, para gnenerar la evluación de los percentiles del 50 al 80
run_batch(gtdata_eval, dict_wm, savepath_wm)

# 4. Revisión de resultados, usando collect_results
df_wm = collect_results(savepath_wm)

# ## Medias Móviles

# 1. Definir los parámetros de evaluación. 

# Generamos el diccionario con los parámetros de evaluación.
# utilizamos los mismos datos gtdata_eval = gtdata[Date(2020, 12)]
# Funciones de remuestreo y tendencia
resamplefn = ResampleSBB(36)
resamplefn2 = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()
# la función de inflación, la instanciamos dentro del diccionario.

avrange = 1:1
wmfs = [InflationMovingAverage(InflationTotalCPI(),i) for i in avrange]

dict_ma = Dict(
    :inflfn => wmfs, 
    :resamplefn => [resamplefn,resamplefn2],
    :trendfn => trendfn,
    :nsim => 125000) |> dict_list


# 2. Definimos las carpetas para almacenar los resultados 
savepath_ma = datadir("MovingAverage")
savepath_plot_ma = plotsdir("InflationMovingAverage","MSE")

# 3. Usamos run_batch, para gnenerar la evluación de los percentiles del 50 al 80
run_batch(gtdata_eval, dict_ma, savepath_ma)

# 4. Revisión de resultados, usando collect_results
df_ma = collect_results(savepath_ma)

# Revisamos el elemento del DataFrame con el valor mínimo de mse
min_mse_sm = minimum(df_ma[!,"mse"])

# Podemos ordenar el DataFrame respecto al mse.
sorted_df = sort(df_ma, "mse")


 # revisión gráfica
scatter(2:12, df_ma.mse, 
    ylims = (0, 15),
    label = " MSE Medias Móviles", 
    legend = :topleft, 
    xlabel= "Promedio Móvil", ylabel = "MSE")


##
# ## Ejemplo de evaluación con búsqueda de parámetros 

#config = SimConfig(InflationPercentileEq(69), ResampleSBB(36), TrendRandomWalk(), 10_000)

#results = evalsim(gtdata_eval, config)

## Terminar ejemplo con NLopt u Optim...