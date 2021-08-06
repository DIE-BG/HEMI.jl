# ResampleGSBBMod.jl - Funciones para remuestrear objetos
# VarCPIBase con la metodología de Generalized Seasonal Block Bootstrap. 

# NOTA: se utiliza una variante con largo de bloque = 25 y con 300 observaciones
# de salida. EL método más general descrito en el paper no considera la
# extensión de la serie de tiempo.


# Definición de la función de remuestreo de GSBB
Base.@kwdef struct ResampleGSBBMod <: ResampleFunction
    blocklength::Int = 25
end

# Definir cuál es la función para obtener bases paramétricas 
get_param_function(::ResampleGSBBMod) = param_gsbb_mod

# Definir el nombre y la etiqueta del método de remuestreo 
method_name(resamplefn::ResampleGSBBMod) = "Block bootstrap estacional con bloque de tamaño " * string(resamplefn.blocklength) 
method_tag(resamplefn::ResampleGSBBMod) = string(nameof(resamplefn)) * "-" * string(resamplefn.blocklength)


# Definir cómo remuestrear matrices con las series de tiempo en las columnas
function (resample_gsbb_fn::ResampleGSBBMod)(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG)
    G = size(vmat, 2)
    boot_vmat = Matrix{eltype(vmat)}(undef, 300, G)

    # Índices de muestreo para bloques de 25 meses
    ids = [(12i + j):(12i + j + 24) for i in 0:7, j in 1:12]

    for j in 1:12
        # Muestrear un rango y asignarlo en el bloque de 25 meses
        range_ = rand(rng, view(ids, :, j))
        boot_vmat[(25(j-1) + 1):(25j), :] = vmat[range_, :]
    end

    boot_vmat
end

# Modificar cómo remuestrear objetos CountryStructure para modificar las fechas en las bases remuestreadas
function (resample_gsbb_fn::ResampleGSBBMod)(cs::CountryStructure, rng = Random.GLOBAL_RNG)
    # Obtener bases remuestreadas
    base_boot = map(b -> resample_gsbb_fn(b, rng), cs.base)
        
    # Modificar las fechas de la segunda base
    finalbase = base_boot[2]
    startdate = base_boot[1].dates[end] + Month(1)
    T = periods(finalbase)
    newdates = getdates(startdate, T)
    base10_mod = VarCPIBase(finalbase.v, finalbase.w, newdates, finalbase.baseindex)

    # Devolver nuevamente el CountryStructure
    CPIDataBase.getunionalltype(cs)(base_boot[1], base10_mod)
end