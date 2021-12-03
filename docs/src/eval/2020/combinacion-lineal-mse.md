# Combinación lineal MSE  

En esta sección se documentan los resultados del proceso de combinación y
evaluación fuera de muestra de los estimadores de inflación obtenidos. 

## Ejercicio de validación cruzada y prueba
La metodología de evaluación puede resumirse en dos pasos: 

1. Se obtienen trayectorias hasta un determinado período, denominado de
   *entrenamiento*. 
2. Se combinan las trayectorias de inflación del período de entrenamiento
   utilizando un método de combinación lineal para obtener ponderadores. Los
   diferentes métodos de combinación lineal utilizados se describen en la
   sección siguiente. Posteriormente, la trayectoria combinada es evaluada en un
   determinado período posterior al período de entrenamiento, utilizando los
   mismos ponderadores obtenidos en el período de entrenamiento. Se denomina
   este período como *período de validación* o *prueba*. 

Este proceso se repite durante varios períodos para obtener una métrica de
validación cruzada. La métrica de validación cruzada permite calibrar los
hiperparámetros en los métodos de combinación lineal, tales como: 

- El subperíodo de entrenamiento: se evalúa la disyuntiva entre utilizar todo el
  período de entrenamiento o el subperíodo de la base 2010 del IPC. 
- El parámetro de regularización $\lambda$ del método de combinación Ridge.
- Incluir en la combinación lineal de estimadores la medida de exclusión fija de
  gastos básicos.
- Agregar un intercepto en la combinación lineal. 

Los períodos de entrenamiento y validación utilizados son los siguientes: 

|  No.  |    Entrenamiento    |   Validación    |
| :---: | :-----------------: | :-------------: |
|   1   | Dic-2001 a Dic-2012 | Ene-13 a Dic-14 |
|   2   | Dic-2001 a Dic-2013 | Ene-14 a Dic-15 |
|   3   | Dic-2001 a Dic-2014 | Ene-15 a Dic-16 |
|   4   | Dic-2001 a Dic-2015 | Ene-16 a Dic-17 |
|   5   | Dic-2001 a Dic-2016 | Ene-17 a Dic-18 |

Finalmente, se reserva un período de prueba, el cual no es utilizado para
calibrar ningún hiperparámetro y así tener una medida del desempeño final de
cada método de combinación. El período de prueba es el siguiente:

|  No.  |    Entrenamiento    |     Prueba      |
| :---: | :-----------------: | :-------------: |
|   1   | Dic-2001 a Dic-2018 | Ene-19 a Dic-20 |


### Métodos de combinación lineal

Se evalúan los siguientes métodos de combinación lineal: 
1. Ponderadores de mínimos cuadrados (LS, por las siglas en inglés *Least Squares*). 
2. Ponderadores de mínimos cuadrados con regularización Ridge. 
4. Ponderadores de mínimos cuadrados restringidos.

### Escenarios de hiperparámetros 

Se consideran cinco escenarios de calibración de hiperparámetros: 
1. **Escenario A**: 
   - Se incluyen todos los estimadores de inflación calibrados hasta diciembre de 2018. 
   - Los ponderadores de combinación se obtienen en el período completo de entrenamiento. 
2. **Escenario B**: 
   - Se incluyen todos los estimadores de inflación calibrados hasta diciembre de 2018. 
   - Los ponderadores de combinación se obtienen en el subperíodo de entrenamiento comprendido a partir de diciembre de 2011. 
3. **Escenario C**: 
   - Se incluyen todos los estimadores de inflación calibrados hasta diciembre de 2018. 
   - Los ponderadores de combinación se obtienen en el subperíodo de entrenamiento comprendido a partir de diciembre de 2011. 
   - Se agrega un intercepto en la combinación lineal de estimadores.  
4. **Escenario D**: 
   - Se incluyen todos los estimadores de inflación calibrados hasta diciembre de 2018, excepto el estimador de exclusión fija de gastos básicos
   - Los ponderadores de combinación se obtienen en el subperíodo de entrenamiento comprendido a partir de diciembre de 2011. 
   - Se agrega un intercepto en la combinación lineal de estimadores.  
