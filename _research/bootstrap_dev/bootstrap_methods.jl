using DrWatson
@quickactivate "bootstrap_dev"

using HEMI
using InflationEvalTools: scramblevar
using DependentBootstrap
using Bootstrap
using CSV, DataFrames
using JLD2

## Cargar datos 
@load projectdir("..", "..", "data", "guatemala", "gtdata32.jld2") gt00 gt10
gtdata = UniformCountryStructure(gt00, gt10)

## Funciones para investigación de remuestreo
Revise.includet(projectdir("helper_functions.jl"))

## Obtener argumentos de consola
basearg = !isempty(ARGS) ? ARGS[1] : "2000"

## Cómputo de resultados de error cuadrático en función de rezagos
base = basearg == "2000" ? gt00 : gt10
basetag = base == gt00 ? "2000" : "2010"
nsim = 10_000
maxlags = 36

# Parámetros para archivos
params = (base=basetag, nsim=nsim, maxlags=maxlags)

# Directorio de gráficas
PLOTS_DIR = mkpath(plotsdir("bootstrap_methods", savename(params)))


## Resultados de métodos de remuestreo de bloques 
nbb_res = map_block_lags(base.v, method=:nooverlap, methodlabel = "NBB", 
    N=nsim, maxlags=maxlags)
cbb_res = map_block_lags(base.v, method=:circular, methodlabel = "CBB", 
    N=nsim, maxlags=maxlags)
mbb_res = map_block_lags(base.v, method=:moving, methodlabel = "MBB", 
    N=nsim, maxlags=maxlags)
sbb_res = map_block_lags(base.v, method=:stationary, methodlabel = "SBB", 
    N=nsim, maxlags=maxlags)

# Métodos que no varían el tamaño de bloque o ancho de banda
scramble_res = map_df_resample(base.v, scramblevar, 
    methodlabel="Método meses (Scramble)", blocklength=1, N=nsim)

    # Método de máxima entropía
maxentropy_res = map_df_resample(base.v, me_resample, 
    methodlabel="Máxima entropía (MEBOOT)", blocklength=120, N=nsim)

# Método de Wild Dependent Bootstrap
wdb_res = map_block_lags_wdb(base.v, lrange=1:maxlags, N=nsim)

# Método de remuestreo con Generalized Seasonal Block Bootstrap
# Este funciona mejor quitando las medias de meses y manejar la estacionalidad
# remanente con la metodología de muestreo generalizado estacional
gsbb_res = map_block_lags_gsbb(base.v, methodlabel = "GSBB", 
    N=nsim, maxlags=maxlags, decompose_stations = true)

# GSBB-II con extensión de períodos 
gsbb_mod_res = map_df_resample(base.v, resample_gsbb_mod, 
    methodlabel="Método GSBB-II", 
    blocklength=25, N=nsim, decompose_stations = false)

# Método de remuestreo de Stationary Block Bootstrap con extensión de períodos
sbb_mod_res = map_block_lags(base.v, method=:stationary, 
    methodlabel = "SBB-II", 
    N=nsim, maxlags=maxlags, decompose_stations=false)
    
# Método experimental de remuestreo de Stationary Seasonal Block Bootstrap con
# selección circular de índices en el remuestreo
ssbb_res = map_block_lags_ssbb(base.v, methodlabel = "SSBB-EXP", 
    N=nsim, decompose_stations=false, maxlags = maxlags)


@show size(nbb_res[:, 1])
@show size(cbb_res[:, 1])
@show size(mbb_res[:, 1])
@show size(sbb_res[:, 1])
@show size(wdb_res[:, 1])
@show size(gsbb_res[:, 1])
@show size(sbb_mod_res[:, 1])
@show size(ssbb_res[:, 1])


## Guardar resultados 

results_file = datadir("bootstrap_methods", savename("bootstrap_methods_results", params, "jld2"))

wsave(results_file, 
    "nbb_res", nbb_res, 
    "sbb_res", sbb_res, 
    "mbb_res", mbb_res, 
    "cbb_res", cbb_res, 
    "scramble_res", scramble_res, 
    "maxentropy_res", maxentropy_res, 
    "wdb_res", wdb_res, 
    "gsbb_res", gsbb_res, 
    "gsbb_mod_res", gsbb_mod_res, 
    "sbb_mod_res", sbb_mod_res, 
    "ssbb_res", ssbb_res)

## Cargar resultados 

results = wload(results_file)
@unpack nbb_res, 
    cbb_res, 
    mbb_res, 
    sbb_res, 
    scramble_res, 
    maxentropy_res, 
    wdb_res, 
    gsbb_res, 
    gsbb_mod_res, 
    sbb_mod_res, 
    ssbb_res = results


