# Combinación lineal MSE  

En esta sección se documentan los resultados del proceso de combinación y
evaluación fuera de muestra de los estimadores de inflación obtenidos. 

## Metodología de evaluación
La metodología de evlauación puede resumirse en dos pasos: 

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
- Los parámetros de regularización $\lambda$ y $\gamma$ de los métodos de
  combinación Ridge, Lasso y Elastic Net. 
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


## Métodos de combinación lineal

Se evalúan los siguientes métodos de combinación lineal: 
1. Ponderadores de mínimos cuadrados. 
2. Ponderadores de mínimos cuadrados con regularización Ridge. 
3. Ponderadores de mínimos cuadrados con regularización Lasso. 
4. Ponderadores de mínimos cuadrados restringidos.
5. Ponderadores de mínimos cuadrados con regularización Elastic Net. 

## Escenarios de hiperparámetros 

Se consideran cinco escenarios de calibración de hiperparámetros: 
1. **Escenario A**: 
   - Se incluyen todos los estimadores de inflación calibrados hasta diciembre de 2018. 
   - Los ponderadores de combinación se obtienen en el período completo de entrenamiento. 
2. **Escenario B**: 
   - Se incluyen todos los estimadores de inflación calibrados hasta diciembre de 2018. 
   - Los ponderadores de combinación se obtienen en el subperíodo de entrenamiento comprendido a partir de enero de 2011. 
3. **Escenario C**: 
   - Se incluyen todos los estimadores de inflación calibrados hasta diciembre de 2018. 
   - Los ponderadores de combinación se obtienen en el subperíodo de entrenamiento comprendido a partir de enero de 2011. 
   - Se agrega un intercepto en la combinación lineal de estimadores.  
4. **Escenario D**: 
   - Se incluyen todos los estimadores de inflación calibrados hasta diciembre de 2018, excepto el estimador de exclusión fija de gastos básicos
   - Los ponderadores de combinación se obtienen en el subperíodo de entrenamiento comprendido a partir de enero de 2011. 
   - Se agrega un intercepto en la combinación lineal de estimadores.  
5. **Escenario E**: 
   - Se incluyen todos los estimadores de inflación calibrados hasta diciembre de 2018, excepto el estimador de exclusión fija de gastos básicos
   - Los ponderadores de combinación se obtienen en el subperíodo de entrenamiento comprendido a partir de enero de 2011. 



## Combinación lineal de mínimos cuadrados 

| Escenario | MSE CV | MSE Prueba |
| :-------: | -----: | ---------: |
|     D     | 0.6762 |     0.2821 |
|     E     | 0.4812 |     0.4260 |
|     C     | 0.6469 |     0.5597 |
|     B     | 0.4142 |     0.7877 |
|     A     | 0.4979 |     1.0028 |

Las componentes de la combinación lineal con la mejor métrica de prueba son: 

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Variación interanual constante igual a 1.0   |      1.6792 |
| Percentil equiponderado 71.43                |      5.7205 |
| Percentil ponderado 69.04                    |     -0.8216 |
| Media Truncada Equiponderada (43.78, 90.0)   |     -5.7513 |
| Media Truncada Ponderada (17.63, 96.2)       |      0.0029 |
| Inflación de exclusión dinámica (0.57, 2.67) |      0.5535 |
| MAI (FP,4,[0.29, 0.81, 0.98])                |      0.0182 |
| MAI (F,4,[0.29, 0.78, 0.98])                 |      0.7226 |
| MAI (G,4,[0.28, 0.39, 0.98])                 |      0.3371 |


### Trayectorias de inflación observada

![Trayectoria observada mínimos cuadrados](images/mse-combination/ls_combination.svg)



## Combinación lineal Ridge

| Escenario | $\lambda$ | MSE CV | MSE Prueba |
| :-------: | --------: | -----: | ---------: |
|     D     |      0.01 | 0.6303 |     0.2677 |
|     E     |     0.005 | 0.5069 |     0.3820 |
|     C     |       0.1 | 0.6373 |     0.5337 |
|     A     |       0.7 | 0.6138 |     0.6217 |
|     B     |       0.1 | 0.4867 |     0.7754 |

Las componentes de la combinación lineal con la mejor métrica de prueba son: 

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Variación interanual constante igual a 1.0   |      1.3435 |
| Percentil equiponderado 71.43                |      1.3805 |
| Percentil ponderado 69.04                    |     -0.2783 |
| Media Truncada Equiponderada (43.78, 90.0)   |     -1.0736 |
| Media Truncada Ponderada (17.63, 96.2)       |      -0.126 |
| Inflación de exclusión dinámica (0.57, 2.67) |     -0.0482 |
| MAI (FP,4,[0.29, 0.81, 0.98])                |     -0.0542 |
| MAI (F,4,[0.29, 0.78, 0.98])                 |      0.7052 |
| MAI (G,4,[0.28, 0.39, 0.98])                 |      0.2092 |