5. **Escenario E**: 
   - Se incluyen todos los estimadores de inflación calibrados hasta diciembre de 2018, excepto el estimador de exclusión fija de gastos básicos
   - Los ponderadores de combinación se obtienen en el subperíodo de entrenamiento comprendido a partir de diciembre de 2011. 



## Combinación lineal de mínimos cuadrados 

| Escenario | MSE CV | MSE Prueba |
| :-------: | -----: | ---------: |
|     A     | 0.1307 |     0.1022 |
|     E     | 0.2025 |     0.1754 |
|     B     | 0.2026 |     0.1849 |
|     D     | 0.7344 |     0.1927 |
|     C     | 0.7399 |     0.2081 |

A continuación, se presentan las ponderaciones de las combinaciones lineales utilizando los datos de entrenamiento del período de prueba, comprendido entre diciembre de 2001 y diciembre de 2018. 

### Ponderaciones de combinación del escenario A

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |     -0.1845 |
| Percentil ponderado 70.0                     |     -0.0592 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.7501 |
| Media Truncada Ponderada (21.0, 95.89)       |     -0.0976 |
| Inflación de exclusión dinámica (0.32, 1.68) |     -0.0501 |
| Exclusión fija de gastos básicos(14, 14)     |      0.2618 |
| MAI óptima MSE 2018                          |      0.3864 |

### Ponderaciones de combinación del escenario B

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |     -0.0372 |
| Percentil ponderado 70.0                     |      -0.032 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.6719 |
| Media Truncada Ponderada (21.0, 95.89)       |      0.0396 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.0104 |
| Exclusión fija de gastos básicos(14, 14)     |     -0.0256 |
| MAI óptima MSE 2018                          |      0.3451 |

### Ponderaciones de combinación del escenario C

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Variación interanual constante igual a 1.0   |     -0.5326 |
| Percentil equiponderado 72.4                 |      -0.064 |
| Percentil ponderado 70.0                     |     -0.0383 |
| Media Truncada Equiponderada (58.76, 83.15)  |      1.0593 |
| Media Truncada Ponderada (21.0, 95.89)       |      0.0623 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.0129 |
| Exclusión fija de gastos básicos(14, 14)     |     -0.0354 |
| MAI óptima MSE 2018                          |      0.1094 |
### Ponderaciones de combinación del escenario D

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Variación interanual constante igual a 1.0   |      -0.499 |
| Percentil equiponderado 72.4                 |     -0.0618 |
| Percentil ponderado 70.0                     |     -0.0379 |
| Media Truncada Equiponderada (58.76, 83.15)  |      1.0535 |
| Media Truncada Ponderada (21.0, 95.89)       |      0.0278 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.0127 |
| MAI óptima MSE 2018                          |      0.1041 |

### Ponderaciones de combinación del escenario E

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |     -0.0368 |
| Percentil ponderado 70.0                     |      -0.032 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.6856 |
| Media Truncada Ponderada (21.0, 95.89)       |      0.0152 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.0104 |
| MAI óptima MSE 2018                          |      0.3302 |

### Trayectorias de inflación observada

![Trayectoria observada mínimos cuadrados](images/mse-combination-cv-test/ls_combination_2020.svg)



## Combinación lineal Ridge

| Escenario | $\lambda$ | MSE CV | MSE Prueba |
| :-------: | --------: | -----: | ---------: |
|     C     |       0.1 | 1.0153 |     0.1688 |
|     D     |       0.1 | 1.0124 |     0.1784 |
|     A     |       5.9 |  0.089 |     0.2046 |
|     B     |       2.0 | 0.1224 |     0.2094 |
|     E     |       1.1 | 0.1238 |     0.2257 |

A continuación, se presentan las ponderaciones de las combinaciones lineales utilizando los datos de entrenamiento del período de prueba, comprendido entre diciembre de 2001 y diciembre de 2018. 

### Ponderaciones de combinación del escenario A

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |      0.1438 |
| Percentil ponderado 70.0                     |      0.1333 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.1437 |
| Media Truncada Ponderada (21.0, 95.89)       |       0.136 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.1368 |
| Exclusión fija de gastos básicos(14, 14)     |       0.144 |
| MAI óptima MSE 2018                          |      0.1451 |

