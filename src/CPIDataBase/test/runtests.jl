using SafeTestsets

@safetestset "Create types" begin
    
    using Dates
    using CPIDataBase

    GB = 10
    PER = 20
    baseindex = 100.0
    
    v = rand(PER, GB) .- 0.25
    ipc = capitalize(v, baseindex)
    w = rand(GB)

    basedate = Date(2010,12)
    enddate = basedate + Month(PER-1)
    dates = basedate:Month(1):enddate

    ## Create individual types with same arrays: FullCPIBase, VarCPIBase, IndexCPIBase
    fullcpi = FullCPIBase(ipc, v, w, dates, baseindex)
    vcpi = VarCPIBase(v, w, dates, baseindex)
    indexcpi = IndexCPIBase(ipc, w, dates, baseindex)

    # Test they share the same arrays
    @test fullcpi.ipc === indexcpi.ipc
    @test fullcpi.v === vcpi.v
    @test fullcpi.w === vcpi.w === indexcpi.w
    
    # Create copies with constructors from FullCPIBase and test they hold different arrays
    vcpi2 = VarCPIBase(fullcpi)
    indexcpi2 = IndexCPIBase(fullcpi)

    @test vcpi.v == vcpi2.v     # same values in matrix
    @test !(vcpi.v === vcpi2.v) # different reference in memory

    @test indexcpi.ipc == indexcpi2.ipc
    @test !(indexcpi.ipc === indexcpi2.ipc)

    @test vcpi.fechas == vcpi2.fechas
    @test indexcpi.fechas == indexcpi2.fechas


    ## Test convert methods with different precision floats
    fullcpi32 = convert(Float32, deepcopy(fullcpi))
    vcpi32 = convert(Float32, deepcopy(vcpi))
    indexcpi32 = convert(Float32, deepcopy(indexcpi))
    
    # as matrixs are different type, == does not apply, check with isapprox
    @test fullcpi32.ipc ≈ fullcpi.ipc   
    @test fullcpi32.v == vcpi32.v

    @test indexcpi32.ipc ≈ indexcpi.ipc
    @test fullcpi32.ipc == indexcpi32.ipc
    
    @test vcpi32.v ≈ vcpi.v
    @test fullcpi32.baseindex == vcpi32.baseindex == indexcpi32.baseindex

    
    ## Create types with different base indexes
    baseindex = rand(100:0.5:110, GB)

    fullcpi_b = FullCPIBase(ipc, v, w, dates, baseindex)
    vcpi_b = VarCPIBase(fullcpi_b)
    indexcpi_b = IndexCPIBase(vcpi_b)

    # Test they hold the same base indexes, but not same arrays
    @test vcpi_b.baseindex == indexcpi_b.baseindex
    @test !(vcpi_b.baseindex === indexcpi_b.baseindex)
    @test length(fullcpi_b.baseindex) > 1
    @test length(vcpi_b.baseindex) > 1
    @test length(indexcpi_b.baseindex) > 1


    ## Create CountryStructure 

    # These hold the same v array values (not same array objects) with different base indexes
    cs = CountryStructure((vcpi, vcpi_b))

    @test cs[1].v == cs[2].v
    @test !(cs[1].v === cs[2].v)
    @test typeof(cs[1].baseindex) != typeof(cs[2].baseindex) # different containers
    @test eltype(cs[1].baseindex) == eltype(cs[2].baseindex) # same types
    @test length(cs[1].baseindex) != length(cs[2].baseindex) # different length

    # Check conversion of precision types
    cs32 = convert(Float32, cs)
    
    @test cs32[1].v ≈ cs[1].v
    @test eltype(cs32[1].baseindex) == Float32

end

@safetestset "Operations with types" begin 

    using CPIDataBase
    S = 10
    v = zeros(S, S)

    @test :capitalize in names(CPIDataBase)

    # Test capitalization with default base index
    cap = capitalize(v)
    @test all(cap .== 100)

    # Test capitalization with different base index
    @test all(capitalize(v, 110) .== 110)

    base_idx = rand(100:110, S)
    cap = capitalize(v, base_idx)
    @test all(100 .<= cap[1, :] .<= 110)
    
    # Test capitalize_addbase
    cap = CPIDataBase.capitalize_addbase(v, base_idx)
    @test all(100 .<= cap[1, :] .<= 110)
    @test size(cap, 1) == size(v, 1)+1

end