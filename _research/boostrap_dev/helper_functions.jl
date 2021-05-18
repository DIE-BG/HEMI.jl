# helper_functions.jl -- Funciones de ayuda para compilación de resultados de
# metodologías de remuestreo

using LinearAlgebra, Distributions

## Obtener residuos de las variaciones intermensuales promedio
function monthavg(vmat)
    avgmat = similar(vmat)
    for i in 1:12
        avgmat[i:12:end, :] .= mean(vmat[i:12:end, :], dims=1)
    end
    avgmat
end

## Función para obtener desempeño del método de remuestreo 

# Función de remuestreo que computa error cuadrático en autocovarianza y covarianza 
function mse_cov_autocov(vmat, resamplefn; N = 100, 
    decompose_stations=true, max_lag=12, return_sims=false)
    # Valores poblacionales observados, media, Varianza y autocovarianza poblacional
    vmat_cov = cov(vmat)
    vmat_autocov = autocov(vmat, 1:max_lag, demean=true)
    vmat_mean = mean(vmat, dims=1)
    

    # Matriz de residuos
    month_avg = monthavg(vmat)
    resid_vmat = vmat - month_avg

    G = size(vmat, 2)
    res_cov = zeros(eltype(vmat), G, G, N)
    res_autocov = zeros(eltype(vmat), max_lag, G, N)
    res_mean = zeros(eltype(vmat), N, G)

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
        res_autocov[:, :, j] = autocov(boot_vmat, 1:max_lag, demean=true)

        # Media muestral 
        res_mean[j, :] = mean(boot_vmat, dims=1)
    end

    NG = sum(1:G) - G # número de elementos en la matriz triangular inferior
    cov_mask = tril(ones(G, G), -1) # 1's en el triángulo inferior

    mse_cov = sum(((res_cov .- vmat_cov) .* cov_mask) .^ 2) / (NG * N)
    mse_autocov = sum((res_autocov .- vmat_autocov) .^ 2) / (max_lag * G * N)
    mse_mean = sum((res_mean .- vmat_mean) .^ 2) / (N * G)
    mse_var = sum(((res_cov .- vmat_cov) .* I(G)) .^ 2) / (G * N)

    # Opción para obtener matrices de simulación
    return_sims && return res_cov, res_autocov, res_mean, [mse_mean mse_var mse_cov mse_autocov]

    # Resumen de propiedades de la matriz de variaciones intermensuales
    [mse_mean mse_var mse_cov mse_autocov]
    
end


## Función de remuestreo para métodos de bloque de DependentBootstrap
function resample_block(vmat, blocklength, bootmethod)
    first(dbootdata(vmat; blocklength, numresample=1, bootmethod))
end

function resample_block_fn(blocklength, bootmethod)
    fn = vmat -> first(dbootdata(vmat; blocklength, numresample=1, bootmethod))
    fn
end

# Función para mapear error cuadrático de los métodos de bloque en función de
# tamaño de bloque en un DataFrame 
function map_block_lags(vmat; method = :nooverlap, methodlabel = "NBB", maxlags=25, N=100)
    nbb_res = zeros(eltype(vmat), maxlags, 4)
    for l in 1:maxlags
        nbb_res[l, :] = mse_cov_autocov(vmat, v -> resample_block(v, l, method), N = N)
    end
    # Crear el DataFrame
    nbb_df = DataFrame(nbb_res, [:ErrorMedia, :ErrorVar, :ErrorCov, :ErrorAutocov])
    nbb_df[!, :Metodo] .= methodlabel
    nbb_df[!, :BloqueL] = 1:maxlags
    nbb_df[!, :NumSimulaciones] .= N
    nbb_df
end

## Función de remuestreo de MaximumEntropy del paquete Bootstrap
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


## Función de remuestreo con Wild Dependent Bootstrap
# Ver detalles en Shao (2010) 

# kernel de Bartlett
function k_bartlett(x; l=1)
	0 <= abs(x/l) <= 1 && return 1 - abs(x/l)
	0
end

# kernel de Parzen
function k_parzen(x; l=1)
    0 <= abs(x/l) <= 0.5 && return 1 - 6(x/l)^2*(1-abs(x/l)) 
    0.5 < abs(x/l) <= 1 && return 2(1-abs(x/l))^3
    0
end

# Se utiliza un objeto para guardar la matriz sigma_sqrt, que se computa una
# sola vez para cada l y T y se utiliza repetidamente en el remuestreo de la
# serie de tiempo
struct WildDependentBootstrap{U}
    l::U
    T::Int
    sigma_sqrt::Matrix{U}

    # Se guarda la matriz sigma_sqrt, utilizada para generar nuevas secuencias W
    function WildDependentBootstrap(T::Int, l::U, k=k_bartlett) where U <: AbstractFloat
        # Obtener la matriz para muestreo
        sigma = [k((i-j); l) for i in 1:T, j in 1:T]
        sigma_sqrt = sqrt(sigma)
        new{U}(l, T, sigma_sqrt)
    end
end

