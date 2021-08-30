using DrWatson
@quickactivate "HEMI"

using DataFrames, Chain
using HEMI 

# NOTA: este script asume que ya se cuenta con los resultados y trayectorias de cada
#       medida de forma individual. Para generar estas trayectorias (excepto las de la
#       MAI), correr el script llamado comb_lineal_2019a.jl

# Definimos fecha de evaluación
gtdata_eval = gtdata[Date(2019, 12)]

# Definimos el parámetro
legacy_param = InflationParameter(
    InflationTotalRebaseCPI(36, 2), # Cada 36 meses y hasta 2 cambios de base 
    ResampleScrambleVarMonths(), 
    TrendRandomWalk()
)

tray_infl_param = legacy_param(gtdata_eval)

## MAI ---------------------------------------------------------------------------------


# cargamos los resultados y definimos directorio de trayectorias
df_mai = collect_results(datadir("tray2019","MAI"))
tray_dir_mai = datadir("tray2019", "MAI", "tray_infl")

# agregamos una columna con las trayectorias
df_mai[!,:tray] = @chain df_mai.path begin
    basename.(_)
    joinpath.(tray_dir_mai,_)
    load.(_)
    [x["tray_infl"] for x in _]
end

# creamos array con trayectorias y obtenemos ponderadores
tray_infl_mai = reduce(hcat, df_mai.tray)
a_mai = combination_weights(tray_infl_mai, tray_infl_param)

# creamos nueva columna con los ponderadores
df_mai[!, :a_mai] = a_mai

# creamos tabla de resultados para la MAI
RESULTS_MAI = select(df_mai, :measure, :a_mai, :mse)

# Combinación de simulaciones 
tray_infl_maiopt = sum(tray_infl_mai .* a_mai', dims=2)
metrics_mai = eval_metrics(tray_infl_maiopt, tray_infl_param)

# Funcion de inflación combinada 
inflfn_mai = CombinationFunction(df_mai.inflfn..., df_mai.a_mai) 

## OTRAS MEDIDAS --------------------------------------------------------------------------------------------------------------------------

# cargamos los resultados y definimos directorio de trayectorias
df = collect_results(datadir("tray2019"))
tray_dir = datadir("tray2019", "tray_infl")

# agregamos una columna con las trayectorias
df[!,:tray] = @chain df.path begin
    basename.(_)
    joinpath.(tray_dir,_)
    load.(_)
    [x["tray_infl"] for x in _]
end

# Creamos un DataFrame con los resultados de la MAI para agregar a las demás medidas
mai_DF = DataFrame(inflfn = inflfn_mai, measure = "Subyacente MAI óptima MSE", tray = [tray_infl_maiopt], mse = [metrics_mai[:mse]])

# Se combina con las otras medidas para determinar ponderadores
df = vcat(df,mai_DF, cols=:union)

# Se crea el array y se obtienen los ponderadores
tray_infl = reduce(hcat, df.tray)
a = combination_weights(tray_infl, tray_infl_param)

# creamos nueva columna con los ponderadores
df[!, :a] = a

# Creamos una tabla de resultados final
RESULTS = select(df, :measure, :a, :mse)

# Combinación de simulaciones 
tray_infl_opt = sum(tray_infl .* a', dims=2)
metrics = eval_metrics(tray_infl_opt, tray_infl_param)

# Creamos una funcion de inflación combinada final
inflfn = CombinationFunction(df.inflfn..., df.a) 

## RESULTADOS FINALES -----------------------------------------------------------------------

# se muestran los resultados finales de la optimización
println(RESULTS_MAI)
println(RESULTS)
println("MSE = ", metrics[:mse])

# resultados

# Row  │ measure     a_mai       mse      
#      │ String?     Float32     Float32? 
# ─────┼──────────────────────────────────
# 1    │ MAI (F,10)   0.246467   0.381114
# 2    │ MAI (F,20)  -0.0948016  0.821786
# 3    │ MAI (F,4)    0.788371   0.372025
# 4    │ MAI (F,40)   0.160992   1.16912
# 5    │ MAI (F,5)   -0.282135   0.308402
# 6    │ MAI (G,10)  -0.0293709  0.709831
# 7    │ MAI (G,20)   0.0513666  0.683976
# 8    │ MAI (G,4)    0.117855   0.884099
# 9    │ MAI (G,40)   0.054515   0.786082
# 10   │ MAI (G,5)   -0.0400753  0.896793

# Row  │ measure                            a           mse      
#      │ String?                            Float32     Float32? 
# ─────┼─────────────────────────────────────────────────────────
# 1    │ Inflación de exclusión dinámica …  -0.0895958  0.290958
# 2    │ Exclusión fija de gastos básicos…   0.287025   0.642199
# 3    │ Media Truncada Equiponderada (57…   1.1065     0.217257
# 4    │ Media Truncada Ponderada (15.0, …  -0.134828   0.294983
# 5    │ Percentil equiponderado 72.0       -0.36216    0.24138
# 6    │ Percentil ponderado 70.0            0.0141849  0.406735
# 7    │ Subyacente MAI óptima MSE           0.177114   0.217247

# MSE = 0.15239142