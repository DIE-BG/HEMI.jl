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

## Pruebas para Inflación de Exclusión Fija de Gastos Básicos
@testset "InflationFixedExclusionCPI" begin
    # Creación de vectores de exclusión de prueba
    exc00 = [10, 100, 200, 218]
    exc10 = [20, 120, 220, 279]
    # Instanciar un tipo 
    simplefn = InflationFixedExclusionCPI(exc00, exc10) 
    @test simplefn isa InflationFixedExclusionCPI

    # Probar que esté definido el método para obtener su nombre 
    @test measure_name(simplefn) isa String
    @test measure_tag(simplefn) isa String

    # Probar con bases del IPC con variaciones intermensuales iguales a cero.
    # Estas pruebas ayudan a verificar que la función de inflación se pueda
    # llamar sobre los tipos correctos 
   
    zero_base = getzerobase()

    m_traj_infl = simplefn(zero_base,1)
    # Probamos que el resumen intermensual sea igual a cero
    @test all(isapprox.(m_traj_infl, 0; atol = 0.0001))

    # Obtenemos un UniformCountryStructure con dos bases y todas las variaciones
    # intermensuales iguales a cero
    zero_cst = getzerocountryst()
    traj_infl = simplefn(zero_cst)

    # Probamos que la trayectoria de inflación sea más larga que el resumen
    # intermensual de una sola base 
    @test length(traj_infl) > length(m_traj_infl)

    @test all(isapprox.(traj_infl, 0; atol = 0.0001))

end

# Función de inflación por percentiles equiponderados
# prueba con percentil 70
@testset "InflationPercentileEq" begin
    # Instanciar un tipo 
    percEqfn = InflationPercentileEq(70) 
    @test percEqfn isa InflationPercentileEq

    # Probar que esté definido el método para obtener su nombre 
    @test measure_name(percEqfn) isa String
    @test measure_tag(percEqfn) isa String

    # Probar con bases del IPC con variaciones intermensuales iguales a cero.
    # Estas pruebas ayudan a verificar que la función de inflación se pueda
    # llamar sobre los tipos correctos 
   
    zero_base = getzerobase()
    m_traj_infl = percEqfn(zero_base)
    # Probamos que el resumen intermensual sea igual a cero
    @test all(m_traj_infl .≈ 0)

    # Obtenemos un UniformCountryStructure con dos bases y todas las variaciones
    # intermensuales iguales a cero
    zero_cst = getzerocountryst()
    traj_infl = percEqfn(zero_cst)
    
    # Probamos que la trayectoria de inflación sea más larga que el resumen
    # intermensual de una sola base 
    @test length(traj_infl) > length(m_traj_infl)

    # Probamos que la trayectoria de inflación sea igual a cero 
    @test all(traj_infl .≈ 0)
end


# Función de inflación por percentiles ponderados
# prueba con percentil 70
@testset "InflationPercentileWeighted" begin
    # Instanciar un tipo 
    percfn = InflationPercentileWeighted(70) 
    @test percfn isa InflationPercentileWeighted

    # Probar que esté definido el método para obtener su nombre 
    @test measure_name(percfn) isa String
    @test measure_tag(percfn) isa String

    # Probar con bases del IPC con variaciones intermensuales iguales a cero.
    # Estas pruebas ayudan a verificar que la función de inflación se pueda
    # llamar sobre los tipos correctos 
   
    zero_base = getzerobase()
    m_traj_infl = percfn(zero_base)
    # Probamos que el resumen intermensual sea igual a cero
    @test all(m_traj_infl .≈ 0)

    # Obtenemos un UniformCountryStructure con dos bases y todas las variaciones
    # intermensuales iguales a cero
    zero_cst = getzerocountryst()
    traj_infl = percfn(zero_cst)
    
    # Probamos que la trayectoria de inflación sea más larga que el resumen
    # intermensual de una sola base 
    @test length(traj_infl) > length(m_traj_infl)

    # Probamos que la trayectoria de inflación sea igual a cero 
    @test all(traj_infl .≈ 0)
end

@testset "InflationDynamicExclusion" begin
    # Instanciar un tipo 
    dynExfn = InflationDynamicExclusion(2,2)
    @test dynExfn isa InflationDynamicExclusion

    # Probar que esté definido el método para obtener su nombre 
    @test measure_name(dynExfn) isa String
    @test measure_tag(dynExfn) isa String

    # Probar con bases del IPC con variaciones intermensuales iguales a cero.
    # Estas pruebas ayudan a verificar que la función de inflación se pueda
    # llamar sobre los tipos correctos 
   
    zero_base = getzerobase()
    m_traj_infl = dynExfn(zero_base)
    # Probamos que el resumen intermensual sea igual a cero
    @test all(m_traj_infl .≈ 0)

    # Obtenemos un UniformCountryStructure con dos bases y todas las variaciones
    # intermensuales iguales a cero
    zero_cst = getzerocountryst()
    traj_infl = dynExfn(zero_cst)
    
    # Probamos que la trayectoria de inflación sea más larga que el resumen
    # intermensual de una sola base 
    @test length(traj_infl) > length(m_traj_infl)

    # Probamos que la trayectoria de inflación sea igual a cero 
    @test all(traj_infl .≈ 0)
end