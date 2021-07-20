# ResampleGSBB.jl - Funciones para remuestrear series de tiempo con la metodología de Generalized Seasonal Block Bootstrap (GSBB). 

# Esta implementación permite utilizar cualquier tamaño de bloque y mantiene la cantidad de observaciones de las series de tiempo. 

Base.@kwdef struct ResampleGSBB <: ResampleFunction
    blocklength::Int = 25
    seasonality::Int = 12
end

# Constructor con estacionalidad mensual por defecto 
ResampleGSBB(blocklength::Int) = ResampleGSBB(blocklength, 12)


# Función para obtener datos paramétricos. A diferencia de la implementación de
# SBB, se implementan métodos adicionales para resamplefn que reciben en el
# segundo argumento el tipo Val{:inverse}() para que el sistema de despacho se
# encargue de manejar la obtención de los datos paramétricos con la misma
# función resamplefn, ya que se requieren los datos del tamaño de bloque y de la
# estacionalidad.
get_param_function(resamplefn::ResampleGSBB) = cs::CountryStructure -> resamplefn(cs, Val(:inverse))

# Definir el nombre y la etiqueta del método de remuestreo 
method_name(resamplefn::ResampleGSBB) = "Block bootstrap estacional con bloque de tamaño " * string(resamplefn.blocklength) 
method_tag(resamplefn::ResampleGSBB) = string(nameof(resamplefn)) * "-" * string(resamplefn.blocklength)


# Definición del procedimiento de remuestreo para matrices con las series de
# tiempo en las columnas. Se remuestrea la matriz `vmat`, generando
# `numobs` nuevas observaciones de remuestreo en cada serie de tiempo. 
function (resamplefn::ResampleGSBB)(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG)
    # Obtener índices de remuestreo 
    numobs = size(vmat, 1)
    inds = resamplefn(numobs, rng)

    # Obtener las series de tiempo remuestreadas
    resamplemat = vmat[inds, :]
    resamplemat
end


# Función para obtener índices de remuestreo de GSBB. 
# Ver algoritmo en Dudek, Leśkow, Paparoditis y Politis (2013)
function (resamplefn::ResampleGSBB)(numobs::Int, rng = Random.GLOBAL_RNG)
    # Parámetros del algoritmo
    T = numobs
    b = resamplefn.blocklength
    d = resamplefn.seasonality

    # Número de bloques a obtener
    l = T ÷ b
    ids = Vector{UnitRange{Int}}(undef, 0)

    for t in 1:b:l*b+1
        R1 = (t - 1) ÷ d
        R2 = (T - b - t) ÷ d

        # Obtener conjunto de índices posibles para observación t y muestrear
        # iid uno de estos
        St = (t - d*R1):d:(t + d*R2)
        kt = rand(rng, St)
        
        push!(ids, kt:(kt + b - 1))
    end
    # Obtener los índices de remuestreo 
    resample_ids = mapreduce(r -> collect(r), vcat, ids)[1:T]
    resample_ids
end


# Función para obtener rangos de índices de remuestreo para cómputo de datos
# paramétricos 
function (resamplefn::ResampleGSBB)(numobs::Int, ::Val{:inverse})
    # Parámetros del algoritmo
    T = numobs
    b = resamplefn.blocklength
    d = resamplefn.seasonality

    # Número de bloques a obtener
    l = T ÷ b
    ids = Vector{Vector{UnitRange{Int}}}(undef, 0)
    positions = 1:b:l*b+1
    for t in positions
        R1 = (t - 1) ÷ d
        R2 = (T - b - t) ÷ d

        # Obtener conjunto de índices posibles para observación t y muestrear
        # iid uno de estos
        St = (t - d*R1):d:(t + d*R2)

        # Guardar la lista de índices posibles 
        if t == last(positions)
            last_block_size = T - t + 1
            push!(ids, [kt:(kt + last_block_size - 1) for kt in St])
        else
            push!(ids, [kt:kt + b - 1 for kt in St])
        end
    end

    ids
end


# Función para obtener VarCPIBase paramétrico 
function (resamplefn::ResampleGSBB)(base::VarCPIBase, ::Val{:inverse})

    # Obtener listas de índices posibles para los bloques 
    numobs = periods(base)
    ids = resamplefn(numobs, Val(:inverse))

    # Matriz de valores paramétricos (promedios)
    vpob = similar(base.v)
    b = resamplefn.blocklength

    # Obtener los promedios d elos bloques posibles
    for p in 1:length(ids)
        # Obtener matrices en los índices correspondientes de cada bloque 
        block_mats = map(range_ -> base.v[range_, :], ids[p])
        # Obtener promedios de la lista de índices 
        vpob[(b*(p-1) + 1):clamp(b*p, 1:numobs), :] = mean(block_mats)
    end

    # Conformar base de variaciones intermensuales promedio
    VarCPIBase(vpob, base.w, base.fechas, base.baseindex)
end

# Función para obtener CountryStructure paramétrico 
function (resamplefn::ResampleGSBB)(cs::CountryStructure, ::Val{:inverse})
    pob_base = map(base -> resamplefn(base, Val(:inverse)), cs.base)
    getunionalltype(cs)(pob_base)
end