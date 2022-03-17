# Exclusión fija de gastos básicos

En esta sección se documentan los resultados del proceso de evaluación de las medidas de inflación interanual basadas en los métodos de exclusión fija de gastos básicos del IPC..

Medidas de exclusión fija evaluadas
 1. Exclusión Fija de Alimentos y energéticos variante 11
 2. Exclusión Fija de Energéticos 
 3. Exclusión Fija de Alimentos y energéticos variante 9
 4. Exclusión Fija Óptima 

## Resultados de evaluación con criterios básicos a diciembre de 2019 modificando el parámetro de evaluación

### Resultados de evaluación 

| Medida                     |    MSE | Error Estándar |
| :------------------------- | -----: | -------------: |
| Exclusión Óptima           |  0.807 |          0.001 |
| Alimentos y Energéticos 11 |  1.092 |          0.001 |
| Alimentos y Energéticos 9  |   3.97 |          0.003 |
| Energéticos                | 81.064 |          2.329 |

### Exclusión Fija Óptima

En total, luego del proceso de optimización, se excluyen 13 gastos básicos de la base 2000 y 7 gastos básicos de la Base 2010:

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


|  No.  | Gastos básicos excluidos en la base 2010 del IPC |
| :---: | :----------------------------------------------- |
|   1   | Tomate                                           |
|   2   | Chile pimiento                                   |
|   3   | Gas Propano                                      |
|   4   | Cebolla                                          |
|   5   | Culantro                                         |
|   6   | Papa                                             |
|   7   | Güisquil                                         |


### Descomposición aditiva del MSE

| Medida                     | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
| :------------------------- | ----------: | -------------: | ---------------: |
| Exclusión Óptima           |       0.208 |          0.092 |            0.507 |
| Alimentos y Energéticos 11 |       0.422 |          0.211 |            0.459 |
| Alimentos y Energéticos 9  |       3.158 |          0.142 |             0.67 |
| Energéticos                |       9.768 |          62.64 |            8.656 |


### Métricas de evaluación 

| Medida                     |  RMSE |     ME |   MAE | Huber | Correlación |
| :------------------------- | ----: | -----: | ----: | ----: | ----------: |
| Exclusión Óptima           | 0.891 | -0.415 | 0.733 | 0.361 |       0.964 |
| Alimentos y Energéticos 11 | 1.031 | -0.611 |  0.87 | 0.466 |       0.969 |
| Alimentos y Energéticos 9  | 1.981 | -1.757 | 1.817 | 1.332 |        0.95 |
| Energéticos                | 4.148 |  1.359 | 2.257 | 1.855 |       0.771 |


### Trayectorias de inflación observada

#### Exclusión Fija óptima

![Trayectoria Óptima observada](images/Fx-Ex/optima-c19.svg)

#### Medidas de Exclusión Fija
![Trayectoria Óptima observada](images/Fx-Ex/Trayectorias-FxEx-C19.svg)


## Resultados de evaluación con criterios básicos a diciembre de 2020 modificando el parámetro de evaluación

### Resultados de evaluación 

| Medida                     |    MSE | Error Estándar |
| :------------------------- | -----: | -------------: |
| Exclusión Óptima           |  0.803 |          0.001 |
| Alimentos y Energéticos 11 |  1.118 |          0.001 |
| Alimentos y Energéticos 9  |  3.803 |          0.003 |
| Energéticos                | 77.326 |          2.207 |


### Exclusión Fija Óptima

En total, luego del proceso de optimización, se excluyen 13 gastos básicos de la base 2000 y 8 gastos básicos de la Base 2010:

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


|  No.  | Gastos básicos excluidos en la base 2010 del IPC |
| :---: | :----------------------------------------------- |
|   1   | Tomate                                           |
|   2   | Culantro                                         |
|   3   | Cebolla                                          |
|   4   | Chile pimiento                                   |
|   5   | Gas Propano                                      |
|   6   | Papa                                             |
|   7   | Güisquil                                         |
|   8   | Diesel                                           |


!!! note 
    
    En comparación con la optimización con criterios a 2019, hay un gasto básico adicional en las exclusiones de la base 2010 (Diesel), los 7 gastos básicos restantes únicamente cambiaron el órden dentro del vector de exclusión.


### Descomposición aditiva del MSE

| Medida                     | Comp. Sesgo | Comp. Varianza | Comp. Covarianza |
| :------------------------- | ----------: | -------------: | ---------------: |
| Exclusión Óptima           |       0.189 |          0.084 |             0.53 |
| Alimentos y Energéticos 11 |       0.437 |          0.212 |            0.469 |
| Alimentos y Energéticos 9  |       2.959 |          0.137 |            0.707 |
| Energéticos                |       9.127 |         59.594 |            8.605 |


### Métricas de evaluación 

| Medida                     |  RMSE |     ME |   MAE | Huber | Correlación |
| :------------------------- | ----: | -----: | ----: | ----: | ----------: |
| Exclusión Óptima           | 0.889 | -0.392 | 0.728 | 0.359 |       0.961 |
| Alimentos y Energéticos 11 | 1.044 | -0.625 |  0.88 | 0.477 |       0.968 |
| Alimentos y Energéticos 9  | 1.939 | -1.701 | 1.759 | 1.278 |       0.946 |
| Energéticos                | 4.131 |  1.405 | 2.254 | 1.849 |       0.762 |


### Trayectorias de inflación observada

#### Exclusión Fija óptima

![Trayectoria Óptima observada](images/Fx-Ex/optima-c20.svg)

#### Medidas de Exclusión Fija
![Trayectoria Óptima observada](images/Fx-Ex/Trayectorias-FxEx-C20.svg)