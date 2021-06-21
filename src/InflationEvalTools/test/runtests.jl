using InflationEvalTools
using Test

@testset "InflationEvalTools.jl" begin
    # Write your tests here.
end

# Pruebas de métodos para Stationary Block Bootstrap
@testset "Remuestreo con SBB" begin include("resample_SBB.jl") end