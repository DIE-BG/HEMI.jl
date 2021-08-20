# Medidas Basadas en Exclusión Fija 

En esta sección se documentan los resultados del proceso de evaluación de las medidas de inflación interanual basadas en Exclusión fija.

Evaluación de medidas de exclusión fija evaluadas
 1. Exclusión Fija de Alimentos y energéticos variante 11
 2. Exclusión Fija de Energéticos 
 3. Exclusión Fija de Alimentos y energéticos variante 9
 4. Exclusión Fija Óptima 


### Exclusión Fija Óptima

En total, luego del proceso de optimización, se excluyen 14 gastos básicos de la base 2000 y 17 gastos básicos de la Base 2010:

| Exclusiones Base 2000                                                             |
|:---------------------------------------------------------------------------------:|
| Cebolla                                                                           |
| Tomate                                                                            |
| Otras cuotas fijas y extraordinarias en la educación preprimaria y primaria       |
| Papa o patata                                                                     |
| Zanahoria                                                                         |
| Culantro o cilantro                                                               |
| Güisquil                                                                          |    
| Gastos derivados del gas manufacturado y natural y gases licuados del petróleo    |
| Transporte aéreo                                                                  |
| Otras verduras y hortalizas                                                       |
| Frijol                                                                            |
| Gasolina                                                                          |
| Otras cuotas fijas y extraordinarias en la educación secundaria                   |
| Transporte urbano                                                                 |



| Exclusiones Base 2010             |
|:---------------------------------:|
| Tomate                            |
| Culantro                          |
| Cebolla                           |
| Chile pimiento                    |
| Gas Propano                       |
| Papa                              |
| Güisquil                          |    
| Diesel                            |
| Lechuga                           |
| Hierbabuena                       |
| Servicio de transporte aéreo      |
| Zanahoria                         |
| Aguacate                          |
| Gasolina regular                  |
| Otras legumbres y hortalizas      |
| Repollo                           |
| Ejotes                            |
| Gasolina superior                 |

!!! note 
    
    En comparación con la optimización con criterios básicos a 2019, hay un gasto básico adicional en las exclusiones de la base 2010 (Ejotes), los 17 gastos básicos restantes únicamente cambiaron el órden dentro del vector de exclusión.

## Resultados de evaluación con criterios básicos a diciembre de 2020

| Medida                     | MSE      | Error Estándar | 
|:---------------------------|---------:|---------------:|
| Exclusión Óptima           |   0.646  |        0.001   |
| Alimentos y Energéticos 11 |   0.889  |        0.002   |
| Alimentos y Energéticos 9  |   2.989  |        0.003   |
| Energéticos                |  78.363  |        2.212   | 

## Descomposición aditiva del MSE

|                     Medida | Comp. Sesgo |  Comp. Varianza |  Comp. Covarianza | 
|:---------------------------|------------:|----------------:|------------------:|
|           Exclusión Óptima |       0.123 |           0.136 |             0.388 |
| Alimentos y Energéticos 11 |       0.195 |           0.256 |             0.438 |
|  Alimentos y Energéticos 9 |       2.200 |           0.141 |             0.647 |
|                Energéticos |       9.860 |          59.895 |             8.609 |


## Métricas de evaluación 

|                     Medida |     RMSE |       ME |      MAE |    Huber | Correlación |
|:---------------------------|---------:|---------:|---------:|---------:|------------:|
|           Exclusión Óptima |   0.795  |  -0.300  |   0.645  |   0.293  |      0.972  |
| Alimentos y Energéticos 11 |   0.924  |  -0.385  |   0.753  |   0.377  |      0.970  |
|  Alimentos y Energéticos 9 |   1.716  |  -1.460  |   1.540  |   1.067  |      0.950  |
|                Energéticos |   4.240  |   1.645  |   2.322  |   1.918  |      0.758  |


## Trayectorias de inflación observada

### Exclusión Fija óptima

![Trayectoria Óptima observada](images/Fx-Ex/optima.svg)

### Medidas de Exclusión Fija
![Trayectoria Óptima observada](images/Fx-Ex/Trayectorias-FxEx.svg)