### Ponderaciones de combinación del escenario B

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |      0.1581 |
| Percentil ponderado 70.0                     |       0.126 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.1557 |
| Media Truncada Ponderada (21.0, 95.89)       |      0.1341 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.1409 |
| Exclusión fija de gastos básicos(14, 14)     |      0.1157 |
| MAI óptima MSE 2018                          |      0.1491 |

### Ponderaciones de combinación del escenario C

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Variación interanual constante igual a 1.0   |      0.1581 |
| Percentil equiponderado 72.4                 |      0.2023 |
| Percentil ponderado 70.0                     |       0.075 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.2037 |
| Media Truncada Ponderada (21.0, 95.89)       |      0.0748 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.0989 |
| Exclusión fija de gastos básicos(14, 14)     |       0.025 |
| MAI óptima MSE 2018                          |      0.2629 |

### Ponderaciones de combinación del escenario D

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Variación interanual constante igual a 1.0   |      0.1406 |
| Percentil equiponderado 72.4                 |      0.2052 |
| Percentil ponderado 70.0                     |      0.0794 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.2066 |
| Media Truncada Ponderada (21.0, 95.89)       |      0.0836 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.1041 |
| MAI óptima MSE 2018                          |      0.2674 |

### Ponderaciones de combinación del escenario E

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |      0.1806 |
| Percentil ponderado 70.0                     |      0.1397 |
| Media Truncada Equiponderada (58.76, 83.15)  |       0.178 |
| Media Truncada Ponderada (21.0, 95.89)       |      0.1497 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.1572 |
| MAI óptima MSE 2018                          |       0.175 |

### Trayectorias de inflación observada

![Trayectoria observada Ridge](images/mse-combination-cv-test/ridge_combination_2020.svg)



## Combinación lineal restringida

| Escenario | MSE CV | MSE Prueba |
| :-------: | -----: | ---------: |
|     A     | 0.1102 |     0.1279 |
|     B     | 0.1276 |     0.1753 |
|     E     | 0.1284 |     0.1753 |
|     D     |  0.176 |     0.1753 |
|     C     | 0.1278 |     0.1753 |

A continuación, se presentan las ponderaciones de las combinaciones lineales utilizando los datos de entrenamiento del período de prueba, comprendido entre diciembre de 2001 y diciembre de 2018. 

### Ponderaciones de combinación del escenario A

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |         0.0 |
| Percentil ponderado 70.0                     |         0.0 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.4309 |
| Media Truncada Ponderada (21.0, 95.89)       |         0.0 |
| Inflación de exclusión dinámica (0.32, 1.68) |         0.0 |
| Exclusión fija de gastos básicos(14, 14)     |      0.2203 |
| MAI óptima MSE 2018                          |      0.3489 |

### Ponderaciones de combinación del escenario B

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |         0.0 |
| Percentil ponderado 70.0                     |      0.1344 |
| Media Truncada Equiponderada (58.76, 83.15)  |       0.484 |
| Media Truncada Ponderada (21.0, 95.89)       |         0.0 |
| Inflación de exclusión dinámica (0.32, 1.68) |         0.0 |
| Exclusión fija de gastos básicos(14, 14)     |         0.0 |
| MAI óptima MSE 2018                          |      0.3816 |

### Ponderaciones de combinación del escenario C

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Variación interanual constante igual a 1.0   |         0.0 |
| Percentil equiponderado 72.4                 |         0.0 |
| Percentil ponderado 70.0                     |      0.1344 |
| Media Truncada Equiponderada (58.76, 83.15)  |       0.484 |
| Media Truncada Ponderada (21.0, 95.89)       |         0.0 |
| Inflación de exclusión dinámica (0.32, 1.68) |         0.0 |
| Exclusión fija de gastos básicos(14, 14)     |         0.0 |
| MAI óptima MSE 2018                          |      0.3816 |

