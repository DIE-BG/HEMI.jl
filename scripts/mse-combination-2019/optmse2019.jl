# Función de combinación lineal óptima MSE 2019

optmse2019 = let 
    # Listas de exclusión óptima 
    excOpt00 = [35,30,190,36,37,40,31,104,162,32,33,159,193,161]
    excOpt10 = [29,31,116,39,46,40,30,35,186,47,197,41,22,48,185,34,184]

    # Componentes metodologías MAI 
    maifns = [
        InflationCoreMai(MaiF(4)),
        InflationCoreMai(MaiF(5)),
        InflationCoreMai(MaiF(10)),
        InflationCoreMai(MaiF(20)),
        InflationCoreMai(MaiF(40)),
        InflationCoreMai(MaiG(4)),
        InflationCoreMai(MaiG(5)),
        InflationCoreMai(MaiG(10)),
        InflationCoreMai(MaiG(20)),
        InflationCoreMai(MaiG(40))
    ]

    # Ponderaciones MAI 
    mai_weights = Float32[
        0.788371,
        -0.282135,
        0.246467,
        -0.0948016,
        0.160992,
        0.117855,
        -0.0400753,
        -0.0293709,
        0.0513666,
        0.054515,
    ]

    # Subyacente óptima MAI por método MSE 
    optmai = CombinationFunction(
        maifns..., 
        mai_weights, 
        "MAI óptima MSE"
    )

    # Componentes de inflación subyacente 
    components = [
        InflationPercentileEq(72), 
        InflationPercentileWeighted(70),
        InflationTrimmedMeanEq(57.5, 84), 
        InflationTrimmedMeanWeighted(15,97),
        InflationDynamicExclusion(0.3222, 1.7283), 
        InflationFixedExclusionCPI(excOpt00, excOpt10), 
        optmai 
    ]

    # Ponderaciones de las demás componentes 
    mse_weights = Float32[
        -0.36216 ,
        0.0141849,
        1.1065,
        -0.134828,
        -0.0895958,
        0.287025,
        0.177114,
    ]

    # Subyacente óptima MSE v2019
    optmse2019 = CombinationFunction(
        components...,
        mse_weights, 
        "Subyacente óptima MSE 2019"
    )

    optmse2019
end