# Combinación lineal óptima MSE 

En esta sección se documentan los resultados del proceso de evaluación de las medidas de inflación interanual basadas en la combinación lineal óptima MSE

## Resultados de evaluación con criterios básicos a diciembre de 2019


| Medida                                       |      MSE | Error estándar |
| :------------------------------------------- | -------: | -------------: |
| Inflación de exclusión dinámica (0.32, 1.73) |    0.291 |         0.0002 |
|     Exclusión fija de gastos básicos(14, 17) |   0.6422 |         0.0006 |
|    Media Truncada Equiponderada (57.5, 84.0) |   0.2173 |         0.0001 |
|        Media Truncada Ponderada (15.0, 97.0) |    0.295 |         0.0002 |
|                 Percentil equiponderado 72.0 |   0.2414 |         0.0002 |
|                     Percentil ponderado 70.0 |   0.4067 |         0.0003 |
|                    Subyacente MAI óptima MSE |   0.2876 |         0.0003 |


### Combinación lineal óptima 

| Medida                                       | Ponderador |
| :------------------------------------------- | ---------: |
| Inflación de exclusión dinámica (0.32, 1.73) |    -0.0934 |
|     Exclusión fija de gastos básicos(14, 17) |     0.2984 |
|    Media Truncada Equiponderada (57.5, 84.0) |     1.1624 |
|        Media Truncada Ponderada (15.0, 97.0) |    -0.1055 |
|                 Percentil equiponderado 72.0 |    -0.3272 |
|                     Percentil ponderado 70.0 |      0.006 |
|                    Subyacente MAI óptima MSE |     0.0592 |


| Medida                        |     MSE | Error estándar |
| :---------------------------- | ------: | -------------: |
| Combinación lineal óptima MSE |   0.154 |         0.0001 |


## Descomposición aditiva del MSE


| Medida                                       |      MSE | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
| :------------------------------------------- | -------: | ----------: | -------------: | ---------------: |
| Inflación de exclusión dinámica (0.32, 1.73) |    0.291 |      0.0085 |         0.0149 |           0.2675 |
|     Exclusión fija de gastos básicos(14, 17) |   0.6422 |      0.1263 |         0.1408 |           0.3752 |
|    Media Truncada Equiponderada (57.5, 84.0) |   0.2173 |      0.0097 |         0.0404 |           0.1672 |
|        Media Truncada Ponderada (15.0, 97.0) |    0.295 |      0.0092 |         0.0118 |            0.274 |
|                 Percentil equiponderado 72.0 |   0.2414 |      0.0043 |         0.0601 |           0.1769 |
|                     Percentil ponderado 70.0 |   0.4067 |      0.0189 |         0.0357 |           0.3522 |
|                    Subyacente MAI óptima MSE |   0.2876 |      0.0551 |         0.0077 |           0.2248 |


### Combinación lineal óptima 

| Medida                        |     MSE | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
| :---------------------------- | ------: | ----------: | -------------: | ---------------: |
| Combinación lineal óptima MSE |   0.154 |      0.0053 |         0.0101 |           0.1386 |


## Métricas de evaluación 

| Medida                                       |     RMSE | Error medio |      MAE |    Huber | Correlación |
| :------------------------------------------- | -------: | ----------: | -------: | -------: | ----------: |
| Inflación de exclusión dinámica (0.32, 1.73) |   0.5336 |     -0.0002 |   0.4059 |   0.1392 |      0.9779 |
|     Exclusión fija de gastos básicos(14, 17) |   0.7919 |     -0.3051 |   0.6407 |   0.2901 |      0.9731 |
|    Media Truncada Equiponderada (57.5, 84.0) |   0.4638 |      0.0846 |   0.3624 |   0.1063 |      0.9854 |
|        Media Truncada Ponderada (15.0, 97.0) |   0.5373 |     -0.0134 |   0.4183 |   0.1425 |      0.9776 |
|                 Percentil equiponderado 72.0 |   0.4882 |     -0.0361 |   0.3562 |   0.1156 |      0.9843 |
|                     Percentil ponderado 70.0 |   0.6321 |     -0.0938 |   0.5065 |   0.1936 |      0.9732 |
|                    Subyacente MAI óptima MSE |   0.5292 |     -0.1338 |   0.4138 |   0.1392 |      0.9818 |



### Combinación lineal óptima 

| Medida                        |    RMSE | Error medio |     MAE |   Huber | Correlación |
| :---------------------------- | ------: | ----------: | ------: | ------: | ----------: |
| Combinación lineal óptima MSE |  0.3884 |       0.012 |   0.292 |  0.0756 |      0.9886 |



## Trayectoria de inflación observada

![Trayectoria observada](images/comb_lineal_2019/comb_lineal_2019.svg)

