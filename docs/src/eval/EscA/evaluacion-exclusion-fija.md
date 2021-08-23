# Exclusión fija de gastos básicos

En esta sección se documentan los resultados del proceso de evaluación de las medidas de inflación interanual basadas en los métodos de exclusión fija de gastos básicos del IPC..

Medidas de exclusión fija evaluadas
 1. Exclusión Fija de Alimentos y energéticos variante 11
 2. Exclusión Fija de Energéticos 
 3. Exclusión Fija de Alimentos y energéticos variante 9
 4. Exclusión Fija Óptima 


## Resultados de evaluación con criterios básicos a diciembre de 2019

| Medida                     |     MSE | Error Estándar |
| :------------------------- | ------: | -------------: |
| Exclusión Óptima           |  0.6422 |         0.0006 |
| Alimentos y Energéticos 11 |  0.8667 |         0.0016 |
| Alimentos y Energéticos 9  |  3.1216 |          0.003 |
| Energéticos                | 82.0842 |         2.3344 |

### Exclusión Fija Óptima

En total, luego del proceso de optimización, se excluyen 14 gastos básicos de la base 2000 y 17 gastos básicos de la Base 2010:

|  No.  | Gastos básicos excluidos en la base 2000 del IPC                               |
| :---: | :----------------------------------------------------------------------------- |
|   1   | Cebolla                                                                        |
|   2   | Tomate                                                                         |
|   3   | Otras cuotas fijas y extraordinarias en la educación preprimaria y primaria    |
|   4   | Papa o patata                                                                  |
|   5   | Zanahoria                                                                      |
|   6   | Culantro o cilantro                                                            |
|   7   | Güisquil                                                                       |
|   8   | Gastos derivados del gas manufacturado y natural y gases licuados del petróleo |
|   9   | Transporte aéreo                                                               |
|  10   | Otras verduras y hortalizas                                                    |
|  11   | Frijol                                                                         |
|  12   | Gasolina                                                                       |
|  13   | Otras cuotas fijas y extraordinarias en la educación secundaria                |
|  14   | Transporte urbano                                                              |


|  No.  | Gastos básicos excluidos en la base 2010 del IPC |
| :---: | :----------------------------------------------- |
|   1   | Tomate                                           |
|   2   | Chile pimiento                                   |
|   3   | Gas propano                                      |
|   4   | Cebolla                                          |
|   5   | Culantro                                         |
|   6   | Papa                                             |
|   7   | Güisquil                                         |
|   8   | Lechuga                                          |
|   9   | Diesel                                           |
|  10   | Hierbabuena                                      |
|  11   | Servicio de transporte aéreo                     |
|  12   | Zanahoria                                        |
|  13   | Aguacate                                         |
|  14   | Otras legumbres y hortalizas                     |
|  15   | Gasolina regular                                 |
|  16   | Repollo                                          |
|  17   | Gasolina superior                                |

## Descomposición aditiva del MSE

| Medida                     | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
| :------------------------- | ----------: | -------------: | ---------------: |
| Exclusión Óptima           |      0.1263 |         0.1408 |           0.3752 |
| Alimentos y Energéticos 11 |      0.1836 |         0.2534 |           0.4297 |
| Alimentos y Energéticos 9  |      2.3603 |         0.1495 |           0.6117 |
| Energéticos                |     10.4907 |        62.9358 |           8.6577 |


## Métricas de evaluación 

| Medida                     |   RMSE |      ME |    MAE |  Huber | Correlación |
| :------------------------- | -----: | ------: | -----: | -----: | ----------: |
| Exclusión Óptima           | 0.7919 | -0.3051 | 0.6407 | 0.2901 |      0.9731 |
| Alimentos y Energéticos 11 | 0.9102 | -0.3668 | 0.7396 | 0.3659 |      0.9707 |
| Alimentos y Energéticos 9  | 1.7542 | -1.5135 | 1.5924 | 1.1134 |       0.954 |
| Energéticos                | 4.2484 |  1.6031 | 2.3149 | 1.9144 |      0.7678 |


## Trayectorias de inflación observada

### Exclusión Fija óptima

![Trayectoria Óptima observada](images/Fx-Ex/optima.svg)

### Medidas de Exclusión Fija
![Trayectoria Óptima observada](images/Fx-Ex/Trayectorias-FxEx.svg)