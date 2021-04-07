using SafeTestsets

@safetestset "Operations with types" begin 

    using CPIDataBase
    S = 10
    v = zeros(S, S)

    # println(isdefined(capitalize))
    @test 1 == (2-1)

    # Test capitalization with default base index
    cap = capitalize(v)
    @test all(cap .== 100)

    # Test capitalization with different base index
    base_idx = rand(100:110, S)
    cap = capitalize(v, base_index = base_idx)
    @test all(100 .<= cap[1, :] .<= 110)

end