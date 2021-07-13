# stationary_block_bootstrap.jl - Funciones para remuestrear objetos VarCPIBase

# Una idea para mejorar la eficiencia de esta función de remuestreo podría ser
# computar una sola vez la matriz de promedios mensuales y almacenarla en el
# struct StationaryBlockBootstrap para ser aplicada en tiempo de simulación.


# Definición de la función de remuestreo de SBB
struct StationaryBlockBootstrap <: ResampleFunction
    expected_l::Int
    geom_dist::Geometric

    function StationaryBlockBootstrap(expected_l::Int)
        # Construir la distribución geométrica con esperanza expected_l
        g = Geometric(1 / expected_l)
        new(expected_l, g)
    end
end

# Acortar el nombre de la función de remuestreo
const ResampleSBB = StationaryBlockBootstrap

# Definir cuál es la función para obtener bases paramétricas 
get_param_function(::ResampleSBB) = param_sbb

# Definir el nombre y la etiqueta del método de remuestreo 
method_name(resamplefn::ResampleSBB) = "Block bootstrap estacionario con bloque esperado " * string(resamplefn.expected_l) 
method_tag(resamplefn::ResampleSBB) = string(nameof(resamplefn)) * "-" * string(resamplefn.expected_l)

# Definir cómo remuestrear matrices con las series de tiempo en las columnas
function (resample_sbb_fn::ResampleSBB)(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG)
    
    # Obtener índices de remuestreo 
    T = size(vmat, 1)
    inds = sbb_inds(resample_sbb_fn, T, rng)

    # Reordenar las filas para generar el muestreo sobre la matriz de residuos,
    # obtenida respecto a los promedios de cada mes 
    avgmat = monthavg(vmat)
    residmat = vmat - avgmat
    avgmat + residmat[inds, :]

    # vmat[inds, :]
end

# Método para obtener índices de remuestreo 
(resample_sbb_fn::ResampleSBB)(T::Int, rng = Random.GLOBAL_RNG) = 
    sbb_inds(resample_sbb_fn, T, rng)


# Función de remuestreo de índices para una serie de tiempo de largo T
# Adaptado de:  
# https://github.com/colintbowers/DependentBootstrap.jl/blob/9ff843a09fde9f83983f5af1d863ca65e21fbbec/src/bootinds.jl#L24-L40
function sbb_inds(resample_sbb_fn::ResampleSBB, T::Int, rng = Random.GLOBAL_RNG)
    # IID Bootstrap
    resample_sbb_fn.expected_l <= 1 && return rand(rng, 1:T, T)
    
    # Stationary Block Bootstrap 
    inds = Vector{Int}(undef, T)
    geom_dist = resample_sbb_fn.geom_dist
    
    (c, geodraw) = (1, 1)
    for n = 1:T
        # Empezar un nuevo bloque 
        if c == geodraw 
            inds[n] = rand(rng, 1:T)
            geodraw = rand(rng, geom_dist) + 1
            c = 1
        else 
            # Siguiente observación en el bloque existente 
            inds[n-1] == T ? (inds[n] = 1) : (inds[n] = inds[n-1] + 1)
            c += 1
        end
    end
    return inds
end

# Obtener residuos de las variaciones intermensuales promedio
function monthavg(vmat)
    avgmat = similar(vmat)
    for i in 1:12
        avgmat[i:12:end, :] .= mean(vmat[i:12:end, :], dims=1)
    end
    return avgmat
end