## Gráfica de componentes de media
p1 = plot(
    hcat(nbb_res[:, 1], cbb_res[:, 1], mbb_res[:, 1], sbb_res[:, 1], wdb_res[:, 1], gsbb_res[:, 1], sbb_mod_res[:, 1], ssbb_res[:, 1]), 
    label=["NBB" "CBB" "MBB" "SBB" "WDB" "GSBB" "SBB-II" "SSBB-EXP"], 
    linealpha = [0.7 0.7 0.7 1.0 0.7 1.0 0.7 0.7],
    linewidth = [1 1 1 3 1 3 2 2], 
    linestyle = [:solid :solid :solid :solid :solid :dashdot :dash :dash], 
    color = [:auto :auto :auto :auto :auto :blue :red :black], 
    legend = :topright)

hline!(gsbb_mod_res[:, 1], label="GSBB-II", linestyle=:dash, linewidth=2, color=:black)
hline!(scramble_res[:, 1], label="Scramble", linestyle=:dash, linewidth=3)
hline!(maxentropy_res[:, 1], label="MEBOOT", linealpha=0.7)
title!("Error cuadrático de la media")
savefig(joinpath(PLOTS_DIR, savename("mean_err_components", params)))

## Gráfica de componentes de varianza
p2 = plot(
    hcat(nbb_res[:, 2], cbb_res[:, 2], mbb_res[:, 2], sbb_res[:, 2], wdb_res[:, 2], gsbb_res[:, 2], sbb_mod_res[:, 2], ssbb_res[:, 2]), 
    label=["NBB" "CBB" "MBB" "SBB" "WDB" "GSBB" "SBB-II" "SSBB-EXP"], 
    linealpha = [0.7 0.7 0.7 1.0 0.7 1.0 0.7 0.7],
    linewidth = [1 1 1 3 1 3 2 2], 
    linestyle = [:solid :solid :solid :solid :solid :dashdot :dash :dash], 
    color = [:auto :auto :auto :auto :auto :blue :red :black], 
    legend = :topright)

hline!(gsbb_mod_res[:, 2], label="GSBB-II", linestyle=:dash, linewidth=2, color=:black)
hline!(scramble_res[:, 2], label="Scramble", linestyle=:dash, linewidth=3)
hline!(maxentropy_res[:, 2], label="MEBOOT", linealpha=0.7)
title!("Error cuadrático de la varianza")
savefig(joinpath(PLOTS_DIR, savename("var_err_components", params)))


## Gráfica de componentes de covarianza
p3 = plot(
    hcat(nbb_res[:, 3], cbb_res[:, 3], mbb_res[:, 3], sbb_res[:, 3], wdb_res[:, 3], gsbb_res[:, 3], sbb_mod_res[:, 3], ssbb_res[:, 3]), 
    label=["NBB" "CBB" "MBB" "SBB" "WDB" "GSBB" "SBB-II" "SSBB-EXP"], 
    linealpha = [0.7 0.7 0.7 1.0 0.7 1.0 0.7 0.7],
    linewidth = [1 1 1 3 1 3 2 2], 
    linestyle = [:solid :solid :solid :solid :solid :dashdot :dash :dash], 
    color = [:auto :auto :auto :auto :auto :blue :red :black], 
    legend = :topright)

hline!(gsbb_mod_res[:, 3], label="GSBB-II", linestyle=:dash, linewidth=2, color=:black)
hline!(scramble_res[:, 3], label="Scramble", linestyle=:dash, linewidth=3)
hline!(maxentropy_res[:, 3], label="MEBOOT", linealpha=0.7)
title!("Error cuadrático de la covarianza")
savefig(joinpath(PLOTS_DIR, savename("cov_err_components", params)))


## Gráfica de componentes de autocovarianza
p4 = plot(
    hcat(nbb_res[:, 4], cbb_res[:, 4], mbb_res[:, 4], sbb_res[:, 4], wdb_res[:, 4], gsbb_res[:, 4], sbb_mod_res[:, 4], ssbb_res[:, 4]), 
    label=["NBB" "CBB" "MBB" "SBB" "WDB" "GSBB" "SBB-II" "SSBB-EXP"], 
    linealpha = [0.7 0.7 0.7 1.0 0.7 1.0 0.7 0.7],
    linewidth = [1 1 1 3 1 3 2 2], 
    linestyle = [:solid :solid :solid :solid :solid :dashdot :dash :dash], 
    color = [:auto :auto :auto :auto :auto :blue :red :black], 
    legend = :topright)

hline!(gsbb_mod_res[:, 4], label="GSBB-II", linestyle=:dash, linewidth=2, color=:black)
hline!(scramble_res[:, 4], label="Scramble", linestyle=:dash, linewidth=3)
hline!(maxentropy_res[:, 4], label="MEBOOT", linealpha=0.7)
title!("Error cuadrático de la autocovarianza")
savefig(joinpath(PLOTS_DIR, savename("autocov_err_components", params)))


