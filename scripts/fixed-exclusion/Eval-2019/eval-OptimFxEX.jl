## carga de paquetes
using DrWatson
@quickactivate "HEMI"

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI
using DataFrames
using Plots, CSV

## #################### Instancias generales #############################

trendfn = TrendRandomWalk()
# legacy_param = ParamTotalCPILegacyRebase()
resamplefn = ResampleScrambleVarMonths() 


## ########################### Optimización Base 2000 ########################
# Datos 
gtdata_00 = gtdata[Date(2010, 12)]

## Creación de vector de de gastos básicos ordenados por volatilidad.
estd = std(varinteran(capitalize(gt00.v)), dims=1)

df = DataFrame(num = collect(1:218), Desv = vec(estd))

sorted_std = sort(df, "Desv", rev=true)

vec_v = sorted_std[!,:num]

# Creación de vectores de exclusión
# Se crearán 100 vectores para la exploración inicial
v_exc = []
for i in 10:20#length(vec_v)-118
   exc = vec_v[1:i]
   append!(v_exc, [exc])
end

v_exc

## creación de diccionarios y ruta para lote de simulación

FxEx_00 = Dict(
    :inflfn => InflationFixedExclusionCPI.(v_exc), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 125_000) |> dict_list

savepath = datadir("results","fixed-exclusion","Eval-19","Base2000-125k-lp")    


## Lote de simulación con 100 vectores de exclusión

run_batch(gtdata_00, FxEx_00, savepath, 
    param_constructor_fn=ParamTotalCPILegacyRebase, 
    rndseed = 0)

## Recoleeción de datos desde ruta

Exc_0019lp = collect_results(savepath)

## Análisis de resultados

# obtener longitud del vector de exclusión
exclusiones =  getindex.(map(x -> length.(x), Exc_0019lp[!,:params]),1)
Exc_0019lp[!,:exclusiones] = exclusiones 

# Ordenamiento por cantidad de exclusiones
Exc_0019lp = sort(Exc_0019lp, :exclusiones)

# DF ordenado por MSE
sort_0019 = sort(Exc_0019lp, :mse)

## Exctracción de vector de exclusión  y MSE
a = collect(sort_0019[1,:params])
sort_0019[1,:mse]


## Revisión gráfica 
mseplot = plot(collect(10:20),Exc_0019lp[1:end,:mse], xticks = 10:1:20,
    title = " Óptimización Base 2000",
    label = " MSE Exclusión fija Óptima Base 2000", 
    legend = :topleft, 
    xlabel= "Gastos Básicos Excluidos", ylabel = "MSE",
    dpi = 200) 

plot!([13],seriestype="vline", label = "Mínimo en 13 exclusiones")
# saveplot = plotsdir("fixed-exclusion","Base2000")    
savefig(mseplot, "plots//fixed-exclusion//Eval-19//mse-base2000-125K")

"""
###################  RESULTADOS BASE 2000

Matlab -> [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 exclusiones)
MSE = 0.777

###### Julia con 10K simulaciones para los primeros 100 vectores de exclusión ####### 
ResampleScrambleVarMonths, ParamTotalCPILegacyRebase, TrendRandomWalk :
exclusiones Base 2010 = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193] (13 exclusiones)
MSE = 1.2932962

##### Julia con 125K con los vectores 10 a 20 ################3
ResampleScrambleVarMonths, ParamTotalCPILegacyRebase, TrendRandomWalk :
exclusiones Base 2010 =  [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193] (13 exclusiones)
MSE = 1.2883958f0

"""


##########################  Optimización Base 2010 ##########################

# Vector óptimo base 2000 encontrado en la primera sección
exc00 =  [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193] 

## Creación de vector de de gastos básicos ordenados por volatilidad, con información a Diciembre de 2019
gtdata_10 = gtdata[Date(2019, 12)]

est_10 = std(gtdata_10[2].v |> capitalize |> varinteran, dims=1)

df = DataFrame(num = collect(1:279), Desv = vec(est_10))

sorted_std = sort(df, "Desv", rev=true)

vec_v = sorted_std[!,:num]

