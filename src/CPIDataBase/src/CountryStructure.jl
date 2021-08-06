# countrystructure.jl - Definición de tipos contenedores para bases de datos de
# variaciones intermensuales del IPC VarCPIBase definidas en cpibase.jl

import Base: show, summary, convert, getindex, eltype


"""
    CountryStructure{N, T <: AbstractFloat}

Tipo abstracto que representa el conjunto de bases del IPC de un país.
"""
abstract type CountryStructure{N, T <: AbstractFloat} end


"""
    UniformCountryStructure{N, T, B} <: CountryStructure{N, T}

Estructura que representa el conjunto de bases del IPC de un país, 
posee el campo `base`, que es una tupla de la estructura `VarCPIBase`. Todas
las bases deben tener el mismo tipo de índice base.
"""
struct UniformCountryStructure{N, T, B} <: CountryStructure{N, T}
    base::NTuple{N, VarCPIBase{T, B}} 
end


# Este tipo se puede utilizar con datos cuyos primeros índices no sean todos 100
"""
    MixedCountryStructure{N, T} <: CountryStructure{N, T}

Estructura que representa el conjunto de bases del IPC de un país, 
posee el campo `base`, que es una tupla de la estructura `VarCPIBase`, cada una 
con su propio tipo de índices base B. Este tipo es una colección de un tipo abstracto.
"""
struct MixedCountryStructure{N, T} <: CountryStructure{N, T}
    base::NTuple{N, VarCPIBase{T, B} where B} 
end


# Anotar también como VarCPIBase...
UniformCountryStructure(bases::Vararg{VarCPIBase{T, B}, N}) where {N, T, B} = UniformCountryStructure{N, T, B}(bases)
MixedCountryStructure(bases::Vararg{VarCPIBase}) = MixedCountryStructure(bases)

# Resumen y método para mostrar 

function summary(io::IO, cst::CountryStructure)
    datestart, dateend = _formatdate.((first(cst.base).dates[begin], last(cst.base).dates[end]))
    print(io, typeof(cst), ": ", datestart, "-", dateend)
end

function show(io::IO, cst::CountryStructure)
    l = length(cst.base)
    println(io, typeof(cst), " con ", l, " bases")
    for base in cst.base
        println(io, "|─> ", sprint(show, base))
    end
end


# Conversión entre tipos de datos flotantes

# Este método crea una copia a través de los métodos de conversión de bases
function convert(::Type{T}, cst::CountryStructure) where {T <: AbstractFloat}
    # Convert each base to type T
    conv_b = convert.(T, cst.base)
    getunionalltype(cst)(conv_b)
end


# Funciones de acceso a bases del IPC

"""
    getindex(cst::CountryStructure, i::Int)

Devuelve la base número `i` de un contenedor `CountryStructure`.
"""
getindex(cst::CountryStructure, i::Int) = cst.base[i]

# Función de ayuda para obtener los índices que corresponden a una fecha
# específica de una base
function _base_index(cst, date, retfirst=true)
    for (b, base) in enumerate(cst.base)
        dates = base.dates
        dateindex = findfirst(dates .== date)
        if !isnothing(dateindex)
            return b, dateindex
        end
    end
    # return first or last
    if retfirst
        1, 1
    else
        length(cst.base), size(cst.base[end].v, 1)
    end
end


"""
    getindex(cst::CountryStructure, startdate::Date, finaldate::Date)

Devuelve una copia del `CountryStructure` con las bases modificadas para tener
observaciones entre las fechas indicada por `startdate` y `finaldate`.
"""
function getindex(cst::CountryStructure, startdate::Date, finaldate::Date)

    # Obtener base y fila de inicio
    start_base, start_index = _base_index(cst, startdate, true)
    final_base, final_index = _base_index(cst, finaldate, false)

    bases = deepcopy(cst.base[start_base:final_base])
    if start_base == final_base
        # copy same base and slice
        @debug "Fechas en la misma base"
        # @info bases[1]
        onlybase = bases[1]
        newbase = VarCPIBase(
            onlybase.v[start_index:final_index, :], 
            copy(onlybase.w), onlybase.dates[start_index:final_index], copy(onlybase.baseindex))
        
        return getunionalltype(cst)(newbase)
    else 
        # different bases
        @debug "Fechas en diferentes bases"
        firstbase = first(bases)
        lastbase = last(bases)
        newstart = VarCPIBase(
            firstbase.v[start_index:end, :], 
            copy(firstbase.w), firstbase.dates[start_index:end], copy(firstbase.baseindex))
        newfinal = VarCPIBase(
            lastbase.v[begin:final_index, :], 
            copy(lastbase.w), lastbase.dates[begin:final_index], copy(lastbase.baseindex))
        
        if final_base - start_base > 1
            # more than one base
            @debug "Más de dos bases"
            newbases = (newstart, bases[start_base+1:final_base-1], newfinal)
        else
            # only two bases
            @debug "Dos bases"
            newbases = (newstart, newfinal)
            return getunionalltype(cst)(newbases)
        end
    end

end


"""
    getindex(cst::CountryStructure, finaldate::Date)

Devuelve una copia del `CountryStructure` hasta la fecha indicada por `finaldate`.
"""
function getindex(cst::CountryStructure, finaldate::Date)
    startdate = cst.base[1].dates[1]
    getindex(cst, startdate, finaldate)
end



# Métodos getunionalltype: estos sirven para obtener el tipo concreto de un CountryStructure y poder así construir nuevos objetos de forma genérica. 

"""
    getunionalltype(::UniformCountryStructure)

Devuelve el tipo `UniformCountryStructure`. Utilizado al llamar
`getunionalltype` sobre un `CountryStructure` para obtener el tipo concreto
`UnionAll`. 
"""
getunionalltype(::UniformCountryStructure) = UniformCountryStructure


"""
    getunionalltype(::MixedCountryStructure)

Devuelve el tipo `MixedCountryStructure`. Utilizado al llamar `getunionalltype`
sobre un `CountryStructure` para obtener el tipo concreto `UnionAll`.
"""
getunionalltype(::MixedCountryStructure) = MixedCountryStructure


## Utilidades

"""
    eltype(::CountryStructure{N, T})

Tipo de dato de punto flotante del contenedor de la estructura de país
`CountryStructure`.
"""
eltype(::CountryStructure{N, T}) where {N,T} = T 


"""
    periods(cst::CountryStructure)

Computa el número de períodos (meses) en las bases de variaciones intermensuales
de la estructura de país. 
"""
periods(cst::CountryStructure) = sum(size(b.v, 1) for b in cst.base)


"""
    infl_periods(cst::CountryStructure)

Computa el número de períodos de inflación de la estructura de país. Corresponde
al número de observaciones intermensuales menos las primeras 11 observaciones de
la primera base del IPC.
"""
infl_periods(cst::CountryStructure) = periods(cst) - 11


"""
    infl_periods(cst::CountryStructure)

Fechas correspondientes a la trayectorias de inflación computadas a partir un
`CountryStructure`.
"""
infl_dates(cst::CountryStructure) = 
    first(cst.base).dates[12]:Month(1):last(cst.base).dates[end]