## Gráficas juntas 

plot(p1, p2, size=(1000, 600), layout=(1, 2))
savefig(joinpath(PLOTS_DIR, savename("mean_var_err_components", params)))

plot(p3, p4, size=(1000, 600), layout=(1, 2))
savefig(joinpath(PLOTS_DIR, savename("cov_autocov_err_components", params)))


## Compilar resultados en DataFrames

bootdf = [nbb_res; mbb_res; cbb_res; sbb_res; scramble_res; 
    maxentropy_res; gsbb_res; gsbb_mod_res; wdb_res; sbb_mod_res]
bootdf
CSV.write(datadir("bootstrap_methods", savename("results_methods", params, "csv")), bootdf)

# Obtener los mejores parámetros de cada metodología
sumdf = combine(sdf -> sdf[argmin(sdf.ErrorAutocov), :], groupby(bootdf, :Metodo))
CSV.write(datadir("bootstrap_methods", savename("summary_methods", params, "csv")), sumdf)


# ## Gráficas de barra de los mejores métodos
# categ = sumdf.Metodo .* " (L=" .* string.(sumdf.BloqueL) .* ")"
# bar(categ, sumdf.ErrorAutocov, label = :none, orientation=:h)
# xlabel!("Error de autocovarianza")
# savefig(joinpath(PLOTS_DIR, "error_autocov"))

# bar(categ, sumdf.ErrorCov, label = :none, orientation=:h)
# xlabel!("Error de covarianza")
# savefig(joinpath(PLOTS_DIR, "error_cov"))

#= 

## Gráficas de series remuestreadas

## Selección de rezagos por criterio de autocovarianza 

l_nbb = argmin(nbb_res[:, :ErrorAutocov])
l_mbb = argmin(mbb_res[:, :ErrorAutocov])
l_cbb = argmin(cbb_res[:, :ErrorAutocov])
l_sbb = argmin(sbb_res[:, :ErrorAutocov])
l_gsbb = argmin(gsbb_res[:, :ErrorAutocov])
l_wdb = argmin(gsbb_res[:, :ErrorAutocov])
l_sbb_mod = argmin(sbb_mod_res[:, :ErrorAutocov])
l_ssbb = argmin(ssbb_res[:, :ErrorAutocov])


## Ilustración métodos de muestreo en base 2000, x = 1 (Arroz)

if params.base == "2000"
    # Ilustración métodos de muestreo en base 2000, x = 1 (Arroz)
    path = mkpath(joinpath(PLOTS_DIR, "arroz_2000"))
    gb_label = "Arroz"
    gb_x = 1
else
    # Ilustración métodos de muestreo en base 2010, x = 29 (Tomate)
    path = mkpath(joinpath(PLOTS_DIR, "tomate_2010"))
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
    x = gb_x, decompose_stations = false, extend_periods = true)
    
# Método de Wild Dependent Bootstrap
p = (params..., gb = gb_label, method="WDB", L = l_wdb)
create_gif(base, WildDependentBootstrap(size(base.v, 1), l_wdb*one(eltype(base))), 
    path = joinpath(path, savename("resample", p, "gif")), 
    x = gb_x, decompose_stations = false)

# SBB-II (extensión a 300 períodos)
p = (params..., gb = gb_label, method="SBB-II", L = l_sbb_mod)
create_gif(base, v -> resample_block_mod(v, l_sbb_mod, :stationary), 
    path = joinpath(path, savename("resample", p, "gif")), 
    x = gb_x, decompose_stations = false, extend_periods = true)
    
# SSBB (experimental): Stationary Seasonal Block Bootstrap 
p = (params..., gb = gb_label, method="SSBB-EXP", L = l_ssbb)
create_gif(base, v -> resample_ssbb(v, l_ssbb), 
    path = joinpath(path, savename("resample", p, "gif")), 
    x = gb_x, decompose_stations = false, extend_periods = false)


## Procedimiento de selección de bloque automático de Politis y White 2004, 2009

sbb_opt_blocks = optblock_politis_white(base, :stationary; decompose_stations = true)
p_sbb = plot_bar_optblock(sbb_opt_blocks, "SBB", basetag)

cbb_opt_blocks = optblock_politis_white(base, :circular; decompose_stations = true) 
p_cbb = plot_bar_optblock(cbb_opt_blocks, "CBB", basetag)

plot(p_sbb, p_cbb, layout=(1, 2), size=(1000, 600), ylims=(0,30))
savefig(joinpath(PLOTS_DIR, savename("opt_block_politis_white", params, accesses=(:base,))))

 =#
