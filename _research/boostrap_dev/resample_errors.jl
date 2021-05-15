using DrWatson
@quickactivate :HEMI

using InflationEvalTools: scramblevar
using DependentBootstrap
using Bootstrap
using CSV, DataFrames

## Funciones para investigación de remuestreo

# Obtener residuos de las variaciones intermensuales promedio
function monthavg(vmat)
    avgmat = similar(vmat)
    for i in 1:12
        avgmat[i:12:end, :] .= mean(vmat[i:12:end, :], dims=1)
    end
    avgmat
end

# Función de remuestreo que computa error cuadrático en autocovarianza y covarianza 
function mse_cov_autocov(vmat, resamplefn; N = 100, decompose_stations=true)
    # Varianza y autocovarianza poblacional
    vmat_cov = cov(vmat)
    vmat_autocov = mapreduce(col -> autocov(col, 1:12, demean=false), hcat, eachcol(vmat))

    # Matriz de residuos
    month_avg = monthavg(vmat)
    resid_vmat = vmat - month_avg

    G = size(vmat, 2)
    res_cov = zeros(eltype(vmat), G, G, N)
    res_autocov = zeros(eltype(vmat), 12, G, N)

    # Remuestrear datos N veces y obtener el MSE
    for j in 1:N 
        if decompose_stations
            boot_vmat = resamplefn(resid_vmat) + month_avg
        else
            boot_vmat = resamplefn(vmat)
        end

        # Matriz de covarianza y funciones de autocovarianza de la matriz de
        # variaciones intermensuales
        res_cov[:, :, j] = cov(boot_vmat)
        res_autocov[:, :, j] = autocov(boot_vmat, 1:12, demean=!decompose_stations)

    end

    NG = sum(1:G)
    mse_cov = sum((res_cov .- vmat_cov) .^ 2) / (2 * NG * N)
    mse_autocov = sum((res_autocov .- vmat_autocov) .^ 2) / (12 * G * N)
    # end

    [mse_cov mse_autocov]
    # res_cov, res_autocov
end

# Función de remuestreo para métodos de bloque de DependentBootstrap
function resample_block(vmat, blocklength, bootmethod)
    first(dbootdata(vmat; blocklength, numresample=1, bootmethod))
end

# Función de remuestreo de MaximumEntropy del paquete Bootstrap
function me_resample(vmat)
    s = MaximumEntropySampling(1)
    bootsample = similar(vmat)
    cols = size(vmat, 2)    
    for j in 1:cols
        origdata = vmat[:, j]
        bootstrap(mean, origdata, s)
        bootsample[:, j] = draw!(s.cache, origdata, bootsample[:, j])
    end
    bootsample
end

# Función de remuestreo de extensión de base del IPC
function resample_JC_blocks(vmat)
    G = size(vmat, 2)
    boot_vmat = Matrix{eltype(vmat)}(undef, 300, G)

    # Índices de muestreo para bloques de 25 meses
    ids = [(12i + j):(12i + j + 24) for i in 0:7, j in 1:12]

    for j in 1:12
        # Muestrear un rango y asignarlo en el bloque de 25 meses
        range_ = rand(ids[:, j])
        boot_vmat[(25(j-1)+1):(25j), :] = vmat[range_, :]
    end

    boot_vmat
end

## Función de remuestreo con Wild Dependent Bootstrap

using LinearAlgebra, Distributions

# kernel de Bartlett
function k(x; l=1)
	0 <= abs(x/l) <= 1 && return 1 - abs(x/l)
	0
end

# kernel de Parzen
function k(x; l=1)
    0 <= abs(x/l) <= 0.5 && return 1 - 6(x/l)^2*(1-abs(x/l)) 
    0.5 < abs(x/l) <= 1 && return 2(1-abs(x/l))^3
    0
end

struct WildDependentBootstrap{U}
    l::U
    T::Int
    sigma_sqrt::Matrix{U}

    # Se guarda la matriz sigma_sqrt, utilizada para generar nuevas secuencias W
    function WildDependentBootstrap(T::Int, l::U) where U <: AbstractFloat
        # Obtener la matriz para muestreo
        sigma = [k((i-j); l) for i in 1:T, j in 1:T]
        sigma_sqrt = sqrt(sigma)
        new{U}(l, T, sigma_sqrt)
    end
