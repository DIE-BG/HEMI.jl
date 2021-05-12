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
function mse_cov_autocov(vmat, resamplefn; N = 100)
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
        boot_vmat = resamplefn(resid_vmat) + month_avg
        # boot_vmat = resamplefn(vmat)

        res_cov[:, :, j] = cov(boot_vmat)
        res_autocov[:, :, j] = autocov(boot_vmat, 1:12, demean=false)

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

# Función para mapear error cuadrático en función de tamaño de bloque en un
# DataFrame
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

function map_df_resample(vmat, resamplefn; methodlabel, N)
    # Obtener resultados de método
    method_res = mse_cov_autocov(vmat, resamplefn, N = N)

    # Crear el DataFrame
    method_df = DataFrame(method_res, [:ErrorCov, :ErrorAutocov])
    method_df[!, :Metodo] .= methodlabel
    method_df[!, :BloqueL] .= 0
    method_df[!, :NumSimulaciones] .= N
    method_df
end



## Cómputo de resultados de error cuadrático en función de rezagos

nbb_res = map_block_lags(gt00.v, method=:nooverlap, methodlabel = "NBB", N=1000)
cbb_res = map_block_lags(gt00.v, method=:circular, methodlabel = "CBB", N=1000)
mbb_res = map_block_lags(gt00.v, method=:moving, methodlabel = "MBB", N=1000)
sbb_res = map_block_lags(gt00.v, method=:stationary, methodlabel = "SBB", N=1000)
scramble_res = map_df_resample(gt00.v, scramblevar, methodlabel="Método meses", N=1000)
maxentropy_res = map_df_resample(gt00.v, me_resample, methodlabel="Máxima entropía", N=1000)


## Gráfica de componentes de covarianza
plot(
    hcat(nbb_res[:, 1], cbb_res[:, 1], mbb_res[:, 1], sbb_res[:, 1]), 
    label=["Covarianza NBB" "Covarianza CBB" "Covarianza MBB" "Covarianza SBB"])
hline!(scramble_res[:, 1], label="Covarianza método meses")
hline!(maxentropy_res[:, 1], label="Covarianza método máxima entropía")
title!("Componentes de covarianza")
savefig(plotsdir("bootstrap_methods", "cov_components"))


## Gráfica de componentes de autocovarianza
plot(
    hcat(nbb_res[:, 2], cbb_res[:, 2], mbb_res[:, 2], sbb_res[:, 2]), 
    label=["Autocov. NBB" "Autocov. CBB" "Autocov. MBB" "Autocov. SBB"])
hline!(scramble_res[:, 2], label="Autocov. método meses")
hline!(maxentropy_res[:, 2], label="Autocov. método máxima entropía")
title!("Componentes de autocovarianza")
savefig(plotsdir("bootstrap_methods", "autocov_components"))



## Compilar resultados en DataFrames

bootdf = [nbb_res; mbb_res; cbb_res; sbb_res; scramble_res; maxentropy_res]
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

