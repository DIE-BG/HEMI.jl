# # Script de Evaluación de inflación basada en percentiles (Equiponderados y ponderados)

# Escenario C: Evaluación de criterios básicos con cambio de parámetro de evaluación
# -  Período de Evaluación:
#      a. Diciembre 2001 - Diciembre 2019, ff19 = Date(2019, 12)
#      b. Diciembre 2001 - Diciembre 2020, ff20 = Date(2020, 12)
# -  Trayectoria de inflación paramétrica con cambios de base cada 5 años, [InflationTotalRebaseCPI(60)].
# -  Método de remuestreo de extracciones estocásticas independientes (Remuestreo por meses de ocurrencia), [ResampleScrambleVarMonths()].
# -  Muestra completa para evaluación [SimConfig].

Esc = "EscC19"
using DrWatson
@quickactivate "HEMI"
using DataFrames
using Plots, CSV

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

# CountryStructure con datos hasta diciembre de 2020
gtdata_eval = gtdata[Date(2019, 12)]
ff = Date(2019, 12)

##
# Percentiles ponderados

medida = "InflPercentileWeighted"

# 1. Definir los parámetros de evaluación. 

# Se evalúan los percentiles ponderados del 50 al 80. 
# Generamos el diccionario con los parámetros de evaluación.
# utilizamos los mismos datos gtdata_eval = gtdata[Date(2019, 12)]

# Funciones de remuestreo y tendencia
#resamplefn = ResampleSBB(36)
resamplefn = ResampleScrambleVarMonths() 
trendfn = TrendRandomWalk()
paramfn = InflationTotalRebaseCPI(60)

# la función de inflación, la instanciamos dentro del diccionario.
dict_percW = Dict(
    :inflfn => InflationPercentileWeighted.(50:80), 
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 125_000,
    :traindate => ff) |> dict_list 

# 2. Definimos las carpetas para almacenar los resultados 
savepath_pw = datadir("results",medida,"EscC",Esc)
savepath_plot_pw = joinpath("docs", "src", "eval", "EscC", "images", medida)

# 3. Usamos run_batch, para gnenerar la evaluación de los percentiles del 50 al 80
run_batch(gtdata_eval, dict_percW, savepath_pw)

# 4. Revisión de resultados, usando collect_results
df_pw = collect_results(savepath_pw)

# Revisamos el elemento del DataFrame con el valor mínimo de mse
min_mse_pw= minimum(df_pw[!,"mse"])

# Podemos ordenar el DataFrame respecto al mse.
sorted_df_pw = sort(df_pw, "mse")
min_pw= first(sorted_df_pw[!,"measure"])
num_min_pw = sorted_df_pw.params[1]
num_min_pw = num_min_pw[1]

# Guardar como CSV el DataFrame en la ruta especifiada
CSV.write(joinpath(savepath_pw,"InflationPercentileWeighted.csv"),sorted_df_pw)

# revisión gráfica

# a. Gráfica percentiles
scatter(50:80, df_pw.mse, 
    ylims = (0, 20),
    label = " MSE Percentiles Ponderados", 
    legend = :topright, # :topleft, 
    xlabel= "Percentil ponderado", ylabel = "MSE")
    annotate!(70, 14, string("min MSE = ",min_mse_pw,"  ",min_pw),7)
    png(joinpath(savepath_plot_pw, "MSE_c19"))

# b. Gráfica trayectorias
p = plot(InflationTotalCPI(), gtdata, fmt = :svg)
plot!(InflationPercentileWeighted(num_min_pw), gtdata, fmt = :svg)

Plots.svg(p, joinpath(savepath_plot_pw, "obs_trajectory_c19"))
    
##
# Percentiles Equiponderados
medida = "InflPercentileEq"

# 1. Definir los parámetros de evaluación. 

# Asumimos que queremos evaluar los percentiles ponderados del 50 al 80. 
# Generamos el diccionario con los parámetros de evaluación.
# utilizamos los mismos datos gtdata_eval = gtdata[Date(2019, 12)]

# Funciones de remuestreo y tendencia
#resamplefn = ResampleSBB(36)
resamplefn = ResampleScrambleVarMonths() 
trendfn = TrendRandomWalk()
paramfn = InflationTotalRebaseCPI(60)

# la función de inflación, la instanciamos dentro del diccionario.
dict_perc = Dict(
    :inflfn => InflationPercentileEq.(50:80), 
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 125_000,
    :traindate => ff) |> dict_list 

# 2. Definimos las carpetas para almacenar los resultados 

savepath_p = datadir("results",medida,"EscC",Esc)
savepath_plot_p = joinpath("docs", "src", "eval", "EscC", "images", medida)

# 3. Usamos run_batch, para gnenerar la evaluación de los percentiles del 50 al 80
run_batch(gtdata_eval, dict_perc, savepath_p)

# 4. Revisión de resultados, usando collect_results
df_p = collect_results(savepath_p)

# Revisamos el elemento del DataFrame con el valor mínimo de mse
min_mse_p= minimum(df_p[!,"mse"])

# Podemos ordenar el DataFrame respecto al mse.
sorted_df_p = sort(df_p, "mse")
min_p= first(sorted_df_p[!,"measure"])
num_min_p = sorted_df_p.params[1]
num_min_p = num_min_p[1]

# Guardar el DataFrame en la ruta especifiada
CSV.write(joinpath(savepath_p,"InflationPercentileEq.csv"),sorted_df_p)

# revisión gráfica

# a. Gráfica percentiles
scatter(50:80, df_p.mse, 
    ylims = (0, 20),
    label = " MSE Percentiles Equiponderados", 
    legend = :topright, # :topleft, 
    xlabel= "Percentil Equiponderado", ylabel = "MSE")
    annotate!(70, 16, string("min MSE = ",min_mse_p,"  ",min_p),7)
    png(joinpath(savepath_plot_p, "MSE_c19"))

# b. Gráfica trayectorias
p = plot(InflationTotalCPI(), gtdata, fmt = :svg)
plot!(InflationPercentileEq(num_min_p), gtdata, fmt = :svg)

Plots.svg(p, joinpath(savepath_plot_p, "obs_trajectory_c19"))