end

# Cómo remuestrea vector o matriz
function (wdb::WildDependentBootstrap)(y::AbstractVecOrMat)
    N = MvNormal(zeros(eltype(y), wdb.T), I(wdb.T))
    W = wdb.sigma_sqrt * rand(N)
    ȳ = mean(y; dims=1)
    yres = @. ȳ + (y - ȳ)W
    yres
end


# Función para mapear error cuadrático de WildDependentBootstrap en función de
# l (similar al tamñao de bloque) en un DataFrame 
function map_block_lags_wdb(vmat; methodlabel = "WDB", lrange=1:25, N=100)
    nbb_res = zeros(eltype(vmat), length(lrange), 2)
    T = size(vmat, 1)
    for i in eachindex(lrange)
        l = lrange[i]
        nbb_res[i, :] = mse_cov_autocov(
            vmat, v -> WildDependentBootstrap(T, l*one(eltype(vmat)))(v), 
            N = N, decompose_stations = true)
    end
    # Crear el DataFrame
    nbb_df = DataFrame(nbb_res, [:ErrorCov, :ErrorAutocov])
    nbb_df[!, :Metodo] .= methodlabel
    nbb_df[!, :BloqueL] = lrange
    nbb_df[!, :NumSimulaciones] .= N
    nbb_df
end


# Función para mapear error cuadrático de los métodos de bloque en función de
# tamaño de bloque en un DataFrame 
function map_block_lags(vmat; method = :nooverlap, methodlabel = "NBB", maxlags=25, N=100)
    nbb_res = zeros(eltype(vmat), 25, 2)
    for l in 1:maxlags
        nbb_res[l, :] = mse_cov_autocov(vmat, v -> resample_block(v, l, method), N = N)
    end
    # Crear el DataFrame
    nbb_df = DataFrame(nbb_res, [:ErrorCov, :ErrorAutocov])
    nbb_df[!, :Metodo] .= methodlabel
    nbb_df[!, :BloqueL] = 1:maxlags
    nbb_df[!, :NumSimulaciones] .= N
    nbb_df
end


## Generalized Seasonal Block Bootstrap

# Función para obtener índices de remuestreo
function dbootinds_gsbb(data, d, b)
    T = size(data, 1)
    l = T ÷ b
    ids = Vector{UnitRange{Int}}(undef, 0)
    
    for t in 1:b:T
        R1 = (t - 1) ÷ d
        R2 = (T - b - t) ÷ d

        St = (t - d*R1):d:(t+ d*R2)
        kt = rand(St)
        
        push!(ids, kt:(kt+b-1))
    end
    final_ids = mapreduce(r -> collect(r), vcat, ids)[1:T]
end

# Función para remuestrear
function resample_gsbb(data, d, b)
    @views ids = dbootinds_gsbb(data[:, 1], d, b)
    data[ids, :]
end

function map_block_lags_gsbb(vmat; methodlabel = "GSBB", maxlags=25, N=100, decompose_stations = true)
    nbb_res = zeros(eltype(vmat), 25, 2)
    for l in 1:maxlags
        nbb_res[l, :] = mse_cov_autocov(vmat, v -> resample_gsbb(v, 12, l);  N, decompose_stations)
    end
    # Crear el DataFrame
    nbb_df = DataFrame(nbb_res, [:ErrorCov, :ErrorAutocov])
    nbb_df[!, :Metodo] .= methodlabel
    nbb_df[!, :BloqueL] = 1:maxlags
    nbb_df[!, :NumSimulaciones] .= N
    nbb_df
end


function map_df_resample(vmat, resamplefn; methodlabel, blocklength, N = 100, decompose_stations = true)
    # Obtener resultados de método
    method_res = mse_cov_autocov(vmat, resamplefn; N, decompose_stations)

    # Crear el DataFrame
    method_df = DataFrame(method_res, [:ErrorCov, :ErrorAutocov])
    method_df[!, :Metodo] .= methodlabel
    method_df[!, :BloqueL] .= blocklength
    method_df[!, :NumSimulaciones] .= N
    method_df