# Creación de vectores de exclusión
# Se crearán 100 vectores para la exploración inicial
v_exc = []
tot = []
total = []
for i in 1:length(vec_v)-259
   exc = vec_v[1:i]
   v_exc =  append!(v_exc, [exc])
   tot = (exc00, v_exc[i])
   total = append!(total, [tot])
end

total

## creación de diccionarios y ruta para lote de simulación

FxEx_10 = Dict(
    :inflfn => InflationFixedExclusionCPI.(total), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 125_000) |> dict_list


savepath10 = datadir("results","fixed-exclusion","Eval-19","Base2010-125k-lp")    

## Lote de simulación
run_batch(gtdata_10, FxEx_10, savepath10, 
    param_constructor_fn=ParamTotalCPILegacyRebase, 
    rndseed = 0)


## Recolección de resultados desde ruta

Exc_1019lp = collect_results(savepath10)

## Análisis de resultados

# obtener longitud del vector de exclusión 
exclusiones =  getindex.(map(x -> length.(x)[2], Exc_1019lp[!,:params]),1)
Exc_1019lp[!,:exclusiones] = exclusiones 

# Ordenamiento por cantidad de exclusiones
Exc_1019lp = sort(Exc_1019lp, :exclusiones)

# DF ordenado por MSE
sort_1019 = sort(Exc_1019lp, :mse)

## Exctracción de vector de exclusión  y MSE
a = collect(sort_1019[1,:params])
exc10 = a[2]

# Menor MSE
sort_1019[1,:mse]

## Revisión Gráfica
mseplot = plot(collect(1:20),Exc_1019lp[!,:mse], xticks = 1:1:20,
    title = " Óptimización Base 2010",
    label = " MSE Exclusión fija Óptima Base 2010", 
    legend = :topleft, 
    xlabel= "Gastos Básicos Excluidos", ylabel = "MSE",
    dpi = 200)

plot!([7],seriestype="vline", label = "Mínimo en 7 exclusiones")

savefig(mseplot, "plots//fixed-exclusion//Eval-19//mse-base2010-125k")

"""

################################# RESULTADOS DE LA OPTIMIZACIÓN ################################# 
######################################## PARA AMBAS BASES ####################################### 

###### Matlab #######
Base 2000 -> [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 exclusiones)
Base 2010 -> [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184] (17 exclusiones)
MSE = 0.64


###### Julia 10K simulaciones para los 100 primeros vectores de exclusión ####### 
ResampleScrambleVarMonths, ParamTotalCPILegacyRebase, TrendRandomWalk :
Base 2000 -> [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193] (13 exclusiones)
Base 2010 -> [29, 31, 116, 39, 46, 40, 30] (7 exclusiones)
MSE = 1.1399192f0

###### Julia 125K simulaciones para los vectores de 1 a 20 ####### 
ResampleScrambleVarMonths, ParamTotalCPILegacyRebase, TrendRandomWalk :
Base 2000 -> [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193] (13 exclusiones)
Base 2010 -> [29, 31, 116, 39, 46, 40, 30] (7 exclusiones)
MSE = 1.1360317f0

"""

########### EVALUACIÓN COMPARATIVA DE EXCLUSIONES ÓPTIMAS MATLAB Y Julia con 125_000 #####################

########  Exclusión óptima JULIA con 125K  #########
# vectores óptimos Julia
exc_opt = ([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193], [29, 31, 116, 39, 46, 40, 30])

# Configuración de simulación
config = SimConfig(InflationFixedExclusionCPI(exc_opt),resamplefn, trendfn, 125_000)

# Simulación
results, tray = makesim(gtdata_10, config; 
param_constructor_fn=ParamTotalCPILegacyRebase, 
rndseed = 0)

## Trayectoria

inflfn = InflationFixedExclusionCPI(exc_opt)
FxExOpt = inflfn(gtdata)
plotrng = Date(2001, 12):Month(1):Date(2021, 6)
plot(plotrng, FxExOpt, label="Exc. Óptima", dpi=200)
title!("Exclusión Fija ótpima")
hspan!([3,5], color=[:gray], alpha=0.25, label="")
hline!([4], linestyle=:dash, color=[:black], label = "")

