# Función de combinación lineal óptima MSE 2021

# Definir la subyacente MAI óptima, calibrada con datos hasta 2018
optmai_mse2021 = let 
    # Componentes metodologías MAI 
    maifns = [
        InflationCoreMai(MaiF(0:1/4:1)),
        InflationCoreMai(MaiG(0:1/4:1)),
        InflationCoreMai(MaiF(0:1/5:1)),
        InflationCoreMai(MaiG(0:1/5:1)),  
        InflationCoreMai(MaiF(0:1/10:1)),
        InflationCoreMai(MaiG(0:1/10:1)),    
        InflationCoreMai(MaiF(0:1/20:1)),
        InflationCoreMai(MaiG(0:1/20:1)), 
        InflationCoreMai(MaiF(0:1/40:1)),
        InflationCoreMai(MaiG(0:1/40:1)),                   

    ]

    # Ponderaciones MAI 
    mai_weights = Float32[ 0.79742682, 0.11082839, -0.29522967, -0.037427250, 0.23941688, -0.024653632, -0.084661230, 0.049339466, 0.16632006, 0.050283819]

    # Subyacente óptima MAI por método MSE 
    optmai = CombinationFunction(
        maifns..., 
        mai_weights, 
        "MAI óptima MSE"
    )

    optmai
end

# Definir la función de exclusión fija
optfx_mse2021 = InflationFixedExclusionCPI{3}((
    [35,30,190,36,37,40,31,104,162,32,33,159,193,161], 
    [29,31,116,39,46,40,30,35,186,47,197,41,22,48,185,34,184],
    []
))

# Definir la combinación óptima MSE 2021.
optmse2021 = let 
    # Componentes de inflación subyacente 
    components = [
        InflationPercentileEq(72), 
        InflationPercentileWeighted(70), 
        InflationTrimmedMeanEq(57.5, 84), 
        InflationTrimmedMeanWeighted(15, 97), 
        InflationDynamicExclusion(0.3222, 1.7283), 
        optfx_mse2021,
        optmai_mse2021 
    ]

    # Ponderaciones de las demás componentes 
    mse_weights = Float32[
        -0.32378256, 
        0.010275449, 
        1.0546468, 
        -0.13903011, 
        -0.080038212,        
        0.28515562,  
        0.19028130
    ]

    # Subyacente óptima MSE v2021
    optmse2021 = CombinationFunction(
        components...,
        mse_weights, 
        "Subyacente óptima MSE 2021"
    )

    optmse2021
end

@info "Definición de funciones óptimas MSE" optmai_mse2021 optfx_mse2021 optmse2021 