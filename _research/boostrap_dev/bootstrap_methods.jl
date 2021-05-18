using DrWatson
@quickactivate :HEMI

using InflationEvalTools: scramblevar
using DependentBootstrap
using Bootstrap
using CSV, DataFrames

## Funciones para investigación de remuestreo
includet(projectdir("_research", "boostrap_dev", "helper_functions.jl"))

## Cómputo de resultados de error cuadrático en función de rezagos
base = gt10
basetag = "2010"
nsim = 1000

# Parámetros para archivos
params = (base=basetag, nsim=nsim)

# Métodos de remuestreo de bloques 
nbb_res = map_block_lags(base.v, method=:nooverlap, methodlabel = "NBB", N=nsim)
cbb_res = map_block_lags(base.v, method=:circular, methodlabel = "CBB", N=nsim)
mbb_res = map_block_lags(base.v, method=:moving, methodlabel = "MBB", N=nsim)
sbb_res = map_block_lags(base.v, method=:stationary, methodlabel = "SBB", N=nsim)

# Métodos que no varían el tamaño de bloque o ancho de banda
scramble_res = map_df_resample(base.v, scramblevar, 
    methodlabel="Método meses (Scramble)", blocklength=1, N=nsim)
maxentropy_res = map_df_resample(base.v, me_resample, 
    methodlabel="Máxima entropía (MEBOOT)", blocklength=120, N=nsim)
gsbb_mod_res = map_df_resample(base.v, resample_gsbb_mod, 
    methodlabel="Método GSBB-II", blocklength=25, N=nsim, decompose_stations = false)

# Método de Wild Dependent Bootstrap
wdb_res = map_block_lags_wdb(base.v, lrange=1:25, N=nsim)

# Método de remuestreo con Generalized Seasonal Block Bootstrap
# Este funciona mejor quitando las medias de meses y manejar la estacionalidad
# remanente con la metodología de muestreo generalizado estacional
gsbb_res = map_block_lags_gsbb(base.v, methodlabel = "GSBB", N=nsim, decompose_stations = true)


## Gráfica de componentes de media
p1 = plot(
    hcat(nbb_res[:, 1], cbb_res[:, 1], mbb_res[:, 1], sbb_res[:, 1], wdb_res[:, 1], gsbb_res[:, 1]), 
    label=["NBB" "CBB" "MBB" "SBB" "WDB" "GSBB"], 
    linealpha = [0.7 0.7 0.7 1.0 0.7 1.0],
    linewidth = [1 1 1 3 1 3], 
    linestyle = [:solid :solid :solid :solid :solid :dashdot], 
    color = [:auto :auto :auto :auto :auto :blue], 
    legend = :topleft)

hline!(gsbb_mod_res[:, 1], label="GSBB-II", linestyle=:dash, linewidth=2, color=:black)
hline!(scramble_res[:, 1], label="Scramble", linestyle=:dash, linewidth=3)
hline!(maxentropy_res[:, 1], label="MEBOOT", linealpha=0.7)
title!("Error cuadrático de la media")
savefig(plotsdir("bootstrap_methods", savename("mean_err_components", params)))

## Gráfica de componentes de varianza
p2 = plot(
    hcat(nbb_res[:, 2], cbb_res[:, 2], mbb_res[:, 2], sbb_res[:, 2], wdb_res[:, 2], gsbb_res[:, 2]), 
    label=["NBB" "CBB" "MBB" "SBB" "WDB" "GSBB"], 
    linealpha = [0.7 0.7 0.7 1.0 0.7 0.7],
    linewidth = [1 1 1 3 1 3], 
    linestyle = [:solid :solid :solid :solid :solid :dashdot], 
    color = [:auto :auto :auto :auto :auto :blue], 
    legend = :topleft)

hline!(gsbb_mod_res[:, 2], label="GSBB-II", linestyle=:dash, linewidth=2, color=:black)
hline!(scramble_res[:, 2], label="Scramble", linestyle=:dash, linewidth=3)
hline!(maxentropy_res[:, 2], label="MEBOOT", linealpha=0.7)
title!("Error cuadrático de la varianza")
savefig(plotsdir("bootstrap_methods", savename("var_err_components", params)))