end



## Cómputo de resultados de error cuadrático en función de rezagos

varbase = gt00
Nsim = 100

nbb_res = map_block_lags(varbase.v, method=:nooverlap, methodlabel = "NBB", N=Nsim)
cbb_res = map_block_lags(varbase.v, method=:circular, methodlabel = "CBB", N=Nsim)
mbb_res = map_block_lags(varbase.v, method=:moving, methodlabel = "MBB", N=Nsim)
sbb_res = map_block_lags(varbase.v, method=:stationary, methodlabel = "SBB", N=Nsim)
scramble_res = map_df_resample(varbase.v, scramblevar, methodlabel="Método meses", blocklength=1, N=Nsim)
maxentropy_res = map_df_resample(varbase.v, me_resample, methodlabel="Máxima entropía", blocklength=120, N=Nsim)
jc_res = map_df_resample(varbase.v, resample_JC_blocks, methodlabel="Método extensión bloques", blocklength=25, N=Nsim, decompose_stations = false)


wdb_res = map_block_lags_wdb(varbase.v, lrange=1:25, N=Nsim)

# Este funciona mejor quitando las medias de meses y manejar la estacionalidad
# remanente con la metodología de muestreo generalizado estacional
gsbb_res = map_block_lags_gsbb(varbase.v, methodlabel = "SBB", N=Nsim, decompose_stations = false)

## Gráfica de componentes de covarianza
p1 = plot(
    hcat(nbb_res[:, 1], cbb_res[:, 1], mbb_res[:, 1], sbb_res[:, 1], wdb_res[:, 1], gsbb_res[:, 1]), 
    label=["NBB" "CBB" "MBB" "SBB" "WDB" "GSBB"])
hline!(scramble_res[:, 1], label="Método selección meses")
hline!(maxentropy_res[:, 1], label="Método máxima entropía")
hline!(jc_res[:, 1], label="Método extensión bloques")
title!("Componentes de covarianza")
# savefig(plotsdir("bootstrap_methods", "cov_components"))


## Gráfica de componentes de autocovarianza
p2 = plot(
    hcat(nbb_res[:, 2], cbb_res[:, 2], mbb_res[:, 2], sbb_res[:, 2], wdb_res[:, 2], gsbb_res[:, 2]), 
    label=["NBB" "CBB" "MBB" "SBB" "WDB" "GSBB"])
hline!(scramble_res[:, 2], label="Método selección meses")
hline!(maxentropy_res[:, 2], label="Método máxima entropía")
hline!(jc_res[:, 2], label="Método extensión bloques")
title!("Componentes de autocovarianza")
# savefig(plotsdir("bootstrap_methods", "autocov_components"))



## Gráficas juntas 

plot(p1, p2, size=(800, 600), layout=(1, 2))
# savefig(plotsdir("bootstrap_methods", "squared_error_components_10"))


## Compilar resultados en DataFrames

bootdf = [nbb_res; mbb_res; cbb_res; sbb_res; scramble_res; maxentropy_res; jc_res; wdb_res]
bootdf
CSV.write(datadir("bootstrap_methods", "results_methods.csv"), bootdf)

sumdf = combine(sdf -> sdf[argmin(sdf.ErrorAutocov), :], groupby(bootdf, :Metodo))
CSV.write(datadir("bootstrap_methods", "summary_methods.csv"), sumdf)


## Gráficas de barra de los mejores métodos
categ = sumdf.Metodo .* " (L=" .* string.(sumdf.BloqueL) .* ")"
bar(categ, sumdf.ErrorAutocov, label = :none, orientation=:h)
xlabel!("Error de autocovarianza")
savefig(plotsdir("bootstrap_methods", "error_autocov"))

bar(categ, sumdf.ErrorCov, label = :none, orientation=:h)
xlabel!("Error de covarianza")
savefig(plotsdir("bootstrap_methods", "error_cov"))



