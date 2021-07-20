# resample.jl - Estructura general para aplicar funciones de remuestreo a tipos
# CountryStructure y VarCPIBase

"""
    abstract type ResampleFunction <: Function end
Tipo abstracto para funciones de remuestreo. Cada función debe extender como 
mínimo el método
- `resamplefn(vmat::AbstractMatrix, rng)::Matrix` 
para remuestrear un CountryStructure con las funciones definidas arriba. 

Opcionalmente, si se desea modificar el comportamiento específico de cada
función de remuestreo, se deben extender los siguientes métodos: 
- `function (resamplefn::ResampleFunction)(cs::CountryStructure, rng = Random.GLOBAL_RNG)`
- `function (resamplefn::ResampleFunction)(base::VarCPIBase, rng = Random.GLOBAL_RNG)`
"""
abstract type ResampleFunction <: Function end


## Métodos de remuestreo para CountryStructure y VarCPIBase

"""
    function (resamplefn::ResampleFunction)(cs::CountryStructure, rng = Random.GLOBAL_RNG)
Define el comportamiento general de función de remuestreo sobre CountryStructure. 
Se remuestrea cada una de las bases del campo `base` utilizando el método para objetos `VarCPIBase`
y se devuelve un nuevo `CountryStructure`.
"""
function (resamplefn::ResampleFunction)(cs::CountryStructure, rng = Random.GLOBAL_RNG)
    
    # Obtener bases remuestreadas, esto requiere definir un método para manejar
    # objetos de tipo VarCPIBase
    base_boot = map(b -> resamplefn(b, rng), cs.base)

    # Devolver nuevo CountryStructure con 
    typeof(cs)(base_boot)
end


"""
    function (resamplefn::ResampleFunction)(base::VarCPIBase, rng = Random.GLOBAL_RNG)
Define el comportamiento general de función de remuestreo sobre `VarCPIBase`. 
Este método requiere una implementación específica del método sobre el par (`AbstractMatrix`, rng). 
Considera que el método de remuestreo podría extender los períodos de la serie de tiempo y 
ajusta las fechas apropiadamente.
"""
function (resamplefn::ResampleFunction)(base::VarCPIBase, rng = Random.GLOBAL_RNG)

    # Obtener la matriz remuestreada, requiere definir el método para manejar
    # matrices
    v_boot = resamplefn(base.v, rng)

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



"""
    get_param_function(::ResampleFunction)

Cada función de remuestreo debe realizar la implementación de una función para
obtener un `CountryStructure` con objetos `VarCPIBase` que contengan las
variaciones intermensuales promedio (o paramétricas) que permitan construir la
trayectoria paramétrica de inflación de acuerdo con el método de remuestreo dado
en `ResampleFunction`.

Esta función devuelve la función de obtención de datos paramétricos. 

## Ejemplo 
```julia
# Obtener la función de remuestreo 
resamplefn = ResampleSBB(36)
...

# Obtener su función para obtener los datos paramétricos 
paramdatafn = get_param_function(resamplefn)
# Obtener CountryStructure de datos paramétricos 
paramdata = paramdatafn(gtdata)
```

Ver también: [`param_sbb`](@ref)
"""
get_param_function(::ResampleFunction) = 
    error("Se debe especificar una función para obtener el parámetro de esta función de remuestreo")


"""
    method_name(resamplefn::ResampleFunction)
Función para obtener el nombre del método de remuestreo.
"""
method_name(::ResampleFunction) = error("Se debe redefinir el nombre del método de remuestreo")

"""
    method_tag(resamplefn::ResampleFunction)
Función para obtener una etiqueta del método de remuestreo.
"""
method_tag(resamplefn::ResampleFunction) = string(nameof(resamplefn))

