# Medias truncadas

En esta sección se documentan los resultados del proceso de evaluación de las medidas de inflación interanual basadas en la metodología de medias truncadas.

## Resultados de evaluación con criterios básicos a diciembre de 2020



| Medida             |      MSE | Error estándar |
|:-------------------|---------:|---------------:|
| MTEq-(58.76,83.15) |   0.2114 |         0.0001 |
|   MTW-(21.0,95.89) |   0.2939 |         0.0002 |

## Descomposición aditiva del MSE



| Medida                |    MSE | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
|:--------------------- | ------:| -----------:| --------------:| ----------------:|
| MTEq-(58.76,83.15)    | 0.2114 |      0.0049 |         0.0344 |           0.1721 |
|   MTW-(21.0,95.89)    | 0.2939 |      0.0086 |         0.0107 |           0.2747 |


## Métricas de evaluación 


| Medida                |   RMSE | Error medio |    MAE |  Huber | Correlación |
|:--------------------- | ------:| -----------:| ------:| ------:| -----------:|
| MTEq-(58.76,83.15)    | 0.4574 |      0.0491 | 0.3478 |  0.103 |      0.9851 |
|   MTW-(21.0,95.89)    | 0.5365 |     -0.0096 |  0.418 | 0.1421 |      0.9777 |


## Trayectoria de inflación observada

![Trayectoria observada](images/trimmed_mean/trayectorias_MT.svg)
