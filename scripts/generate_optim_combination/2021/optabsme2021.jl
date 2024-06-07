# Función de combinación lineal óptima ABSME 2021

# Definir la subyacente MAI óptima, calibrada con datos hasta 2018
optmai_absme2021 = let 
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
    mai_weights = Float32[0.11448115, 0.10647138, 0.10958032, 0.098436758, 0.096933529, 0.091687977, 0.099304229, 0.091138400, 0.099669911, 0.092296347]

    # Subyacente óptima MAI por método ABSME 
    optmai = CombinationFunction(
        maifns..., 
        mai_weights, 
        "MAI óptima ABSME"
    )

    optmai
end

# Definir la función de exclusión fija
optfx_absme2021 = InflationFixedExclusionCPI{3}((
    [35,30,190,36,37,40,31,104,162,32,33,159,193,161], 
    [29,31,116,39,46,40,30,35,186,47,197,41,22,48,185,34,184],
    []
))

# Definir la combinación óptima ABSME 2021.
optabsme2021 = let 
    # Componentes de inflación subyacente 
    components = [
        InflationPercentileEq(72), 
        InflationPercentileWeighted(70), 
        InflationTrimmedMeanEq(42.5, 91), 
        InflationTrimmedMeanWeighted(52.5, 85), 
        InflationDynamicExclusion(0.3524, 1.8829), 
        optfx_absme2021,
        optmai_absme2021 
    ]

    # Ponderaciones de las demás componentes 
    absme_weights = Float32[
    0.029440723, 
    0.026790924, 
    0.13497497, 
    0.51598936, 
    0.14337616,    
    0.0071561225,  
    0.14227174]

    # Subyacente óptima ABSME v2021
    optabsme2021 = CombinationFunction(
        components...,
        absme_weights, 
        "Subyacente óptima ABSME 2021"
    )

    optabsme2021
end

@info "Definición de funciones óptimas ABSME" optmai_absme2021 optfx_absme2021 optabsme2021 