# Función para remuestrear vectores o matrices (las perturbaciones W se aplican
# a todas las columnas sin volver a muestrear W)
function (wdb::WildDependentBootstrap)(y::AbstractVecOrMat)
    N = MvNormal(zeros(eltype(y), wdb.T), I(wdb.T))
    W = wdb.sigma_sqrt * rand(N)
    ȳ = mean(y; dims=1)
    yres = @. ȳ + (y - ȳ)W
    yres
end


# Función para mapear error cuadrático de WildDependentBootstrap en función de
# l (similar al tamaño de bloque) en un DataFrame 
function map_block_lags_wdb(vmat; methodlabel = "WDB", lrange=1:25, N=100)
    nbb_res = zeros(eltype(vmat), length(lrange), 4)
    T = size(vmat, 1)
    for i in eachindex(lrange)
        l = lrange[i]
        # Función de remuestreo WildDependentBootstrap con parámetro l en el kernel
        resamplefn = v -> WildDependentBootstrap(T, l*one(eltype(vmat)))(v)
        nbb_res[i, :] = mse_cov_autocov(vmat, resamplefn, N = N, decompose_stations = true)
    end

    # Crear el DataFrame de resultados
    nbb_df = DataFrame(nbb_res, [:ErrorMedia, :ErrorVar, :ErrorCov, :ErrorAutocov])
    nbb_df[!, :Metodo] .= methodlabel
    nbb_df[!, :BloqueL] = lrange
    nbb_df[!, :NumSimulaciones] .= N
    nbb_df
end


## Funciones para metodología Generalized Seasonal Block Bootstrap (GSBB)

# Función para obtener índices de remuestreo, ver algoritmo en Dudek, Leśkow,
# Paparoditis y Politis (2013)
function dbootinds_gsbb(data, d, b)
    T = size(data, 1)
    # l = T ÷ b
    ids = Vector{UnitRange{Int}}(undef, 0)
    
    for t in 1:b:T
        R1 = (t - 1) ÷ d
        R2 = (T - b - t) ÷ d

        St = (t - d*R1):d:(t+ d*R2)
        kt = rand(St)
        
        push!(ids, kt:(kt+b-1))
    end
    final_ids = mapreduce(r -> collect(r), vcat, ids)[1:T]
    final_ids
end

# Función para remuestrear matriz de variaciones intermensuales
function resample_gsbb(data, d, b)
    @views ids = dbootinds_gsbb(data[:, 1], d, b)
    data[ids, :]
end

# Función de remuestreo de bloque GSBB que extiende la base del IPC a 300
# observaciones, propuesta del Dr. Castañeda
function resample_gsbb_mod(vmat)
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

function map_block_lags_gsbb(vmat; methodlabel = "GSBB", maxlags=25, N=100, decompose_stations = true)
    nbb_res = zeros(eltype(vmat), maxlags, 4)
    for l in 1:maxlags
        nbb_res[l, :] = mse_cov_autocov(vmat, v -> resample_gsbb(v, 12, l);  N, decompose_stations)
    end
    # Crear el DataFrame
    nbb_df = DataFrame(nbb_res, [:ErrorMedia, :ErrorVar, :ErrorCov, :ErrorAutocov])
    nbb_df[!, :Metodo] .= methodlabel
    nbb_df[!, :BloqueL] = 1:maxlags
    nbb_df[!, :NumSimulaciones] .= N
    nbb_df
end


## Función para mapear resultados de un método no variable en bloques a DataFrame
function map_df_resample(vmat, resamplefn; methodlabel, blocklength, N = 100, decompose_stations = true)
    # Obtener resultados de método
    method_res = mse_cov_autocov(vmat, resamplefn; N, decompose_stations)

    # Crear el DataFrame
    method_df = DataFrame(method_res, [:ErrorMedia, :ErrorVar, :ErrorCov, :ErrorAutocov])
    method_df[!, :Metodo] .= methodlabel
    method_df[!, :BloqueL] .= blocklength
    method_df[!, :NumSimulaciones] .= N
    method_df
end


## Función para animación de remuestreo

# Recibe una VarCPIBase y remuestrea la matriz de variaciones intermensuales.
# Posteriormente, toma el gasto básico `x` y genera una animación de la serie
# remuestreada y de la serie original. 
function create_gif(varbase, resamplefn; x = 1, N = 10, decompose_stations = true, path)

    # Matriz de residuos
    month_avg = monthavg(varbase.v)
    resid_vmat = varbase.v - month_avg

    # Gráfica de la serie de tiempo
    fechas = (resamplefn != resample_gsbb_mod) ? 
        varbase.fechas :                    # fechas originales 
        varbase.fechas[1] .+ Month.(0:299)  # fechas extendidas a 300 obs

    # Remuestrear datos N veces y generar gráfica
    anim = @animate for j in 1:N 
        if decompose_stations
            boot_vmat = resamplefn(resid_vmat) + month_avg
        else
            boot_vmat = resamplefn(varbase.v)
        end
        # boot_vmat = resamplefn(varbase.v)

        plot(varbase.fechas, varbase.v[:, x], linewidth=3, label="Original")
        plot!(fechas, boot_vmat[:, x], label="Remuestreada")
        ylabel!("Variación intermensual")
    end

    gif(anim, path, fps=1.5)

end