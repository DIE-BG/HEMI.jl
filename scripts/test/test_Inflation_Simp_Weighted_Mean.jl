# #Pruebas de funciones de media simple y media ponderada

#Carga de paquetes
using DrWatson
@quickactivate "HEMI"
using HEMI
using InflationFunctions
using Plots
using Test


@testset "Media simple y media ponderada" begin
# ##MEDIA SIMPLE

simplemeanfn = InflationSimpleMean()
simplemeanfn(gtdata)

# ##MEDIA PONDERADA 

weightedmeanfn = InflationWeightedMean()
a=weightedmeanfn(gt10)
t = weightedmeanfn(gtdata)

fns = [simplemeanfn, weightedmeanfn]
for fn in fns 
    @test measure_name(fn) isa String 
    @test measure_tag(fn) isa String 
    println(measure_name(fn))
end


# ##MEDIA MÓVIL
inflfn = InflationMovingAverage(InflationTotalCPI(), 3)

# Prueba para computar media móvil de función de inflación 
@test inflfn(gtdata) isa Vector{<:AbstractFloat}

all_ma = [InflationMovingAverage(InflationTotalCPI(), i)(gtdata) for i in 1:12] |> 
    x -> hcat(x...)

@test all_ma isa Matrix

#=
plot(infl_dates(gtdata), all_ma,
    # xlims=(Date(2001,12), Date(2005,12)),
    legend=false)
plot!(infl_dates(gtdata), InflationTotalCPI()(gtdata), 
    linewidth=3, color=:black) 
=#
end 