using CPIDataBase
using InflationFunctions
using Test

@testset "InflationFunctions.jl" begin
    # Write your tests here.
end

# Pruebas sobre medidas de inflación. Se debe probar instanciar los tipos y que
# definan sus métodos sobre los objetos de CPIDataBase
@testset "InflationSimpleMean" begin
    # Instanciar un tipo 
    simplefn = InflationSimpleMean() 
    @test simplefn isa InflationSimpleMean

    # Probar que esté definido el método para obtener su nombre 
    @test measure_name(simplefn) isa String
    @test measure_tag(simplefn) isa String

    # Probar con algunos datos de prueba 
    # ...
    # @test simplefn(gtdata) isa Vector
end