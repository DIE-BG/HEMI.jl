using DrWatson
@quickactivate "HEMI"

using Dates, CPIDataBase
using JLD2

@load datadir("guatemala", "gtdata32.jld2") gt00 gt10

const gtdata = UniformCountryStructure(gt00, gt10)

using Statistics

function monthavg(vmat)
    avgmat = similar(vmat)
    for i in 1:12
        avgmat[i:12:end, :] .= mean(vmat[i:12:end, :], dims=1)
    end
    avgmat
end


demean = gt00.v - monthavg(gt00.v)
plot(demean[:,  1])


using DependentBootstrap

res = dbootdata(demean[:, 1], blocklength=12, numresample = 5, bootmethod = :movingblock)

plot(demean[:, 1], linewidth=3)
plot!(vcat)