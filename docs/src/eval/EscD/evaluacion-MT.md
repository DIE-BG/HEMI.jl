# Medias truncadas

En esta sección se documentan los resultados del proceso de evaluación de las medidas de inflación interanual basadas en la metodología de medias truncadas.

## Resultados de evaluación con criterios básicos a diciembre de 2019 modificando la metodología de remuestreo

| Medida             |      MSE | Error estándar |
|:-------------------|---------:|---------------:|
| MTEq-(38.58,91.36) |   2.5587 |         0.0024 |
|  MTW-(16.67,96.03) |   3.2077 |         0.0034 |

### Descomposición aditiva del MSE



| Medida                |    MSE | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
|:--------------------- | ------:| -----------:| --------------:| ----------------:|
| MTEq-(38.58,91.36)    | 2.5587 |      0.0946 |          0.106 |           2.3581 |
|  MTW-(16.67,96.03)    | 3.2077 |      0.1692 |         0.2375 |           2.8009 |


### Métricas de evaluación 


| Medida                |   RMSE | Error medio |    MAE |  Huber | Correlación |
|:--------------------- | ------:| -----------:| ------:| ------:| -----------:|
| MTEq-(38.58,91.36)    |  1.577 |      -0.146 | 1.1955 | 0.7919 |      0.8191 |
|  MTW-(16.67,96.03)    | 1.7589 |     -0.2519 | 1.3831 | 0.9471 |      0.8032 |


### Trayectoria de inflación observada

![Trayectoria observada](images/trimmed_mean/trayectorias_MT19-36.svg)

## Resultados de evaluación con criterios básicos a diciembre de 2019 modificando la metodología de remuestreo y el parámetro de evaluación

| Medida             |      MSE | Error estándar |
|:-------------------|---------:|---------------:|
| MTEq-(43.65,89.98) |   2.8048 |         0.0026 |
|  MTW-(17.82,96.21) |     3.43 |         0.0036 |

### Descomposición aditiva del MSE



| Medida                |    MSE | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
|:--------------------- | ------:| -----------:| --------------:| ----------------:|
| MTEq-(43.65,89.98)    | 2.8048 |      0.1397 |         0.1146 |           2.5505 |
|  MTW-(17.82,96.21)    |   3.43 |      0.2062 |         0.2398 |            2.984 |


### Métricas de evaluación 


| Medida                |   RMSE | Error medio |    MAE |  Huber | Correlación |
|:--------------------- | ------:| -----------:| ------:| ------:| -----------:|
| MTEq-(43.65,89.98)    |  1.652 |     -0.2499 |  1.264 |  0.846 |      0.8126 |
|  MTW-(17.82,96.21)    | 1.8196 |      -0.314 |  1.434 | 0.9938 |      0.7986 |


### Trayectoria de inflación observada

![Trayectoria observada](images/trimmed_mean/trayectorias_MT19-60.svg)


## Resultados de evaluación con criterios básicos a diciembre de 2020 modificando la metodología de remuestreo

| Medida             |      MSE | Error estándar |
|:-------------------|---------:|---------------:|
| MTEq-(38.26,91.56) |   2.4879 |         0.0023 |
|   MTW-(16.73,96.0) |   3.1337 |         0.0032 |

### Descomposición aditiva del MSE



| Medida                |    MSE | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
|:--------------------- | ------:| -----------:| --------------:| ----------------:|
| MTEq-(38.26,91.56)    | 2.4879 |      0.1025 |         0.0977 |           2.2878 |
|   MTW-(16.73,96.0)    | 3.1337 |      0.1885 |         0.2519 |           2.6933 |


### Métricas de evaluación 


| Medida                |   RMSE | Error medio |    MAE |  Huber | Correlación |
|:--------------------- | ------:| -----------:| ------:| ------:| -----------:|
| MTEq-(38.26,91.56)    |  1.556 |     -0.1773 | 1.1813 | 0.7789 |      0.8217 |
|   MTW-(16.73,96.0)    | 1.7405 |     -0.2944 | 1.3761 | 0.9379 |      0.8102 |


### Trayectoria de inflación observada

![Trayectoria observada](images/trimmed_mean/trayectorias_MT20-36.svg)

## Resultados de evaluación con criterios básicos a diciembre de 2020 modificando la metodología de remuestreo y el parámetro de evaluación

| Medida             |      MSE | Error estándar |
|:-------------------|---------:|---------------:|
| MTEq-(38.52,92.4)  |   2.6888 |         0.0025 |
|  MTW-(19.05,96.0)  |   3.3828 |         0.0034 |

### Descomposición aditiva del MSE



| Medida                |    MSE | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
|:--------------------- | ------:| -----------:| --------------:| ----------------:|
| MTEq-(38.52,92.4)     | 2.6888 |      0.1009 |         0.1091 |           2.4789 |
|  MTW-(19.05,96.0)     | 3.3828 |      0.2178 |         0.2814 |           2.8837 |


### Métricas de evaluación 


| Medida                |   RMSE | Error medio |    MAE |  Huber | Correlación |
|:--------------------- | ------:| -----------:| ------:| ------:| -----------:|
| MTEq-(38.52,92.4)     | 1.6177 |      -0.162 |  1.227 | 0.8187 |       0.817 |
|  MTW-(19.05,96.0)     | 1.8097 |     -0.3351 | 1.4398 | 0.9962 |       0.807 |


### Trayectoria de inflación observada

![Trayectoria observada](images/trimmed_mean/trayectorias_MT20-60.svg)