# helper_functions.jl -- Funciones de ayuda para compilación de resultados de
# metodologías de remuestreo

using LinearAlgebra, Distributions
using ProgressMeter
using StatsBase
using OnlineStats
using Plots

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
    vmat_autocov = StatsBase.autocov(vmat, 1:max_lag, demean=true)
    vmat_mean = mean(vmat, dims=1)
    

    # Matriz de residuos
    month_avg = monthavg(vmat)
    resid_vmat = vmat - month_avg

    G = size(vmat, 2)

    # Resultados de covarianza, autocovarianza y media actualizados online con
    # OnlineStats
    T = eltype(vmat)
    res_cov =  [Mean(T) for _ in 1:G, _ in 1:G] 
    res_autocov = [Mean(T) for _ in 1:max_lag, _ in 1:G]
    res_mean = [Mean(T) for _ in 1:G]

    # Remuestrear datos N veces y obtener el MSE
    for j in 1:N 
        if decompose_stations
            boot_vmat = resamplefn(resid_vmat) + month_avg
        else
            boot_vmat = resamplefn(vmat)
        end

        # Actualizar online las matrices de covarianza y funciones de
        # autocovarianza de los errores cuadráticos entre las medidas obtenidas
        # con la matriz original variaciones intermensuales de índices de
        # precios y las obtenidas al remuestrear. 
        fit!.(res_cov, (cov(boot_vmat) - vmat_cov) .^ 2)
        
        vmat_autocov_res = StatsBase.autocov(boot_vmat, 1:max_lag, demean=true)
        fit!.(res_autocov, (vmat_autocov_res - vmat_autocov) .^ 2)

        # Media muestral 
        fit!.(res_mean, (mean(boot_vmat, dims=1) - vmat_mean) .^ 2)
    end

    # Número de elementos debajo de la matriz triangular inferior
    NG = sum(1:G) - G 
    # Matriz con 1's en el triángulo inferior
    cov_mask = tril(ones(G, G), -1) 

    # Obtener evaluación de resultados = promedio de los errores cuadráticos
    mse_cov = sum(mean.(res_cov) .* cov_mask) / NG
    mse_autocov = mean(mean.(res_autocov))
    mse_mean = mean(mean.(res_mean))
    mse_var = sum(mean.(res_cov) .* I(G)) / G

    # Opción para obtener matrices de simulación que contienen los promedios del
    # error cuadrático de la media y varianza de cada gasto básico y en el caso
    # de la covarianza, el error cuadrático en la covarianza entre gastos
    # básicos. 
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
function map_block_lags(vmat; method = :nooverlap, methodlabel = "NBB", 
    decompose_stations=true, maxlags=25, N=100)

    nbb_res = zeros(eltype(vmat), maxlags, 4)
    @showprogress for l in 1:maxlags
        nbb_res[l, :] = mse_cov_autocov(vmat, v -> resample_block(v, l, method), 
            N = N, decompose_stations = decompose_stations)
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


## Función de remuestreo de SBB con extensión de períodos
function resample_block_mod(vmat, blocklength, method=:stationary)
    # Matriz de residuos
    month_avg = monthavg(vmat)
    resid_vmat = vmat - month_avg

    resample_res = first(dbootdata(resid_vmat; 
        blocklength, # tamaño de bloque
        numresample=1, 
        bootmethod=method, 
        numobsperresample = 300))

    final_resample = resample_res + repeat(view(resid_vmat, 1:12, :), 25, 1)
    final_resample
end


## Función de remuestreo con SBB estacional (SSBB - Stationary Seasonal Block Bootstrap)

# Función de remuestreo respetando estacionalidad en bloques disponibles
function ssbb_sets(t, b, T, d=12)
    # Límites inferior y superior para los índices, considerando el largo de
    # bloque b, desde la posición t, en una serie de tiempo de largo T con
    # estacionalidad d
    R1 = (t - 1) ÷ d
    R2 = (T - b - t) ÷ d
    # @info R1, R2

    # Conjunto de rangos disponibles de largo b en la observación t
    St = (t - d*R1):d:(t+ d*R2)
    # @info St
    # St |> collect
    
    # Extraer el índice de inicio de bloque
    kt = rand(St)
    # kt = try 
    #     rand(St)
    # catch 
    #     println("St=$St, R1=$R1, R2=$R2, t=$t, b=$b, T=$T")
    #     error("Error en generación de índices")
    # end

    # Devolver el rango de índices para el tamaño de bloque b
    kt:(kt+b-1)
end

