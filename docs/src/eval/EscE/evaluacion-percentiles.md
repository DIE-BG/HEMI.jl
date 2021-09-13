# Percentiles 

En esta sección se documentan los resultados del proceso de evaluación de las medidas de inflación interanual basadas en la metodología de percentiles ponderados y equiponderados.

## Resultados de evaluación a diciembre de 2018

| Medida                        |    MSE | Error estándar |
| :---------------------------- | -----: | -------------: |
| Percentil equiponderado 71.43 | 2.9593 |         0.0026 |
| Percentil ponderado 69.04     | 4.0815 |         0.0037 |

### Descomposición aditiva del MSE

| Medida                        |    MSE | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
| :---------------------------- | -----: | ----------: | -------------: | ---------------: |
| Percentil equiponderado 71.43 | 2.9593 |      0.1497 |          2.582 |           0.2276 |
| Percentil ponderado 69.04     | 4.0815 |      0.5112 |         3.2734 |           0.2969 |


### Métricas de evaluación 

| Medida                        |   RMSE | Error medio |    MAE |  Huber | Correlación |
| :---------------------------- | -----: | ----------: | -----: | -----: | ----------: |
| Percentil equiponderado 71.43 | 1.6982 |     -0.3824 | 1.3204 | 0.8918 |      0.8082 |
| Percentil ponderado 69.04     | 1.9939 |     -0.4218 | 1.6004 | 1.1576 |       0.789 |

### Trayectorias de inflación observada

![Trayectoria observada](images/Percentile/Optim-Percentile_EVALDATE=2018-12-01_PARAM_PERIOD=60.svg)