### Ponderaciones de combinación del escenario D

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Variación interanual constante igual a 1.0   |         0.0 |
| Percentil equiponderado 72.4                 |         0.0 |
| Percentil ponderado 70.0                     |      0.1344 |
| Media Truncada Equiponderada (58.76, 83.15)  |       0.484 |
| Media Truncada Ponderada (21.0, 95.89)       |         0.0 |
| Inflación de exclusión dinámica (0.32, 1.68) |         0.0 |
| MAI óptima MSE 2018                          |      0.3816 |

### Ponderaciones de combinación del escenario E

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |         0.0 |
| Percentil ponderado 70.0                     |      0.1344 |
| Media Truncada Equiponderada (58.76, 83.15)  |       0.484 |
| Media Truncada Ponderada (21.0, 95.89)       |         0.0 |
| Inflación de exclusión dinámica (0.32, 1.68) |         0.0 |
| MAI óptima MSE 2018                          |      0.3816 |

### Trayectorias de inflación observada

![Trayectoria observada restringida](images/mse-combination-cv-test/share_combination_2020.svg)




## Evaluación a diciembre de 2020

En esta sección se ajustan las ponderaciones de las medidas óptimas utilizando datos hasta
diciembre de 2020. Posteriormente se presentan métricas de evaluación en el
período de diciembre de 2011 a diciembre de 2020. 


### MSE en período base 2010

El MSE base 2010 es obtenido para cada configuración en el período de diciembre de 2011 a diciembre de 2020. Los datos se encuentran ordenados por MSE en el período base 2010.

| Método       | Escenario | MSE CV | MSE Prueba | MSE base 2010 | Error estándar |
| :----------- | :-------: | -----: | ---------: | ------------: | -------------: |
| LS           |     C     | 0.7399 |     0.2081 |        0.0596 |         0.0002 |
| LS           |     A     | 0.1307 |     0.1022 |        0.0596 |         0.0002 |
| LS           |     B     | 0.2026 |     0.1849 |        0.0596 |         0.0002 |
| Restringidos |     A     | 0.1102 |     0.1279 |        0.0606 |         0.0002 |
| Restringidos |     B     | 0.1276 |     0.1753 |        0.0606 |         0.0002 |
| Restringidos |     C     | 0.1278 |     0.1753 |        0.0606 |         0.0002 |
| LS           |     D     | 0.7344 |     0.1927 |        0.0635 |         0.0002 |
| LS           |     E     | 0.2025 |     0.1754 |        0.0636 |         0.0002 |
| Restringidos |     D     |  0.176 |     0.1753 |        0.0637 |         0.0002 |
| Restringidos |     E     | 0.1284 |     0.1753 |        0.0637 |         0.0002 |
| Ridge        |     C     | 1.0153 |     0.1688 |        0.0647 |         0.0002 |
| Ridge        |     D     | 1.0124 |     0.1784 |        0.0673 |         0.0002 |
| Ridge        |     E     | 0.1238 |     0.2257 |        0.0758 |         0.0002 |
| Ridge        |     B     | 0.1224 |     0.2094 |        0.0814 |         0.0003 |
| Ridge        |     A     |  0.089 |     0.2046 |         0.139 |         0.0004 |

### Métricas de evaluación 

