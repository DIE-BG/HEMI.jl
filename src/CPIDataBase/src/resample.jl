# resample.jl - Functions to resample VarCPIBase objects

"""
    Resample

Funciones de remuestreo para ejercicios de simulación.
"""
module Resample

export scramblevar, scramblevar!

using Random

# Este es el mejor que aloja nueva memoria hasta el momento
# 245.700 μs (2 allocations: 204.45 KiB) con Float64
# 226.200 μs (2 allocations: 102.27 KiB) con Float32 (tarda un poquitín menos)
"""
    scramblevar(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG) 

Samples every column of matrix `vmat` by months and returns scrambled copy. 
"""
function scramblevar(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG) 
    othermat = similar(vmat)
    for i in 1:12
        # fill every column with random values from the same periods (t and t+12)
        for j in 1:size(vmat, 2)
            @views rand!(rng, othermat[i:12:end, j], vmat[i:12:end, j])
        end
    end
    othermat
end

# Esta es la mejor versión inplace
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

## Remuestreo de objetos de CPIDataBase
    
import ..CPIDataBase: VarCPIBase, CountryStructure

scramblevar!(base::VarCPIBase, rng = Random.GLOBAL_RNG) = scramblevar!(base.v, rng)

function scramblevar!(cs::CountryStructure, rng = Random.GLOBAL_RNG) 
    for base in cs.base
        scramblevar!(base, rng)
    end
end

end