# Percentiles 

En esta sección se documentan los resultados del proceso de evaluación de las medidas de inflación interanual basadas en la metodología de percentiles ponderados y equiponderados.

## Resultados de evaluación con criterios básicos a diciembre de 2020


| Medida                        |    MSE | Error estándar |
|:----------------------------- | ------:| --------------:|
| Percentil ponderado 70.0      | 0.4293 |         0.0003 |
| Percentil equiponderado 72.0  | 0.2246 |         0.0001 |

## Descomposición aditiva del MSE


| Medida                       |    MSE | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
|:---------------------------- | ------:| -----------:| --------------:| ----------------:|
| Percentil ponderado 70.0     | 0.4293 |      0.0306 |         0.0509 |           0.3478 |
| Percentil equiponderado 72.0 | 0.2246 |      0.0084 |         0.0387 |           0.1775 |




## Métricas de evaluación 


| Medida                       |   RMSE | Error medio |    MAE |  Huber | Correlación |
|:---------------------------- | ------:| -----------:| ------:| ------:| -----------:|
| Percentil ponderado 70.0     | 0.6504 |     -0.1461 | 0.5312 | 0.2058 |      0.9737 |
| Percentil equiponderado 72.0 | 0.4709 |     -0.0754 | 0.3428 | 0.1081 |      0.9844 |

## Trayectorias de inflación observada

![Trayectoria observada](images/InflPercentileWeighted/obs_trajectory.svg)

![Trayectoria observada](images/InflPercentileEq/obs_trajectory.svg)

## Evaluación gráfica de percentiles 

### Percentiles ponderados 
![Min MSE](images/InflPercentileWeighted/MSE.png)

### Percentiles equiponderados
![Min MSE](images/InflPercentileEq/MSE.png)