| Método       | Escenario | MSE CV | MSE Prueba |   RMSE | Error medio |    MAE |  Huber | Correlación |
| :----------- | :-------: | -----: | ---------: | -----: | ----------: | -----: | -----: | ----------: |
| LS           |     C     | 0.7399 |     0.2081 | 0.2416 |      0.0001 | 0.1979 | 0.0298 |      0.8845 |
| LS           |     A     | 0.1307 |     0.1022 | 0.2417 |      0.0003 |  0.198 | 0.0298 |      0.8847 |
| LS           |     B     | 0.2026 |     0.1849 | 0.2417 |      0.0003 |  0.198 | 0.0298 |      0.8847 |
| Restringidos |     A     | 0.1102 |     0.1279 | 0.2437 |     -0.0024 |  0.199 | 0.0303 |      0.8827 |
| Restringidos |     B     | 0.1276 |     0.1753 | 0.2437 |     -0.0024 |  0.199 | 0.0303 |      0.8827 |
| Restringidos |     C     | 0.1278 |     0.1753 | 0.2437 |     -0.0024 |  0.199 | 0.0303 |      0.8827 |
| LS           |     D     | 0.7344 |     0.1927 | 0.2497 |      0.0001 | 0.2027 | 0.0318 |       0.875 |
| LS           |     E     | 0.2025 |     0.1754 |   0.25 |      0.0006 | 0.2028 | 0.0318 |      0.8755 |
| Restringidos |     D     |  0.176 |     0.1753 | 0.2501 |      0.0008 | 0.2029 | 0.0318 |      0.8754 |
| Restringidos |     E     | 0.1284 |     0.1753 | 0.2501 |      0.0015 | 0.2029 | 0.0318 |      0.8754 |
| Ridge        |     C     | 1.0153 |     0.1688 | 0.2517 |     -0.0063 | 0.2051 | 0.0324 |      0.8752 |
| Ridge        |     D     | 1.0124 |     0.1784 | 0.2571 |     -0.0054 | 0.2081 | 0.0337 |      0.8685 |
| Ridge        |     E     | 0.1238 |     0.2257 | 0.2725 |     -0.0585 | 0.2183 | 0.0379 |       0.858 |
| Ridge        |     B     | 0.1224 |     0.2094 | 0.2818 |     -0.0943 | 0.2263 | 0.0407 |      0.8602 |  |
| Ridge        |     A     |  0.089 |     0.2046 | 0.3693 |     -0.2568 | 0.3012 | 0.0695 |      0.8588 |

## Ponderadores óptimos con datos hasta diciembre de 2020


### Combinación lineal de mínimos cuadrados 

#### Ponderaciones de combinación del escenario A

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |     -0.0454 |
| Percentil ponderado 70.0                     |     -0.0287 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.8667 |
| Media Truncada Ponderada (21.0, 95.89)       |     -0.1363 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.0385 |
| Exclusión fija de gastos básicos(14, 14)     |       0.128 |
| MAI óptima MSE 2018                          |      0.1728 |

#### Ponderaciones de combinación del escenario B

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |     -0.0454 |
| Percentil ponderado 70.0                     |     -0.0287 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.8667 |
| Media Truncada Ponderada (21.0, 95.89)       |     -0.1363 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.0385 |
| Exclusión fija de gastos básicos(14, 14)     |       0.128 |
| MAI óptima MSE 2018                          |      0.1728 |

#### Ponderaciones de combinación del escenario C
| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Variación interanual constante igual a 1.0   |     -0.0677 |
| Percentil equiponderado 72.4                 |     -0.0491 |
| Percentil ponderado 70.0                     |     -0.0294 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.9166 |
| Media Truncada Ponderada (21.0, 95.89)       |     -0.1341 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.0387 |
| Exclusión fija de gastos básicos(14, 14)     |      0.1274 |
| MAI óptima MSE 2018                          |      0.1436 |

#### Ponderaciones de combinación del escenario D

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Variación interanual constante igual a 1.0   |     -0.1627 |
| Percentil equiponderado 72.4                 |     -0.0561 |
| Percentil ponderado 70.0                     |     -0.0345 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.9096 |
| Media Truncada Ponderada (21.0, 95.89)       |      0.0135 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.0282 |
| MAI óptima MSE 2018                          |      0.1787 |

#### Ponderaciones de combinación del escenario E

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |     -0.0468 |
| Percentil ponderado 70.0                     |     -0.0328 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.7884 |
| Media Truncada Ponderada (21.0, 95.89)       |      0.0099 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.0276 |
| MAI óptima MSE 2018                          |      0.2498 |


### Combinación lineal Ridge 

#### Ponderaciones de combinación del escenario A

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |      0.1494 |
| Percentil ponderado 70.0                     |      0.1224 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.1471 |
| Media Truncada Ponderada (21.0, 95.89)       |      0.1343 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.1365 |
| Exclusión fija de gastos básicos(14, 14)     |      0.1283 |
| MAI óptima MSE 2018                          |      0.1365 |

