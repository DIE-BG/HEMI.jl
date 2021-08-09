# ResampleSBB.jl - Funciones para remuestrear series de tiempo con el método de
# remuestreo de block bootstrap estacionario 

# Una idea para mejorar la eficiencia de esta función de remuestreo podría ser
# computar una sola vez la matriz de promedios mensuales y almacenarla en el
# struct StationaryBlockBootstrap para ser aplicada en tiempo de simulación.


# Definición de la función de remuestreo de SBB
struct ResampleSBB <: ResampleFunction
    expected_l::Int
    geom_dist::Geometric

    function ResampleSBB(expected_l::Int)
        # Construir la distribución geométrica con esperanza expected_l
        g = Geometric(1 / expected_l)
        new(expected_l, g)
    end
end

# Definir cuál es la función para obtener los datos paramétricos.  
get_param_function(::ResampleSBB) = param_sbb

# Definir el nombre y la etiqueta del método de remuestreo 
method_name(resamplefn::ResampleSBB) = "Block bootstrap estacionario con bloque esperado " * string(resamplefn.expected_l) 
method_tag(resamplefn::ResampleSBB) = "SBB-" * string(resamplefn.expected_l)

## Comportamiento de la función de remuestreo de Stationary Block Bootstrap

# Definición del procedimiento de remuestreo para matrices con las series de
# tiempo en las columnas. Se remuestrea la matriz `vmat`, generando
# `numobsresample` nuevas observaciones de remuestreo en cada serie de tiempo. 
# Supone que numobsresample >= size(vmat, 1)
function (resample_sbb_fn::ResampleSBB)(vmat::AbstractMatrix, numobsresample::Int, rng = Random.GLOBAL_RNG)

    # Obtener índices de remuestreo 
    numobs = size(vmat, 1)
    inds = sbb_inds(resample_sbb_fn, numobs, numobsresample, rng)

    # Reordenar las filas de la matriz de residuos para generar el remuestreo.

    # Los residuos son obtenidos con respecto a los promedios de cada mes.
    # avgmat = monthavg(vmat, numobsresample)
    # residmat = vmat - (@view avgmat[1:numobs, :])
    # resamplemat = avgmat + (@view residmat[inds, :])
    
    # Los residuos son obtenidos con respecto al promedio histórico de cada gasto básico.
    avgmat = mean(vmat, dims=1)
    residmat = vmat .- avgmat
    resamplemat = avgmat .+ (@view residmat[inds, :])
    
    resamplemat
end

# Método que remuestrea la misma cantidad de observaciones (filas) de `vmat` por defecto.
function (resample_sbb_fn::ResampleSBB)(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG)
    numobsresample = size(vmat, 1)
    resample_sbb_fn(vmat, numobsresample, rng)
end

# Método para obtener índices de remuestreo de una serie de tiempo con largo
# `numobs`. Puede servir para ejemplificar el funcionamiento del método de
# remuestreo de Stationary Block Bootstrap
function (resample_sbb_fn::ResampleSBB)(numobs::Int, numobsresample::Int, rng = Random.GLOBAL_RNG)
    sbb_inds(resample_sbb_fn, numobs, numobsresample, rng)
end


# Función de remuestreo de índices con método de SBB para una serie de tiempo de
# largo `numobs` y que genera `numobsresample` observaciones. Este código fue
# adaptado de la librería DependentBootstrap:  
# https://github.com/colintbowers/DependentBootstrap.jl/blob/9ff843a09fde9f83983f5af1d863ca65e21fbbec/src/bootinds.jl#L24-L40
function sbb_inds(resample_sbb_fn::ResampleSBB, numobs::Int, numobsresample::Int = numobs, rng = Random.GLOBAL_RNG)
    # IID Bootstrap
    resample_sbb_fn.expected_l <= 1 && return rand(rng, 1:numobs, numobsresample)
    
    # Stationary Block Bootstrap 
    inds = Vector{Int}(undef, numobsresample)
    geom_dist = resample_sbb_fn.geom_dist
    
    (c, geodraw) = (1, 1)
    for n = 1:numobsresample
        # Empezar un nuevo bloque 
        if c == geodraw 
            inds[n] = rand(rng, 1:numobs)
            geodraw = rand(rng, geom_dist) + 1
            c = 1
        else 
            # Siguiente observación en el bloque existente 
            inds[n-1] == numobs ? (inds[n] = 1) : (inds[n] = inds[n-1] + 1)
            c += 1
        end
    end
    return inds
end

# Obtener variaciones intermensuales promedio de los mismos meses de ocurrencia.
# Se remuestrean `numobsresample` observaciones de las series de tiempo en las
# columnas de `vmat`. 
function monthavg(vmat, numobsresample = size(vmat, 1))
    # Crear la matriz de promedios 
    cols = size(vmat, 2)
    avgmat = Matrix{eltype(vmat)}(undef, numobsresample, cols)
    
    # Llenar la matriz de promedios con los promedios de cada mes 
    for i in 1:12
        avgmat[i:12:end, :] .= mean(vmat[i:12:end, :], dims=1)
    end
    return avgmat
end