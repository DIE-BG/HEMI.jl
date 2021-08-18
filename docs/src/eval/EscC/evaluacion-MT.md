# Medias truncadas

En esta sección se documentan los resultados del proceso de evaluación de las medidas de inflación interanual basadas en la metodología de medias truncadas.

## Resultados de evaluación con criterios básicos a diciembre de 2019 modificando el parámetro de evaluación

| Medida             |      MSE | Error estándar |
|:-------------------|---------:|---------------:|
| MTEq-(56.99,85.51) |   0.3135 |         0.0002 |
|  MTW-(18.24,96.89) |   0.4058 |         0.0003 |

### Descomposición aditiva del MSE



| Medida                |    MSE | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
|:--------------------- | ------:| -----------:| --------------:| ----------------:|
| MTEq-(56.99,85.51)    | 0.3135 |      0.0055 |          0.034 |            0.274 |
|  MTW-(18.24,96.89)    | 0.4058 |      0.0098 |         0.0116 |           0.3845 |


### Métricas de evaluación 


| Medida                |   RMSE | Error medio |    MAE |  Huber | Correlación |
|:--------------------- | ------:| -----------:| ------:| ------:| -----------:|
| MTEq-(56.99,85.51)    | 0.5575 |      0.0533 | 0.4193 | 0.1488 |      0.9773 |
|  MTW-(18.24,96.89)    |  0.631 |     -0.0189 |   0.49 | 0.1909 |      0.9701 |


### Trayectoria de inflación observada

![Trayectoria observada](images/trimmed_mean/trayectorias_MT2019.svg)


## Resultados de evaluación con criterios básicos a diciembre de 2020 modificando el parámetro de evaluación

| Medida             |      MSE | Error estándar |
|:-------------------|---------:|---------------:|
| MTEq-(55.81,86.34) |   0.2946 |         0.0002 |
|    MTW-(18.0,97.0) |    0.406 |         0.0003 |

### Descomposición aditiva del MSE



| Medida                |    MSE | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
|:--------------------- | ------:| -----------:| --------------:| ----------------:|
| MTEq-(55.81,86.34)    | 0.2946 |      0.0043 |         0.0176 |           0.2727 |
|    MTW-(18.0,97.0)    |  0.406 |      0.0091 |         0.0118 |           0.3852 |


### Métricas de evaluación 


| Medida                |   RMSE | Error medio |    MAE |  Huber | Correlación |
|:--------------------- | ------:| -----------:| ------:| ------:| -----------:|
| MTEq-(55.81,86.34)    | 0.5404 |      0.0431 |  0.411 | 0.1415 |      0.9778 |
|    MTW-(18.0,97.0)    | 0.6317 |     -0.0045 | 0.4958 | 0.1925 |      0.9703 |


### Trayectoria de inflación observada

![Trayectoria observada](images/trimmed_mean/trayectorias_MT2020.svg)
