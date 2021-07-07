using CPIDataBase
using CPIDataBase.TestHelpers
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

    # Probar con bases del IPC con variaciones intermensuales iguales a cero.
    # Estas pruebas ayudan a verificar que la función de inflación se pueda
    # llamar sobre los tipos correctos 
   
    zero_base = getzerobase()
    m_traj_infl = simplefn(zero_base)
    # Probamos que el resumen intermensual sea igual a cero
    @test all(m_traj_infl .≈ 0)

    # Obtenemos un UniformCountryStructure con dos bases y todas las variaciones
    # intermensuales iguales a cero
    zero_cst = getzerocountryst()
    traj_infl = simplefn(zero_cst)
    
    # Probamos que la trayectoria de inflación sea más larga que el resumen
    # intermensual de una sola base 
    @test length(traj_infl) > length(m_traj_infl)

    # Probamos que la trayectoria de inflación sea igual a cero 
    @test all(traj_infl .≈ 0)
end