### Trayectorias de inflación observada

![Trayectoria observada Ridge](images/mse-combination/ridge_combination.svg)



## Combinación lineal Lasso 

| Escenario | $\lambda$ | MSE CV | MSE Prueba |
| :-------: | --------: | -----: | ---------: |
|     A     |       3.5 | 0.6352 |     0.8106 |
|     D     |       4.5 | 0.3854 |     1.0962 |
|     B     |       2.3 | 0.5821 |     1.1072 |
|     C     |       4.6 | 0.3853 |     1.1185 |
|     E     |       2.4 | 0.5822 |     1.1284 |

Las componentes de la combinación lineal con la mejor métrica de prueba son: 

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 71.43                |         0.0 |
| Percentil ponderado 69.04                    |         0.0 |
| Media Truncada Equiponderada (43.78, 90.0)   |         0.0 |
| Media Truncada Ponderada (17.63, 96.2)       |         0.0 |
| Inflación de exclusión dinámica (0.57, 2.67) |         0.0 |
| Exclusión fija de gastos básicos(26, 5)      |         0.0 |
| MAI (FP,4,[0.29, 0.81, 0.98])                |      0.2487 |
| MAI (F,4,[0.29, 0.78, 0.98])                 |      0.2563 |
| MAI (G,4,[0.28, 0.39, 0.98])                 |      0.4044 |


### Trayectorias de inflación observada

![Trayectoria observada Lasso](images/mse-combination/lasso_combination.svg)






## Combinación lineal restringida

| Escenario | MSE CV | MSE Prueba |
| :-------: | -----: | ---------: |
|     A     | 0.6704 |     0.6528 |
|     C     | 0.6255 |     0.6648 |
|     D     | 0.6255 |     0.6648 |
|     E     | 0.6537 |     0.7137 |
|     B     | 0.6537 |     0.7137 |

Las componentes de la combinación lineal con la mejor métrica de prueba son: 

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 71.43                |         0.0 |
| Percentil ponderado 69.04                    |         0.0 |
| Media Truncada Equiponderada (43.78, 90.0)   |         0.0 |
| Media Truncada Ponderada (17.63, 96.2)       |         0.0 |
| Inflación de exclusión dinámica (0.57, 2.67) |         0.0 |
| Exclusión fija de gastos básicos(26, 5)      |         0.0 |
| MAI (FP,4,[0.29, 0.81, 0.98])                |      0.6609 |
| MAI (F,4,[0.29, 0.78, 0.98])                 |      0.0172 |
| MAI (G,4,[0.28, 0.39, 0.98])                 |      0.3219 |


### Trayectorias de inflación observada

![Trayectoria observada restringida](images/mse-combination/share_combination.svg)





## Combinación lineal Elastic Net

| Escenario | $\lambda$ | $\gamma$ | MSE CV | MSE Prueba |
| :-------: | --------: | -------: | -----: | ---------: |
|     A     |       3.2 |      0.7 | 0.6503 |     0.8289 |
|     E     |       1.7 |      0.5 | 0.6382 |     1.0076 |
|     D     |       3.7 |      0.8 | 0.4792 |     1.0142 |
|     C     |       3.7 |      0.8 | 0.4791 |     1.0142 |
|     B     |       2.0 |      0.8 | 0.6369 |     1.0986 |

Las componentes de la combinación lineal con la mejor métrica de prueba son: 

| Medida de inflación                          | Ponderación |
| :------------------------------------------- | ----------: |
| Percentil equiponderado 71.43                |      0.0627 |
| Percentil ponderado 69.04                    |         0.0 |
| Media Truncada Equiponderada (43.78, 90.0)   |      0.0698 |
| Media Truncada Ponderada (17.63, 96.2)       |         0.0 |
| Inflación de exclusión dinámica (0.57, 2.67) |      0.0224 |
| Exclusión fija de gastos básicos(26, 5)      |         0.0 |
| MAI (FP,4,[0.29, 0.81, 0.98])                |       0.243 |
| MAI (F,4,[0.29, 0.78, 0.98])                 |      0.2334 |
| MAI (G,4,[0.28, 0.39, 0.98])                 |      0.3051 |


### Trayectorias de inflación observada

![Trayectoria observada Elastic Net](images/mse-combination/elasticnet_combination.svg)


