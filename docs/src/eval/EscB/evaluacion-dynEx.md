# Exclusión dinámica

En esta sección se documentan los resultados del proceso de evaluación de las medidas de inflación interanual basadas en la metodología de exclusión dinámica.

## Resultados de evaluación con criterios básicos a diciembre de 2020

### Exclusión dinámica con factores (0.3243, 1.7657)

| Medida                |    MSE | Error estándar |
|:--------------------- | ------:| --------------:|
| dynEx(0.3243, 1.7657) | 0.2865 |         0.0002 |

## Descomposición aditiva del MSE

### Exclusión dinámica con factores (0.3243, 1.7657)

| Medida                |    MSE | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
|:--------------------- | ------:| -----------:| --------------:| ----------------:|
| dynEx(0.3243, 1.7657) | 0.2865 |      0.0084 |         0.0113 |           0.2667 |

## Métricas de evaluación 

### Exclusión dinámica con factores (0.3243, 1.7657)
| Medida                |   RMSE | Error medio |    MAE |  Huber | Correlación |
|:--------------------- | ------:| -----------:| ------:| ------:| -----------:|
| dynEx(0.3243, 1.7657) | 0.5299 |     -0.0236 | 0.4089 | 0.1381 |      0.9783 |


## Trayectoria de inflación observada

![Trayectoria observada](images/dynamic-exclusion/obs_trajectory.svg)