# Función de remuestreo respetando estacionalidad en bloques disponibles, pero
# implementando circularidad en el remuestreo del bloque
function ssbb_sets_cb(t, b, T, d=12)
    
    # Obtener estación de t. Si es 0, entonces corresponde a d
    d0 = t % d
    d0 = d0 == 0 ? d : d0

    # Obtener índices iniciales
    start_bag = d0:d:T
    start_index = rand(start_bag)

    range0 = (start_index:(start_index + b - 1)) .% T
    range0[range0 .== 0] .= 120 

    # Devolver el vector de índices para el tamaño de bloque b
    range0
end



function dbootinds_ssbb(T, l, R=T)
    G = l == 1 ? Bernoulli(0) : Geometric(1/l)

    # Vector de índices para remuestreo de tamaño final R
    ids = Vector{Int}(undef, R)
    
    t = 1
    while t <= R
        # Obtener el largo del bloque para la posición t
        lt = rand(G) + 1
        # Condición para el tamaño de bloque aleatorio (b ≤ T - t)
        while lt > 36
            lt = rand(G) + 1
        end
        
        # Obtener índices para asignar al bloque 
        # kt_range = ssbb_sets(t, lt, T)
        idx_range = ssbb_sets(t, lt, T)
        t_last_pos = t + lt - 1
        if t_last_pos > R 
            t_last_pos = R
        end
        block_last_pos = t_last_pos - t + 1
        
        # Asignar los índices obtenidos 
        # ids[t:t_last_pos] .= collect(kt_range[1:block_last_pos])
        ids[t:t_last_pos] .= @view idx_range[1:block_last_pos]

        # Posicionarse en el siguiente t
        t += lt
    end
    
    ids
end

function resample_ssbb(vmat, expected_l)
    T = size(vmat, 1)
    inds = dbootinds_ssbb(T, expected_l, T)
    # Devolver copia remuestreada
    vmat[inds, :]
end


function map_block_lags_ssbb(vmat; methodlabel = "SSBB", 
    decompose_stations=false, maxlags=25, N=100)

    nbb_res = zeros(eltype(vmat), maxlags, 4)
    @showprogress for l in 1:maxlags
        nbb_res[l, :] = mse_cov_autocov(vmat, v -> resample_ssbb(v, l), 
            N = N, decompose_stations = decompose_stations)
    end
    # Crear el DataFrame
    nbb_df = DataFrame(nbb_res, [:ErrorMedia, :ErrorVar, :ErrorCov, :ErrorAutocov])
    nbb_df[!, :Metodo] .= methodlabel
    nbb_df[!, :BloqueL] = 1:maxlags
    nbb_df[!, :NumSimulaciones] .= N
    nbb_df
end



## Función para animación de remuestreo

# Recibe una VarCPIBase y remuestrea la matriz de variaciones intermensuales.
# Posteriormente, toma el gasto básico `x` y genera una animación de la serie
# remuestreada y de la serie original. 
function create_gif(varbase, resamplefn; path, x = 1, N = 10, decompose_stations = true, extend_periods=false)

    # Matriz de residuos
    month_avg = monthavg(varbase.v)
    resid_vmat = varbase.v - month_avg

    # Fechas de acuerdo con el tipo de función de remuestreo, algunas extienden
    # períodos
    fechas = !extend_periods ? 
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


## Funciones para obtener bloque óptimo de Politis y White 2004, 2009

# Función para obtener bloque óptimo del método `bootmethod`
# Se utiliza try catch porque en la base 2010, el gasto básico 230 posee 
# solamente variaciones intermensuales iguales a cero, lo que da un error 
# no controlado en la función BootInput en el análisis del correlograma
function optblock_politis_white(base, bootmethod = :stationary; decompose_stations = true)
    
    vmat = decompose_stations ? base.v - monthavg(base.v) : base.v
    G = size(vmat, 2)
    
    optblock = map(1:G) do j
        try
            bi = BootInput(vmat[:, j], blocklength = 0, 
                bootmethod = bootmethod, numresample=1)
            bi.blocklength
        catch 
            @warn "Error en cómputo de bloque óptimo en gasto $j"
            one(eltype(vmat))
        end
    end
    optblock
end 

# Función para graficar barras de bloques óptimos
function plot_bar_optblock(opt_blocks, label, basetag)
    # Gráfica de barras
    p1 = bar(opt_blocks, label=label, alpha=0.3)
    # Líneas de media y mediana
    hline!([mean(opt_blocks)], label = "Media", 
        color = :blue, linealpha = 0.8, linestyle = :dash, linewidth = 2)
    hline!([median(opt_blocks)], label = "Mediana", 
        color = :red, linealpha = 0.7, linestyle = :dash, linewidth = 2)
    # Percentiles
    hline!(quantile(opt_blocks, [0.9, 0.95, 0.99]), 
        label = "Percentiles 90%, 95% y 99%", 
        linealpha = 0.5, linestyle = :dash, linewidth = 2)
    title!("Bloque óptimo $label base $basetag")

    p1
end