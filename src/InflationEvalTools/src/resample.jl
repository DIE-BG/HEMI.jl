# resample.jl - Estructura general para aplicar funciones de remuestreo a tipos
# CountryStructure y VarCPIBase

# Tipo abstracto para funciones de remuestreo 
abstract type ResampleFunction <: Function end

# Comportamiento general de función de remuestreo sobre CountryStructure
function (resample_fn::ResampleFunction)(cs::CountryStructure, rng = Random.GLOBAL_RNG)
    
    # Obtener bases remuestreadas, esto requiere definir un método para manejar
    # objetos de tipo VarCPIBase
    base_boot = map(b -> resample_fn(b, rng), cs.base)

    # Devolver nuevo CountryStructure con 
    typeof(cs)(base_boot)
end


# Comportamiento general de función de remuestreo sobre VarCPIBase
function (resample_fn::ResampleFunction)(base::VarCPIBase, rng = Random.GLOBAL_RNG)

    # Obtener la matriz remuestreada, requiere definir el método para manejar
    # matrices
    v_boot = resample_fn(base.v, rng)

    # Conformar un nuevo VarCPIBase. Vector de ponderaciones e índices base
    # inalterados. Las fechas permanecen inalteradas si la función de remuestreo
    # no extiende los períodos en la matriz de variaciones intermensuales
    # `base.v` 
    periods = size(v_boot, 1)
    if periods == size(base.v, 1)
        dates = base.fechas
    else
        startdate = base.fechas[1]
        dates = startdate:Month(1):(startdate + Month(periods - 1))
    end

    VarCPIBase(v_boot, base.w, dates, base.baseindex)
end

# Cada función debe extender el método `resample_fn(vmat::AbstractMatrix, rng)::Matrix`
# para aplicar remuestrear un CountryStructure
