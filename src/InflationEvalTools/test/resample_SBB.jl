# resample_SBB.jl - Pruebas sobre métodos de remuestreo para el Stationary Block
# Bootstrap

using Dates, CPIDataBase
using CPIDataBase.TestHelpers
using Test

# Definir una base del IPC base 2000 con variaciones iguales a cero
test_gt00 = getzerobase(Float32, 218, 120, Date(2001, 1))

# Definir una base del IPC base 2010 con variaciones iguales a cero
test_gt10 = getzerobase(Float32, 279, 120, Date(2011, 1))

# Crear un CountryStructure
cs = UniformCountryStructure(test_gt00, test_gt10)

# Remuestrear la matriz de variaciones intermensuales
resample_sbb = ResampleSBB(12)

# Prueba sobre matriz
@test all(resample_sbb(test_gt00.v) .≈ 0)

# Probar que las ponderaciones, fechas y demás campos no están alterados 
resample_gt00 = resample_sbb(test_gt00)
@test resample_gt00.dates == test_gt00.dates
@test resample_gt00.baseindex == test_gt00.baseindex
@test resample_gt00.w == test_gt00.w

# Probar que el vector de ponderaciones es en efecto el mismo 
@test resample_gt00.w == test_gt00.w



## Remuestreo sobre CountryStructure

resample_cs = resample_sbb(cs)

# Comprobar que las matrices remuestreadas sean diferentes en memoria pero
# iguales en valor. 
@test !(resample_cs[1].v === test_gt00.v)
@test !(resample_cs[2].v === test_gt10.v)

@test (resample_cs[1].v == test_gt00.v)
@test (resample_cs[2].v == test_gt10.v)

# Comprobar que las ponderaciones no fueron copiadas 
@test resample_cs[1].w === test_gt00.w
@test resample_cs[2].w === test_gt10.w