savefig("plots//fixed-exclusion//Eval-19//tray-opt-19")

"""
################### Resultado Evaluación óptima Julia #########################3
julia> results
Dict{Symbol, Any} with 12 entries:
  :trendfn       => TrendRandomWalk{Float32}(Float32[0.953769, 0.948405, 0.926209, 0.902285, 0.832036, 0.825772, 0.799508, 0.789099, 0.764708, 0.757526  …  :params        => ([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193], [29, 31, 116, 39, 46, 40, 30])
  :measure       => "Exclusión fija de gastos básicos([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193], [29, 31, 116, 39, 46, 40, 30])"
  :resamplefn    => ResampleScrambleVarMonths()
  :mae           => 0.884287
  :me            => -0.677169
  :nsim          => 125000
  :rmse          => 0.884287
  :inflfn        => InflationFixedExclusionCPI{2}(([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193], [29, 31, 116, 39, 46, 40, 30]))
  :mse           => 1.13603
  :std_sim_error => 0.0056931
  :corr          => 0.963256


"""

######## Evaluación de medida obtenida en 2019 utilizando Julia  #############

e0019 =  [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161]
e1019 =  [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184]
excoptmt = (e0019, e1019)

config = SimConfig(InflationFixedExclusionCPI(e0019,e1019),resamplefn, trendfn, 125_000)

results, tray = makesim(gtdata_10, config; 
param_constructor_fn=ParamTotalCPILegacyRebase, 
rndseed = 0)

"""
Evaluación con mismos vectores de exclusión obtenidos en Matlab (MSE= 0.64)

Base 2000: [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161]
Base 2010: [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184] 

método de remuestreo:  ResampleScrambleVarMonths()
inflación paramétrica: ParamTotalCPILegacyRebase()
Función de tendencia:  TrendRandomWalk()

MSE MATLAB                   = 0.64
MSE JULIA (VECTORES MATLAB)  = 1.29644
MSE JULIA (VECTORES JULIA)   = 1.1360317


resultados
julia> results
Dict{Symbol, Any} with 12 entries:
  :trendfn       => TrendRandomWalk{Float32}(Float32[0.953769, 0.948405, 0.926209, 0.902285, 0.832036, 0.825772, 0.799508, 0.789099, 0.764708, 0.757526  …  
  :params        => ([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34,…  
  :measure       => "Exclusión fija de gastos básicos([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], [29, 31, 116, 39, 46, 40, 30, 35, 1…  
  :resamplefn    => ResampleScrambleVarMonths()
  :mae           => 0.991936
  :me            => -0.893427
  :nsim          => 125000
  :rmse          => 0.991936
  :inflfn        => InflationFixedExclusionCPI{2}(([35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161], [29, 31, 116, 39, 46, 40, 30, 35, 186,…  
  :mse           => 1.29644  <<<<<<<< ===========================
  :std_sim_error => 0.00519673
  :corr          => 0.976573



"""

############### comparación gráfica entre medidas obtenidas  #################

"""
Nota: Los valores de trayectoria de las inflaciones si son iguales en Matlab y en Julia.

"""

opt_mt = InflationFixedExclusionCPI(excoptmt)(gtdata)
opt_jl = InflationFixedExclusionCPI(exc_opt)(gtdata)
tot = InflationTotalCPI()(gtdata)

plotrng = Date(2001, 12):Month(1):Date(2021, 6)
plot(plotrng, opt_mt, label ="Exc. Óptima Matlab", dpi=200)
plot!(plotrng, opt_jl, label = "Exc. Óptima Julia")
plot!(plotrng, tot, label = "Inflación Total", color = :black, linestyle = :dot)
title!("Exclusión Fija Óptima")
hspan!([3,5], color=[:gray], alpha=0.25, label="")
hline!([4], linestyle=:dash, color=[:black], label = "")

savefig("plots//fixed-exclusion//Eval-19//Comp-Tray-tot")

## Dataframe con series de tiempo

medidas = DataFrame(fechas= string.(plotrng), optmt = opt_mt, optjl = opt_jl, total = tot)
last(medidas, 25)

# CSV.write("Datos.csv", last(medidas,25))