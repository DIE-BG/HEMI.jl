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
    
scramblevar!(base::VarCPIBase, rng = Random.GLOBAL_RNG) = scramblevar!(base.v, rng)


"""
    scramblevar(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG)  

Obtiene una copia del `CountryStructure` con remuestreo de ocurrencia por meses
de las variaciones intermensuales de la bases de la estructura de país.
"""
function scramblevar(cs::CountryStructure, rng = Random.GLOBAL_RNG)
    bootsample = deepcopy(cs)
    for base in bootsample.base
        scramblevar!(base, rng)
    end
    typeof(bootsample)(bootsample.base)
end