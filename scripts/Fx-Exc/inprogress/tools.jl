using DrWatson
using DataFrames

@quickactivate "HEMI"

"""
    std(base::VarCPIBase{T, T} where T <: AbstractFloat)

Calcula la desviación estándar de las variaciones interanuales, para cada uno de los gastos básicos en toda su historia. Devuelve un vector con la misma cantidad de elementos que gastos básicos en la base.
"""
function Statistics.std(base::VarCPIBase{T, T} where T <: AbstractFloat)
    Statistics.std(
        base.v |> HEMI.capitalize |> HEMI.varinteran,
        dims = 1
        ) |> vec
end

"""
    sort(f::Function, data::CountryStructure; rev = true)

Devuelve los índices ordenados, para todas la bases en el `CountryStructure`, respecto una medida calculada a partir de las variaciones intermensuales y la función `f`. Por defecto reliza el ordenamiento de menor a mayor.

la función `f` debe estar definida para operar sobre un objeto de tipo `VarCPIBase{T, T} where T <: AbstractFloat`, y debe devolver un vector con la misma cantidad de elementos que gastos básicos en la base.
"""
function Base.sort(f::Function, data::CountryStructure; rev = true)
    map(data.base) do base
        df = DataFrames.DataFrame(
            num = 1:length(base.w) |> collect,
            measure = f(base)
        )
        df = Base.sort(df, "measure", rev=rev)
        df.num
    end
end


"""
Evaluación por base. 
* vector de orden
* limite de orden
* VarCPIBase

"""

"""
Metodo para pasar vector de orden y límite para exclusión.
"""
function HEMI.InflationFixedExclusionCPI(
    order_vec::Vector{T} where T <: Int, 
    limit::Int
)
HEMI.InflationFixedExclusionCPI(order_vec[1:limit])    
end

"""
Función que recibe los vectores ordenados de los gastos básicos, así como sus límites de exclusión.
"""
function HEMI.InflationFixedExclusionCPI(
    order_vec::NTuple{N, Vector{<:Int}}, 
    limits::Vector{<:Int}
) where {N}
    v = Vector{Vector{<:Int}}(undef, length(order_vec))
    for i in 1:length(order_vec)
    v[i] = order_vec[i][1:limits[i]]
    end
    InflationFixedExclusionCPI(v...)
end


optim_variants = Dict(
    :inflfn => InflationFixedExclusionCPI,
    :resamplefn => ResampleSBB(36), 
    :trendfn => TrendRandomWalk(),
    :paramfn => InflationTotalRebaseCPI(60),
    :nsim => 10_000,
    :traindate => Date(2018, 12),
    :evalperiods => (CompletePeriod(),) 
)

function eval_ExFx(
    base::VarCPIBase,
    config::Dict{Symbol, Any},
    metric::Symbol,
    order_vec::Vector{<:Int},
    limit::Int
)
    config[:inflfn] = config[:inflfn](order_vec, limit)
    base = HEMI.UniformCountryStructure((base, ))
    metrics, ~ = HEMI.evalsim(base, HEMI.dict_config(config)) 
    metrics[metric]
end

eval_ExFx(gt00, optim_variants, :mse, [1,2,3,4], 3)