## Gráfica de componentes de covarianza
p3 = plot(
    hcat(nbb_res[:, 3], cbb_res[:, 3], mbb_res[:, 3], sbb_res[:, 3], wdb_res[:, 3], gsbb_res[:, 3]), 
    label=["NBB" "CBB" "MBB" "SBB" "WDB" "GSBB"], 
    linealpha = [0.7 0.7 0.7 1.0 0.7 0.7],
    linewidth = [1 1 1 3 1 3], 
    linestyle = [:solid :solid :solid :solid :solid :dashdot], 
    color = [:auto :auto :auto :auto :auto :blue], 
    legend = :topleft)

hline!(gsbb_mod_res[:, 3], label="GSBB-II", linestyle=:dash, linewidth=2, color=:black)
hline!(scramble_res[:, 3], label="Scramble", linestyle=:dash, linewidth=3)
hline!(maxentropy_res[:, 3], label="MEBOOT", linealpha=0.7)
title!("Error cuadrático de la covarianza")
savefig(plotsdir("bootstrap_methods", savename("cov_err_components", params)))


## Gráfica de componentes de autocovarianza
p4 = plot(
    hcat(nbb_res[:, 4], cbb_res[:, 4], mbb_res[:, 4], sbb_res[:, 4], wdb_res[:, 4], gsbb_res[:, 4]), 
    label=["NBB" "CBB" "MBB" "SBB" "WDB" "GSBB"],
    linealpha = [0.7 0.7 0.7 1.0 0.7 0.7],
    linewidth = [1 1 1 3 1 3], 
    linestyle = [:solid :solid :solid :solid :solid :dashdot], 
    color = [:auto :auto :auto :auto :auto :blue], 
    legend = :topleft)

hline!(gsbb_mod_res[:, 4], label="GSBB-II", linestyle=:dash, linewidth=2, color=:black)
hline!(scramble_res[:, 4], label="Scramble", linestyle=:dash, linewidth=3)
hline!(maxentropy_res[:, 4], label="MEBOOT", linealpha=0.7)
title!("Error cuadrático de la autocovarianza")
savefig(plotsdir("bootstrap_methods", savename("autocov_err_components", params)))


## Gráficas juntas 

plot(p1, p2, size=(1000, 600), layout=(1, 2))
savefig(plotsdir("bootstrap_methods", savename("mean_var_err_components", params)))

plot(p3, p4, size=(1000, 600), layout=(1, 2))
savefig(plotsdir("bootstrap_methods", savename("cov_autocov_err_components", params)))


## Compilar resultados en DataFrames

bootdf = [nbb_res; mbb_res; cbb_res; sbb_res; scramble_res; maxentropy_res; gsbb_res; gsbb_mod_res; wdb_res]
bootdf
CSV.write(datadir("bootstrap_methods", savename("results_methods", params, "csv")), bootdf)

# Obtener los mejores parámetros de cada metodología
sumdf = combine(sdf -> sdf[argmin(sdf.ErrorAutocov), :], groupby(bootdf, :Metodo))
CSV.write(datadir("bootstrap_methods", savename("summary_methods", params, "csv")), sumdf)


## Gráficas de barra de los mejores métodos
categ = sumdf.Metodo .* " (L=" .* string.(sumdf.BloqueL) .* ")"
bar(categ, sumdf.ErrorAutocov, label = :none, orientation=:h)
xlabel!("Error de autocovarianza")
savefig(plotsdir("bootstrap_methods", "error_autocov"))

bar(categ, sumdf.ErrorCov, label = :none, orientation=:h)
xlabel!("Error de covarianza")
savefig(plotsdir("bootstrap_methods", "error_cov"))



## Gráficas de series remuestreadas

# completar con los últimos métodos


## Selección de rezagos por criterio de autocovarianza 

l_nbb = argmin(nbb_res[:, :ErrorAutocov])
l_mbb = argmin(mbb_res[:, :ErrorAutocov])
l_cbb = argmin(cbb_res[:, :ErrorAutocov])
l_sbb = argmin(sbb_res[:, :ErrorAutocov])
l_gsbb = argmin(gsbb_res[:, :ErrorAutocov])


