using DrWatson
@quickactivate "HEMI"

using HEMI
using InflationFunctions

using Test
using BenchmarkTools
using Plots


## Distribuciones de largo plazo
using InflationFunctions: V, WeightsDistr, ObservationsDistr, vposition

glp00 = WeightsDistr(gt00, V)
mean(glp00)
glp10 = WeightsDistr(gt10, V)
mean(glp10)

flp00 = ObservationsDistr(gt00, V)
mean(flp00)
flp10 = ObservationsDistr(gt10, V)
mean(flp10)

flp = flp00 + flp10
sum(flp), mean(flp)
glp = glp00 + glp10
sum(glp), mean(glp)



## Función de inflación MAI-G
inflfn = InflationCoreMai(MaiG(10))

mai_m = inflfn(gtdata, CPIVarInterm())
@btime inflfn($gtdata, CPIVarInterm())
@profview inflfn(gtdata, CPIVarInterm())

mai_tray_infl = inflfn(gtdata)

@btime inflfn($gtdata);


## Función de inflación MAI-F
inflfn = InflationCoreMai(MaiF(5))

mai_m = inflfn(gtdata, CPIVarInterm())
mai_tray_infl = inflfn(gtdata)

@btime inflfn($gtdata);


## Comparación BASE

mai_m = cliparray()
mai_f = mai_m[:, 1:2:end]
mai_g = mai_m[:, 2:2:end]


## MAI-G

mai_g_jl = mapreduce(hcat, [4,5,10,20,40]) do n 
    inflfn = InflationCoreMai(MaiG(n))
    inflfn(gtdata, CPIVarInterm())
end

# MSE intermensual 
mse_m = mean((mai_g_jl - mai_g) .^ 2, dims=1)

# MSE interanual 
a_mai_g = varinteran(capitalize(mai_g))
a_mai_g_jl = varinteran(capitalize(mai_g_jl))
mse_a = mean((a_mai_g - a_mai_g_jl) .^ 2, dims=1)

@info "Comparación de resultados BASE-Julia MAI-G" mse_m mse_a

# Revisar que no haya NaNs
@test all(.!(isnan.(a_mai_g_jl)))

# Gráficas 
for j in 1:5
    plot(infl_dates(gtdata), [a_mai_g[:, j], a_mai_g_jl[:, j]], 
        label=["MAI-G BASE" "MAI-G Julia"])
    savefig(joinpath(plotsdir(), "MAI-G-$j.png"))
end


## MAI-F

mai_f_jl = mapreduce(hcat, [4,5,10,20,40]) do n 
    inflfn = InflationCoreMai(V, MaiF(n))
    inflfn(gtdata, CPIVarInterm())
end

# MSE intermensual 
mse_m = mean((mai_f_jl - mai_f) .^ 2, dims=1)

# MSE interanual 
a_mai_f = varinteran(capitalize(mai_f))
a_mai_f_jl = varinteran(capitalize(mai_f_jl))
mse_a = mean((a_mai_f - a_mai_f_jl) .^ 2, dims=1)

@info "Comparación de resultados BASE-Julia MAI-G" mse_m mse_a

# Revisar que no haya NaNs
@test all(.!(isnan.(a_mai_f_jl)))

# Gráficas 
for j in 1:5
    plot(infl_dates(gtdata), [a_mai_f[:, j], a_mai_f_jl[:, j]], 
        label=["MAI-F BASE" "MAI-F Julia"])
    savefig(joinpath(plotsdir(), "MAI-F-$j.png"))
end




## Prueba de generación de trayectorias 


using Distributed
addprocs(4, exeflags="--project")

@everywhere using HEMI 

resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()

inflfn = InflationCoreMai(MaiF(5))

@time tray_infl = pargentrayinfl(inflfn, resamplefn, trendfn, gtdata; K=1_000);
# 27.550400 seconds (347.59 k allocations: 20.012 MiB, 0.05% gc time, 0.46% compilation time)
# 25.112090 seconds (81.94 k allocations: 3.937 MiB)
# 24.051167 seconds (81.39 k allocations: 3.900 MiB)
# 18.790535 seconds (80.21 k allocations: 3.800 MiB)