#### Ponderaciones de combinación del escenario B
| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |      0.1622 |
| Percentil ponderado 70.0                     |      0.1267 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.1597 |
| Media Truncada Ponderada (21.0, 95.89)       |       0.137 |
| Inflación de exclusión dinámica (0.32, 1.68) |       0.142 |
| Exclusión fija de gastos básicos(14, 14)     |      0.1296 |
| MAI óptima MSE 2018                          |       0.148 |

#### Ponderaciones de combinación del escenario C
| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Variación interanual constante igual a 1.0   |       0.064 |
| Percentil equiponderado 72.4                 |      0.2295 |
| Percentil ponderado 70.0                     |      0.0759 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.2308 |
| Media Truncada Ponderada (21.0, 95.89)       |      0.0525 |
| Inflación de exclusión dinámica (0.32, 1.68) |       0.102 |
| Exclusión fija de gastos básicos(14, 14)     |         0.1 |
| MAI óptima MSE 2018                          |      0.2085 |

#### Ponderaciones de combinación del escenario D
| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Variación interanual constante igual a 1.0   |       0.055 |
| Percentil equiponderado 72.4                 |      0.2322 |
| Percentil ponderado 70.0                     |      0.0903 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.2342 |
| Media Truncada Ponderada (21.0, 95.89)       |      0.0919 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.1185 |
| MAI óptima MSE 2018                          |      0.2318 |

#### Ponderaciones de combinación del escenario E
| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |      0.1881 |
| Percentil ponderado 70.0                     |      0.1433 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.1855 |
| Media Truncada Ponderada (21.0, 95.89)       |      0.1564 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.1614 |
| MAI óptima MSE 2018                          |      0.1746 |


### Combinación lineal restringida 

#### Ponderaciones de combinación del escenario A

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |      0.0467 |
| Percentil ponderado 70.0                     |         0.0 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.6851 |
| Media Truncada Ponderada (21.0, 95.89)       |         0.0 |
| Inflación de exclusión dinámica (0.32, 1.68) |         0.0 |
| Exclusión fija de gastos básicos(14, 14)     |      0.0975 |
| MAI óptima MSE 2018                          |      0.1707 |

#### Ponderaciones de combinación del escenario B
| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |      0.0467 |
| Percentil ponderado 70.0                     |         0.0 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.6851 |
| Media Truncada Ponderada (21.0, 95.89)       |         0.0 |
| Inflación de exclusión dinámica (0.32, 1.68) |         0.0 |
| Exclusión fija de gastos básicos(14, 14)     |      0.0975 |
| MAI óptima MSE 2018                          |      0.1707 |

#### Ponderaciones de combinación del escenario C
| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Variación interanual constante igual a 1.0   |         0.0 |
| Percentil equiponderado 72.4                 |      0.0468 |
| Percentil ponderado 70.0                     |         0.0 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.6851 |
| Media Truncada Ponderada (21.0, 95.89)       |         0.0 |
| Inflación de exclusión dinámica (0.32, 1.68) |         0.0 |
| Exclusión fija de gastos básicos(14, 14)     |      0.0975 |
| MAI óptima MSE 2018                          |      0.1707 |

#### Ponderaciones de combinación del escenario D
| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Variación interanual constante igual a 1.0   |      0.0008 |
| Percentil equiponderado 72.4                 |         0.0 |
| Percentil ponderado 70.0                     |         0.0 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.7273 |
| Media Truncada Ponderada (21.0, 95.89)       |         0.0 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.0202 |
| MAI óptima MSE 2018                          |      0.2517 |

#### Ponderaciones de combinación del escenario E
| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 72.4                 |         0.0 |
| Percentil ponderado 70.0                     |         0.0 |
| Media Truncada Equiponderada (58.76, 83.15)  |      0.7225 |
| Media Truncada Ponderada (21.0, 95.89)       |         0.0 |
| Inflación de exclusión dinámica (0.32, 1.68) |      0.0227 |
| MAI óptima MSE 2018                          |      0.2547 |


### Trayectorias de inflación observada

![Trayectoria observada métodos](images/mse-combination-cv-test/ls-ridge-share.svg)
