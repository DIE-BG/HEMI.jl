using InflationEvalTools
using InflationFunctions
using CPIDataBase.TestHelpers
using Test

@testset "InflationEvalTools.jl" begin

    # Definición de métodos 
    @test isdefined(InflationEvalTools, :pargentrayinfl)
    @test isdefined(InflationEvalTools, :gentrayinfl)

    # Se exportan funciones de tendencia 
    @test @isdefined TrendAnalytical
    @test @isdefined TrendRandomWalk
    @test @isdefined TrendIdentity
    @test @isdefined TrendExponential
    
    # Se exportan funciones para parámetros 
    param_functions = (ParamTotalCPIRebase, ParamTotalCPI, ParamWeightedMean)
    @test @isdefined InflationParameter
    for param_fn in param_functions
        @test @isdefined param_fn
    end
end


# Pruebas de métodos para Stationary Block Bootstrap
@testset "Remuestreo con SBB" begin include("resample_SBB.jl") end


# Pruebas sobre funciones de tendencia 
@testset "Funciones de tendencia" begin
    
    # Crear un CountryStructure de ceros para pruebas
    cst = getzerocountryst()
    
    trend_functions = (
        TrendRandomWalk(), 
        TrendAnalytical(cst, t -> 1 + 0.5sin(2π*t/12), "Tendencia sinusoidal"), 
        TrendIdentity(), 
        TrendExponential(cst))

        LIM_FACTOR = 3

        for trendfn in trend_functions

        @show trendfn

        # Por el momento, todas las funciones, excepto TrendIdentity, tienen el
        # campo trend para guardar los valores de tendencia 
        if hasproperty(trendfn, :trend)
            # Revisar que todos los factores de tendencia estén entre 0 y LIM_FACTOR
            @test all(0 .< trendfn.trend .< LIM_FACTOR)
        end

        # Revisar la operación sobre CountryStructure
        trended_cst = trendfn(cst)

        # Revisar que en cada base la aplicación de tendencia sea cero (pues el
        # CountryStructure tiene variaciones intermensuales iguales a cero) y que se
        # esté alojando los resultados en nueva memoria
        for b in 1:length(cst.base)
            @test cst[b].v == trended_cst[b].v

            if trendfn isa TrendIdentity
                @test (cst[b].v === trended_cst[b].v)
            else 
                @test !(cst[b].v === trended_cst[b].v)
            end
        end
    
    end

end