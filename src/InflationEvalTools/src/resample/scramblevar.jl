# scramblevar.jl - Functions to resample VarCPIBase objects

# Esta es la mejor versión in-place
# 230.600 μs (0 allocations: 0 bytes) con Float64
# 222.000 μs (0 allocations: 0 bytes) con Float32
"""
    scramblevar!(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG) 

Samples in-place every column of matrix `vmat` by months.
"""
function scramblevar!(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG) 
    for i in 1:12
        # fill every column with random values from the same periods (t and t+12)
        for j in 1:size(vmat, 2)
            @views rand!(rng, vmat[i:12:end, j], vmat[i:12:end, j])
        end
    end
end


"""
    scramblevar(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG)  

Copy and scramble every column of matrix `vmat` by months.
"""
function scramblevar(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG) 
    scrambled_mat = copy(vmat)
    scramblevar!(scrambled_mat, rng)
    scrambled_mat
end


## Remuestreo de objetos de CPIDataBase
# Se define una ResampleFunction para implementar interfaz a VarCPIBase y CountryStructure

# Definición de la función de remuestreo por ocurrencia de meses
"""
    struct ScrambleVarMonths <: ResampleFunction end
Define una función de remuestreo para remuestrear las series de tiempo por los
mismos meses de ocurrencia. El muestreo se realiza de manera independiente para 
serie de tiempo en las columnas de una matriz. 
"""
struct ScrambleVarMonths <: ResampleFunction end

# Nombre estándar para funciones de remuestreo Resample
"""
    ResampleScrambleVarMonths
Alias para [`InflationEvalTools.ScrambleVarMonths`](@ref)
"""
const ResampleScrambleVarMonths = ScrambleVarMonths

# Definir cuál es la función para obtener bases paramétricas 
get_param_function(::ResampleScrambleVarMonths) = param_sbb

"""
    scramblevar(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG)  
Define cómo remuestrear matrices con las series de tiempo en las columnas. Utiliza 
la función interna `scramblevar`.
"""
(resamplefn::ResampleScrambleVarMonths)(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG) = 
    scramblevar(vmat, rng)