## Gráficas de series remuestreadas

# Recibe una VarCPIBase y remuestrea la matriz de variaciones intermensuales.
# Posteriormente, toma el gasto básico `x` y genera una animación de la serie
# remuestreada y de la serie original. 
function create_gif(varbase, resamplefn; x = 1, N = 10, path)

    # Matriz de residuos
    month_avg = monthavg(varbase.v)
    resid_vmat = varbase.v - month_avg

    # Remuestrear datos N veces y generar gráfica
    anim = @animate for j in 1:N 
        boot_vmat = resamplefn(resid_vmat) + month_avg
        # boot_vmat = resamplefn(varbase.v)

        # Gráfica de la serie de tiempo
        plot(varbase.fechas, varbase.v[:, x], linewidth=3, label="Original")
        plot!(varbase.fechas, boot_vmat[:, x], label="Remuestreada")
        ylabel!("Variación intermensual")
    end

    gif(anim, path, fps=1.5)

end

## Selección de rezagos por criterio de autocovarianza 

l_nbb = argmin(nbb_res[:, :ErrorAutocov])
l_mbb = argmin(mbb_res[:, :ErrorAutocov])
l_cbb = argmin(cbb_res[:, :ErrorAutocov])
l_sbb = argmin(sbb_res[:, :ErrorAutocov])


## Ilustración métodos de muestreo en base 2000, x = 1 (Arroz)

path = mkpath(plotsdir("bootstrap_methods", "arroz_2000"))
create_gif(gt00, v -> resample_block(v, l_nbb, :nooverlap), 
    path = joinpath(path, "nbb_l=$(l_nbb)_resample_00.gif"))

create_gif(gt00, v -> resample_block(v, l_mbb, :moving), 
    path = joinpath(path, "mbb_l=$(l_mbb)_resample_00.gif"))

create_gif(gt00, v -> resample_block(v, l_cbb, :circular), 
    path = joinpath(path, "cbb_l=$(l_cbb)_resample_00.gif"))

create_gif(gt00, v -> resample_block(v, l_sbb, :stationary), 
    path = joinpath(path, "sbb_l=$(l_sbb)_resample_00.gif"))
    
create_gif(gt00, scramblevar, 
    path = joinpath(path, "scramblevar_resample_00.gif"))
        
create_gif(gt00, me_resample, 
    path = joinpath(path, "maxentropy_resample_00.gif"))

 
## Ilustración métodos de muestreo en base 2010, x = 29 (Tomate)
path = mkpath(plotsdir("bootstrap_methods", "tomate_2010"))

create_gif(gt10, v -> resample_block(v, l_nbb, :nooverlap), 
    path = joinpath(path, "nbb_l=$(l_nbb)_resample_10.gif"), 
    x = 29)

create_gif(gt10, v -> resample_block(v, l_mbb, :moving), 
    path = joinpath(path, "mbb_l=$(l_mbb)_resample_10.gif"), 
    x = 29)

create_gif(gt10, v -> resample_block(v, l_cbb, :circular), 
    path = joinpath(path, "cbb_l=$(l_cbb)_resample_10.gif"), 
    x = 29)

create_gif(gt10, v -> resample_block(v, l_sbb, :stationary), 
    path = joinpath(path, "sbb_l=$(l_sbb)_resample_10.gif"), 
    x = 29)
    
create_gif(gt10, scramblevar, 
    path = joinpath(path, "scramblevar_resample_10.gif"), 
    x = 29)
        
create_gif(gt10, me_resample, 
    path = joinpath(path, "maxentropy_resample_10.gif"), 
    x = 29)

## Completar gráficas del procedimiento de selección de bloque automático de Politis y White
# Utilizar este código para mostrar una gráfica de barras con el largo óptimo por serie de cada base del IPC  
# function temperature_heatmap(x, T)
# 	p = heatmap(x, [0.], collect(T'), 
# 			   clims=(-1., 1.), cbar=false, xticks=nothing, yticks=nothing)
# 	return p
# end