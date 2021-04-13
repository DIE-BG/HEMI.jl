# resample.jl - Functions to resample VarCPIBase objects

"""
    Resample

Funciones de remuestreo
"""
module Resample
#=
function scramblevar!(vmat::AbstractMatrix) 
    for i in 1:12
        monthvar = @view vmat[i:12:end, :]
        n = size(monthvar, 1)
        for j in 1:size(vmat, 2)
            monthvar[:, j] = rand(monthvar, n)
        end
    end
    othermat
end

function scramblevar(vmat::AbstractMatrix) 
    othermat = similar(vmat)
    for i in 1:12
        monthvar = @view vmat[i:12:end, :]
        monthother = @view othermat[i:12:end, :]
        n = size(monthvar, 1)
        for j in 1:size(vmat, 2)
            monthother[:, j] = rand(monthvar, n)
        end
    end
    othermat
end

function scramblevar2(vmat::AbstractMatrix) 
    othermat = similar(vmat)
    for i in 1:12
        monthvar = @view vmat[i:12:end, :]
        n = size(monthvar, 1)
        
        othermat[i:12:end, :] = reduce(hcat, rand.(eachcol(monthvar), n))
    end
    othermat
end

=#

function scramblevar3!(vmat::AbstractMatrix) 
    for i in 1:12
        monthvar = @view vmat[i:12:end, :]
        n, c = size(monthvar)
        for j in 1:c
            monthvar[:, j] = rand(view(monthvar, :, j), n)
        end
    end
end

# Base 2000
# MATLAB ScrambleVarMatrix: 2.3025 con 1000 veces
# Julia scramblevar3: 361.400 μs (2618 allocations: 429.27 KiB)
# Base 2010
# MATLAB ScrambleVarMatrix: 2.8911 con 1000 veces
# Julia scramblevar3: 414.400 μs (3350 allocations: 551.58 KiB)

function scramblevar3(vmat::AbstractMatrix) 
    othermat = similar(vmat)
    for i in 1:12
        monthvar = @view vmat[i:12:end, :]
        n, c = size(monthvar)
        for j in 1:c
            othermat[i:12:end, j] = rand(view(monthvar, :, j), n)
        end
    end
    othermat
end

function scramblevar3r(rng, vmat::AbstractMatrix) 
    othermat = similar(vmat)
    for i in 1:12
        monthvar = @view vmat[i:12:end, :]
        n, c = size(monthvar)
        for j in 1:c
            othermat[i:12:end, j] = rand(rng, view(monthvar, :, j), n)
        end
    end
    othermat
end

function scramblevar3r!(rng, vmat::AbstractMatrix) 
    for i in 1:12
        monthvar = @view vmat[i:12:end, :]
        n, c = size(monthvar)
        for j in 1:c
            monthvar[:, j] = rand(rng, view(monthvar, :, j), n)
        end
    end
end


function test(a, rng = Random.GLOBAL_RNG)
    rand(rng, a, 5)
end

using Random

# export test

# myrng = MersenneTwister(161803); 

# # Allocating versions
# v00 = copy(gt00.v);

# @btime scramblevar3($v00); 

# @btime scramblevar3r($myrng, $v00); 


# # Inplace versions
# v00 = copy(gt00.v);
# @btime scramblevar3!($v00)

# v00 = copy(gt00.v);
# @btime scramblevar3r!($myrng, $v00)

end