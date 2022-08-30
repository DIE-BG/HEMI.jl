# Función de combinación lineal óptima MSE 2022

# Definir la subyacente MAI óptima, calibrada con datos hasta 2018
optmai2018_absme = let 
    # Componentes metodologías MAI 
    maifns = [
        InflationCoreMai(MaiFP([0.0, 0.2765896107337652, 0.5156337952457809, 0.7052959516853838, 0.8442309350770743, 1.0])),
        InflationCoreMai(MaiG([0.0, 0.3142507204618185, 0.44857385313176157, 0.7193695351441445, 0.8307072986313512, 1.0])),
        InflationCoreMai(MaiF([0.0, 0.20073613992281686, 0.2273231180698717, 0.34266719744949414, 0.4200227663670728, 
                                0.5222141864302854, 0.6136934225111135, 0.687520514923968, 0.7467554041219938, 
                                0.8572615461459108, 1.0
        ])),
    ]

    # Ponderaciones MAI 
    mai_weights = Float32[ 0.5896299, 0.37953162, 0.030924587]

    # Subyacente óptima MAI por método ABSME 
    optmai = CombinationFunction(
        maifns..., 
        mai_weights, 
        "MAI óptima ABSME 2018"
    )

    optmai
end

# Definir la función de exclusión fija
optfx2018_absme = InflationFixedExclusionCPI(
    [35, 30, 190, 36, 37, 40, 31, 104, 162], 
    [29, 116, 31, 46, 39, 40]
)




# Definir la combinación óptima MSE 2022, con componentes optimizadas hasta 2018
# y ponderadores ajustados con datos hasta 2020.
optabsme2022 = let 
    # Componentes de inflación subyacente 
    components = [
        InflationPercentileEq(0.716344f0), 
        InflationPercentileWeighted(0.695585f0), 
        InflationTrimmedMeanEq(35.2881f0, 93.4009f0), 
        InflationTrimmedMeanWeighted(34.1943f0, 93.0f0), 
        InflationDynamicExclusion(1.03194f0, 3.42365f0), 
        optfx2018_absme,
        optmai2018_absme 
    ]

    # Ponderaciones de las demás componentes 
    absme_weights = Float32[
        0.164859, 
        0.0822618, 
        0.407029, 
        0.133195, 
        0.152838, 
        0,
        0.0598154
    ]

    # Subyacente óptima ABSME v2022
    optabsme2022 = CombinationFunction(
        components...,
        absme_weights, 
        "Subyacente óptima ABSME 2022"
    )

    optabsme2022
end

@info "Definición de funciones óptimas ABSME" optmai2018_absme optfx2018_absme optabsme2022
