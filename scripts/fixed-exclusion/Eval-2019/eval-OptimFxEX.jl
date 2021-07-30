##
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

##

gtdata_00 = gtdata[Date(2010, 12)]
trendfn = TrendRandomWalk()
# legacy_param = ParamTotalCPILegacyRebase()
resamplefn = ResampleScrambleVarMonths() 


##

estd = std(varinteran(capitalize(gt00.v)), dims=1)

df = DataFrame(num = collect(1:218), Desv = vec(estd))

sorted_std = sort(df, "Desv", rev=true)

vec_v = sorted_std[!,:num]

# Creación de vectores de exclusión
# Se crearán 20 vectores para la exploración inicial
v_exc = []
for i in 1:length(vec_v)-118
   exc = vec_v[1:i]
   append!(v_exc, [exc])
end

v_exc

##
FxEx_00 = Dict(
    :inflfn => InflationFixedExclusionCPI.(v_exc), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 10_000) |> dict_list

savepath = datadir("results","fixed-exclusion","Eval-19","Base2000-10k-lp")    


##
run_batch(gtdata_00, FxEx_00, savepath, 
    param_constructor_fn=ParamTotalCPILegacyRebase, 
    rndseed = 0)

##

Exc_0019lp = collect_results(savepath)

##

# Para ordenamiento por cantidad de exclusiones 
exclusiones =  getindex.(map(x -> length.(x), Exc_0019lp[!,:params]),1)
Exc_0019lp[!,:exclusiones] = exclusiones 
# Ordenamiento por cantidad de exclusiones
Exc_0019lp = sort(Exc_0019lp, :exclusiones)

# DF ordenado por MSE
sort_0019 = sort(Exc_0019lp, :mse)

## Exctracción de vector de exclusión 
a = collect(sort_0019[1,:params])
sort_0019[!,:mse]
"""
Matlab con ResampleScrambleVarMonths -> [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161] (14 exclusiones)

exclusiones Base 2010 = [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193] (13 exclusiones)
MSE = 1.2932962
"""

## Revisión gráfica 
mseplot = plot(Exc_0019lp[2:end,:mse], 
    title = " Óptimización Base 2000",
    label = " MSE Exclusión fija Óptima Base 2000", 
    legend = :topleft, 
    xlabel= "Gastos Básicos Excluidos", ylabel = "MSE",
    dpi = 150) 

plot!([12],seriestype="vline", label = "Mínimo en 13 exclusiones")
# saveplot = plotsdir("fixed-exclusion","Base2000")    
savefig(mseplot, "plots//fixed-exclusion//Eval-19//mse-base2000")

##  base 2010

exc00 =  [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193] 

##
est_10 = std(gt10.v |> capitalize |> varinteran, dims=1)

df = DataFrame(num = collect(1:279), Desv = vec(est_10))

sorted_std = sort(df, "Desv", rev=true)

vec_v = sorted_std[!,:num]

##
v_exc = []
tot = []
total = []
for i in 1:length(vec_v)-179
   exc = vec_v[1:i]
   v_exc =  append!(v_exc, [exc])
   tot = (exc00, v_exc[i])
   total = append!(total, [tot])
end

total

##
gtdata_10 = gtdata[Date(2019, 12)]

FxEx_10 = Dict(
    :inflfn => InflationFixedExclusionCPI.(total), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 10_000) |> dict_list


savepath10 = datadir("results","fixed-exclusion","Eval-19","Base2010-10k-lp")    

##
run_batch(gtdata_10, FxEx_10, savepath10, 
    param_constructor_fn=ParamTotalCPILegacyRebase, 
    rndseed = 0)


## resultados

Exc_1019lp = collect_results(savepath10)

# Para ordenamiento por cantidad de exclusiones 
exclusiones =  getindex.(map(x -> length.(x)[2], Exc_1019lp[!,:params]),1)
Exc_1019lp[!,:exclusiones] = exclusiones 
# Ordenamiento por cantidad de exclusiones
Exc_1019lp = sort(Exc_1019lp, :exclusiones)

# DF ordenado por MSE
sort_1019 = sort(Exc_1019lp, :mse)

## Exctracción de vector de exclusión 
a = collect(sort_1019[1,:params])
exc10 = a[2]

# Menor MSE
sort_1019[1,:mse]

"""
Matlab con ResampleScrambleVarMonths -> [29,31,116,39,46,40,30,35,186,47,197,41,22,48,185,34,184] (17 exclusiones)

exclusiones Base 2010 =  [29, 46, 39, 31, 116, 40, 186, 30, 35, 47, 197, 185, 196, 41, 184] (15 exclusiones)
MSE = 1.0963f0
"""
##
mseplot = plot(Exc_1019lp[!,:mse], 
    title = " Óptimización Base 2010",
    label = " MSE Exclusión fija Óptima Base 2010", 
    legend = :topleft, 
    xlabel= "Gastos Básicos Excluidos", ylabel = "MSE",
    dpi = 200)

plot!([15],seriestype="vline", label = "Mínimo en 15 exclusiones")

savefig(mseplot, "plots//fixed-exclusion//Eval-19//mse-base2010")


## Evaluación de medida 

results = makesim()