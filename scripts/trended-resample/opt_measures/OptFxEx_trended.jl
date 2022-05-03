using DrWatson
@quickactivate "HEMI"

# Cargar los paquetes utilizados en todos los procesos
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI

using DataFrames, Chain
using Plots, CSV



## Definición de instancias principales
trendfn    = TrendIdentity()
resamplefn = ResampleScrambleTrended(0.46031723899305166)
paramfn    = InflationTotalRebaseCPI(36, 2)

INFL_FAMILY = InflationFixedExclusionCPI
NSIM = 10_000
ff00 = Date(2010, 12) # Fecha de optimización base 2000
ff10 = Date(2018, 12) # Fecha de optimización base 2010
# Métrica de evaluación
METRIC_B00 = :gt_b00_mse
METRIC_B10 = :mse

# Rutas de guardado
savepath_b00 = datadir("results", "trended-resample", "FxEx", "Base00") 
savepath_b10 = datadir("results", "trended-resample", "FxEx", "Base10")
savepath_final = datadir("results", "trended-resample", "FxEx", "FxOpt")


##  Optimización Base 2000  
###################################
 
# Creación de vector de de gastos básicos ordenados por volatilidad.
estd = std(gt00.v |> capitalize |> varinteran, dims=1)
df = DataFrame(num = collect(1:218), Desv = vec(estd))
sorted_std = sort(df, "Desv", rev=true)
vec_v = sorted_std[!,:num]

# Creación de vectores de exclusión
# Se crean 218 vectores para la exploración inicial y se almacenan en v_exc
v_exc = []
for i in 1:length(vec_v)
   exc = vec_v[1:i]
   append!(v_exc, [exc])
end

# Diccionarios para exploración inicial (primero 100 vectores de exclusión)
FxEx_00 = Dict(
    :inflfn => INFL_FAMILY.(v_exc[1:25]), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => NSIM, 
    :evalperiods => (GT_EVAL_B00,),
    :traindate => ff00) |> dict_list

## Lote de simulación con los primeros 100 vectores de exclusión
run_batch(GTDATA, FxEx_00, savepath_b00)

## Recolección de resultados
df00 = collect_results(savepath_b00)

## Análisis de exploración preliminar
# Obtener longitud del vector de exclusión de cada simulación
# Ordenamiento por cantidad de exclusiones
## Extracción de vector de exclusión y correlación
df00opt = @chain df00 begin
    transform(:params => ByRow(x -> length(x[1])) => :exclusiones)
    sort(:exclusiones)
    sort(METRIC_B00, rev=(METRIC_B00 == :gt_b00_corr))
    first(5)
    select(:params, :exclusiones, METRIC_B00, :gt_b00_me)
end 

exc_opt_00 = df00opt[1, :params][1]
println(exc_opt_00)


##  Optimización Base 2010  
###################################

## Creación de vector de de gastos básicos ordenados por volatilidad, con información a Diciembre de 2018
gtdata_10 = GTDATA[ff10]

est_10 = std(gtdata_10[2].v |> capitalize |> varinteran, dims=1)
df = DataFrame(num = collect(1:279), Desv = vec(est_10))
sorted_std = sort(df, "Desv", rev=true)
vec_v = sorted_std[!,:num]

# Creación de vectores de exclusión
# Se crearán 100 vectores para la exploración inicial
v_exc = []
tot = []
total = []
for i in 1:length(vec_v)
   exc = vec_v[1:i]
   v_exc =  append!(v_exc, [exc])
   tot = (exc_opt_00, v_exc[i])
   total = append!(total, [tot])
end
total

# Diccionarios para exploración inicial (primero 100 vectores de exclusión)
FxEx_10 = Dict(
    :inflfn => INFL_FAMILY.(total[1:25]), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => NSIM,
    :traindate => ff10, 
    :evalperiods => (GT_EVAL_B00, GT_EVAL_B10, CompletePeriod())) |> dict_list

## Lote de simulación con los primeros 100 vectores de exclusión
run_batch(GTDATA, FxEx_10, savepath_b10)

## Recolección de resultados
df10 = collect_results(savepath_b10)

## Análisis de exploración preliminar

## Extracción de vector de exclusión y correlación
df10opt = @chain df10 begin
    transform(:params => ByRow(x -> length(x[2])) => :exclusiones)
    sort(:exclusiones)
    sort(METRIC_B10, rev=(METRIC_B10 == :corr))
    first(5)
    transform(:params => ByRow(x -> x[2]) => :exclusiones_b10)
    select(:exclusiones_b10, :exclusiones, METRIC_B10, :gt_b10_me)
end 

exc_opt_10 = df10opt[1, :exclusiones_b10]
println(exc_opt_10)
FGT10.names[exc_opt_10]

## Observar la trayectoria observada 

# Resultados con 100 simulaciones: 
# ([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], 
# [29, 116, 31, 46, 39, 40, 186, 30, 35, 185])

# Resultados con 10_000 simulaciones: 
# ([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], 
# [29, 116, 31, 46, 39, 40, 186, 30, 35, 185])

# ResampleScrambleTrended(0.46031723899305166), 10k simulaciones
# ([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], 
# [29, 116, 31, 46, 39, 40, 186, 30, 35, 185, 197, 34, 48, 184])

inflfn = INFL_FAMILY(exc_opt_00, exc_opt_10)
inflfn(GTDATA)

plot(InflationTotalCPI(), GTDATA)
plot!(inflfn, GTDATA)


## Resultados de evaluación a dic-20
# Evaluación y resultados con datos hasta dic-20

config_fxopt = Dict(
    :inflfn => inflfn, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn,
    :nsim => 125_000,
    :traindate => Date(2020, 12)) |> dict_list

run_batch(GTDATA, config_fxopt, savepath_final)

final_metrics = collect_results(savepath_final)

main_results = @chain final_metrics begin 
    select(:measure, :mse, :mse_std_error)
end

# Descomposición aditiva del MSE 
mse_decomp = @chain final_metrics begin 
    select(:measure, :mse, :mse_bias, :mse_var, :mse_cov)
end

# Otras métricas de evaluación 
sens_metrics = @chain final_metrics begin 
    select(:measure, :rmse, :me, :mae, :huber, :corr)
end 