## Ilustración métodos de muestreo en base 2000, x = 1 (Arroz)

if params.base == "2000"
    # Ilustración métodos de muestreo en base 2000, x = 1 (Arroz)
    path = mkpath(plotsdir("bootstrap_methods", "arroz_2000"))
    gb_label = "Arroz"
    gb_x = 1
else
    # Ilustración métodos de muestreo en base 2010, x = 29 (Tomate)
    path = mkpath(plotsdir("bootstrap_methods", "tomate_2010"))
    gb_label = "Tomate"
    gb_x = 29
end 

# Métodos de bloque 
p = (params..., gb = gb_label, method="NBB", L = l_nbb)
create_gif(base, resample_block_fn(l_nbb, :nooverlap), 
    path = joinpath(path, savename("resample", p, "gif")), 
    x = gb_x)
    
p = (params..., gb = gb_label, method="MBB", L = l_mbb)
create_gif(base, resample_block_fn(l_mbb, :moving), 
    path = joinpath(path, savename("resample", p, "gif")), 
    x = gb_x)

p = (params..., gb = gb_label, method="CBB", L = l_cbb)
create_gif(base, resample_block_fn(l_cbb, :circular), 
    path = joinpath(path, savename("resample", p, "gif")), 
    x = gb_x)
    
p = (params..., gb = gb_label, method="SBB", L = l_sbb)
create_gif(base, resample_block_fn(l_sbb, :stationary), 
    path = joinpath(path, savename("resample", p, "gif")), 
    x = gb_x)

# Método de remuestreo de selección de meses
p = (params..., gb = gb_label, method="Scramble", L = 1)
create_gif(base, scramblevar, 
    path = joinpath(path, savename("resample", p, "gif")), 
    x = gb_x)
    
# Método de máxima entropía 
p = (params..., gb = gb_label, method="MaxEntropy", L = 120)
create_gif(base, me_resample, 
    path = joinpath(path, savename("resample", p, "gif")), 
    x = gb_x)

# GSBB
p = (params..., gb = gb_label, method="GSBB", L = l_gsbb)
create_gif(base, v -> resample_gsbb(v, 12, l_gsbb), 
    path = joinpath(path, savename("resample", p, "gif")), 
    x = gb_x)
    
# GSBB modificado
p = (params..., gb = gb_label, method="GSBB-II", L = 25)
create_gif(base, resample_gsbb_mod, 
    path = joinpath(path, savename("resample", p, "gif")), 
    x = gb_x, decompose_stations = false)





## Procedimiento de selección de bloque automático de Politis y White 2004, 2009

# Utilizar este código para mostrar una gráfica de barras con el largo óptimo por serie de cada base del IPC  
# function temperature_heatmap(x, T)
# 	p = heatmap(x, [0.], collect(T'), 
# 			   clims=(-1., 1.), cbar=false, xticks=nothing, yticks=nothing)
# 	return p
# end

function optblock_politis_white(base, bootmethod = :stationary; decompose_stations = true)
    
    vmat = decompose_stations ? base.v - monthavg(base.v) : base.v
    G = size(vmat, 2)
    
    optblock = map(1:G) do j
        try
            bi = BootInput(resid[:, j], blocklength = 0, 
                bootmethod = bootmethod, numresample=1)
            bi.blocklength
        catch 
            @warn "Error en cómputo de bloque óptimo en gasto $j"
            0.0
        end
    end
    optblock
end 

sbb_opt_blocks = optblock_politis_white(base, :stationary; decompose_stations = true)
p1 = bar(sbb_opt_blocks, label="SBB", alpha=0.3)
hline!([mean(sbb_opt_blocks), median(sbb_opt_blocks)], label = "Media y mediana", 
    linealpha = 0.7, linestyle = :dash, linewidth = 2)
hline!(quantile(sbb_opt_blocks, [0.9, 0.95, 0.99]), 
    label = "Percentiles 90%, 95% y 99%", 
    linealpha = 0.5, linestyle = :dash, linewidth = 2)
title!("Bloque óptimo base $basetag")
 
# mbb_opt_blocks = optblock_politis_white(base, :moving; decompose_stations = true)


