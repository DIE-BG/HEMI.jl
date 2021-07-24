### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ d722fbf0-eb4f-11eb-2fef-b19a7566ba31
begin
	import Pkg
	Pkg.activate("..")
	
	using PlutoUI
	using DrWatson, HEMI, Plots
end

# ╔═╡ ec957b42-5a6f-46be-986d-e7b99cfda80d
md"""
# Método de muestra ampliada implícitamente (MAI) 

Aspectos conceptuales y procedimiento de cómputo.

"""

# ╔═╡ 0f5e97c1-2125-4766-99fc-fda1f71bb391
PlutoUI.TableOfContents(aside=true, title="Contenido", depth=2)

# ╔═╡ 4b605b91-44df-49cf-8c0c-8566e30cc598
md"""
## Objetivos

- Conocer los aspectos conceptuales acerca de la medida de inflación subyacente MAI.
- Involucrarse en el proceso técnico de implementación de los algoritmos en el lenguaje de programación Julia.
- Aplicar la metodología de evaluación de la HEMI sobre este estimador muestral de inflación. 
- Que los participantes presenten resultados al aplicar la metodología de la HEMI a otros estimadores muestrales.
"""

# ╔═╡ 928289db-c42e-4a55-bb04-bac4b33ae379
md"""
## Otra visión de la inflación

- La inflación es un fenómeno no observable que varía en el tiempo.
- Mes a mes, el INE toma una muestra de precios de diferentes rubros y en diferentes puntos del país, con el objetivo de estimar el nivel de precios en la economía.
- En este sentido, las medidas de inflación derivadas del IPC son estadísticos de las muestras recolectadas por el INE.
- Existen diferentes tipos de estadísticos (estimadores muestrales): la variación interanual del IPC, medias truncadas, percentiles, medias móviles, métodos de exclusión fija, etc.
- En esta visión de la inflación, existe una literatura de medidas de inflación que presentan mejores propiedades estadísticas en la estimación de la inflación (no observable).

"""

# ╔═╡ 137b9a66-66fb-467a-a3af-20572f5286c2
md"""
## Introducción 

- Medida de inflación derivada del análisis de la distribución de variaciones intermensuales de índices de precios en el IPC de Guatemala.
- Procedimiento estadístico que utiliza una “muestra grande” de observaciones históricas.
- No elimina variaciones intermensuales atípicamente altas o bajas, sino que las transforma.
- Esta modificación neutraliza los efectos de valores atípicos (subyacente).
- La sustitución de “muestra ampliada implícitamente” permite mantener las propiedades estadísticas de la distribución de largo plazo de variaciones intermensuales.

"""

# ╔═╡ 1d59e61c-4cdf-43c6-970f-868beaeffe9b
md"""
## Utilización

- Utilizada en el DIE para el análisis de presiones inflacionarias.
- Insumo para el modelo macroeconómico semiestructural.
- Conceptualizada como un estadístico (estimador) de la inflación intermensual e interanual.
> Podría pensarse que es un estadístico “con memoria” debido a que utiliza información histórica para obtener la inflación intermensual.

"""

# ╔═╡ 96e18948-5150-4193-bc93-b78daf87f067
md"""
## El IPC de Guatemala

- El INE publica mensualmente cada uno de los índices de precios correspondientes a un conjunto representativo de los bienes y servicios de consumo de la economía guatemalteca.
- En los años 2000, los índices fueron publicados por el INE utilizando como mes de referencia diciembre de 2000.
- Actualmente, los índices de precios en el IPC se encuentran publicados utilizando como referencia el mes de diciembre de 2010, en el cual todos los índices de precios toman un valor de 100.
- En la información provista por el INE, los índices de precios de los bienes y servicios (en adelante, “gastos básicos”), se agrupan en una matriz.

"""

# ╔═╡ 0d1bf735-062f-44d7-bd70-2c25f16e8f59
md"""
# Aspectos conceptuales

A continuación, se describen algunos aspectos conceptuales y definiciones matemáticas que permiten formalizar el cómputo de la inflación subyacente MAI de un período particular.

"""

# ╔═╡ 535f144b-02fa-47b2-9990-9b8c033c42cb
md"""
## IPC de Guatemala

Sea $b \in \left\lbrace 2000, 2010 \right\rbrace$ el índice utilizado para referirse a cada una de las bases de datos de índices de precios al consumidor de la canasta representativa de la economía guatemalteca.
"""

# ╔═╡ 793cabab-c5d4-4ad3-bf22-fb1bef99aad1
md"""
Sea $IPC^{(b)}$ la matriz de índices de precios para cada uno de los gastos y servicios de la base $b$.

$$IPC^{(b)} = \left [ 
\begin{array}{cccc}
i_{0,1}^{(b)} & i_{0,2}^{(b)} & \ldots & i_{0,N_b}^{(b)} \\
i_{1,1}^{(b)} & i_{1,2}^{(b)} & \ldots & i_{1,N_b}^{(b)} \\
i_{2,1}^{(b)} & i_{2,2}^{(b)} & \ldots & i_{2,N_b}^{(b)} \\
\vdots & \vdots & \ddots & \vdots \\
i_{T_b,1}^{(b)} & i_{T_b,2}^{(b)} & \ldots & i_{T_b,N_b}^{(b)} \\
\end{array} 
\right ] = \left ( i_{t, x}^{(b)} \right ) \in \mathbb{R}^{(T_b+1) \times N_b}$$
	
	
Donde $t$ y $x$ indexan las observaciones temporales y los gastos, respectivamente. $T_b$ representa el número total de observaciones para la base $b$, y $N_b$ el número total de gastos básicos de la base $b$.
	Finalmente, notar que $i_{0,x}^{(b)}$ representa el índice de precios base del gasto básico $x$. Así, $i_{0,x}^{(b)} = 100 \;\forall\, x \in \lbrace 1, 2, \ldots, N_b \rbrace$. 
"""

# ╔═╡ 3d5c920b-964d-4755-8867-96bddbe5d83d
capitalize(gt00.v)

# ╔═╡ e1387332-9b1e-4358-8fac-1de63a7f1e92
md"""
Para la base 2000 del IPC, $T_b = 120$ y $N_b = 218$. El período de observaciones de índices de precios está comprendido desde enero de 2001 hasta diciembre de 2010 y hay un total de 218 gastos básicos considerados en el cálculo del IPC. Por otro lado, para la base 2010 del IPC, $T_b$ es variable y $N_b = 279$. 

En la base 2010 del IPC, el período de observaciones de índices de precios está comprendido desde enero de 2011, hasta la fecha, y además, hay un total de 279 gastos básicos considerados en el cálculo del IPC. Como referencia, $T_b = 120$ en diciembre de 2020 y así sucesivamente, hasta la fecha actual.
"""

# ╔═╡ e083e30b-b6c9-4655-90f6-a7ac5f71704b
md"""

## Variaciones intermensuales

Sea $V_b$ la matriz de variaciones intermensuales de índices de precios de cada uno de los gastos básicos de la base $b$. 
	
$$V^{(b)} = \left [
\begin{array}{cccc}
v_{1,1}^{(b)} & v_{1,2}^{(b)} & \ldots & v_{1,N_b}^{(b)} \\
v_{2,1}^{(b)} & v_{2,2}^{(b)} & \ldots & v_{2,N_b}^{(b)} \\
\vdots & \vdots & \ddots & \vdots \\
v_{T_b,1}^{(b)} & v_{T_b,2}^{(b)} & \ldots & v_{T_b,N_b}^{(b)} \\
\end{array} 
\right ] = \left ( v_{t,x}^{(b)} \right ) \in {\mathbb{R}}^{T_b \times N_b}$$
	
Donde $v_{t,x}^{(b)}$ es la variación intermensual del gasto básico $x$ en el mes $t$, expresada como porcentaje. Cada variación intermensual $v_{t,x}^{(b)}$ se computa a partir del cambio porcentual en el índice de precios del gasto básico $x$, respecto al período anterior, obtenido de la matriz $IPC^{(b)}$ como sigue: 

$$v_{t,x}^{(b)} = 100 \left ( \frac{i_{t,x}^{(b)} - i_{t-1,x}^{(b)}}{i_{t-1,x}^{(b)}} \right ), \quad t = 1, 2, \ldots, T_b \, ; \, x = 1, 2, \ldots, N_b$$ 
"""

# ╔═╡ 605481ae-77ee-4628-a19c-324307ae5eac
gt00.v

# ╔═╡ 3ceec3c2-3bac-4276-8bb7-072c433fe61a
md"""
## Ponderaciones

Cada uno de los gastos básicos en la matriz de índice de precios $IPC^{(b)}$ posee una ponderación que sirve para computar el IPC como un promedio ponderado de los índice de precios de los gastos básicos.

Sea $W^{(b)}$ el vector fila de ponderaciones correspondientes a cada uno de los gastos básicos de la matriz de índice de precios $IPC^{(b)}$. El vector está conformado como sigue: 

$$W^{(b)} = \left[ 
\begin{array}{cccc}
w^{(b)}_1 & w^{(b)}_2 & \ldots & w^{(b)}_{N_b} \\
\end{array}
\right]$$ 

donde la suma de todas las ponderaciones es igual a 1, esto es: $$\sum_{x} w^{(b)}_x = 1$$
"""

# ╔═╡ ebd08f30-0617-4ff7-b07c-da446bb2745d
gt10.w

# ╔═╡ ab127c7b-e1d4-4b92-aad7-6790bbfabb99
size(gt10.w)

# ╔═╡ 7c894360-bae4-4827-b26b-536d05f15338
sum(gt10.w)

# ╔═╡ ead7a6c4-c632-41e2-beb4-8ee1303fca74
md"""
## Ventanas mensuales

Para llevar a cabo el cómputo de inflación intermensual, considere la "ventana" o muestra pequeña de variaciones intermensuales. 

Sea $V^{(b)}_{t}$ la ventana mensual de variaciones intermensuales de índices de precios de la base $b$ en el período $t$, representada como un vector fila y obtenida como una submatriz de $1 \times N_b$ de la matriz de variaciones $V^{(b)}$: 
	
$$V^{(b)}_{t} = V^{(b)}\left [t; 1,2,\;\ldots\;,N_b \right ] = \left ( v_{t,x}^{(b)} \right ) \in {\mathbb{R}}^{1 \times N_b}$$
	
en donde $t$ representa la fila de la matriz de variaciones $V^{(b)}$, tomando todos los gastos básicos de la matriz, es decir, las columnas $1, 2, \ldots, N_b$.
"""

# ╔═╡ 6f57de61-45b4-49e4-b189-d825a887604a
gt00.v[1, :]

# ╔═╡ 11c25418-b567-4c9f-ada2-c0da447c8fb5
md"""
## Grilla de variaciones intermensuales

- Las variaciones intermensuales de índices de precios son tratadas como una variable aleatoria discreta,        
- Se construyen diferentes funciones muestrales de densidad de ponderaciones u ocurrencias.
- La grilla de variaciones intermensuales representa el conjunto de dominio de dichas funciones de densidad muestrales.
- Para construir la grilla se utiliza una variable de precisión $\varepsilon$ que define la distancia entre los elementos de la grilla. Típicamente, $\varepsilon = 10^{-2} = 0.01$. 

Nota: 
- *Debido a que las variaciones intermensuales están expresadas en porcentajes, estas son registradas con precisión de hasta $10^{-4}$*.
- *Históricamente, las variaciones intermensuales observadas en Guatemala desde el año 2001 se encuentran en un rango de $\left[ -100\%, 100\% \right]$. Es decir, no se ha observado hasta la fecha que ninguno de los gastos básicos haya duplicado su índice de precios, ni que este haya caído drásticamente hacia cero, de un mes a otro*.
"""

# ╔═╡ 5ecd2dfc-8630-45c1-b10c-fd447c108a06
md"""
Para las definiciones presentadas más adelante, considere el conjunto de variaciones intermensuales con precisión $\varepsilon$:

$$\begin{array}{c}%
V_\varepsilon = \left\lbrace v_i \;|\; v_i \in \left[-200, 200\right]; i \in \left\lbrace 1,2,\ldots, n \right\rbrace; \right.\\%
\left. v_1 = -200; (v_i-v_{i-1}) = \varepsilon \quad\forall i \geq 2 \right\rbrace \\%
\end{array}$$

donde el número de elementos $n$ del conjunto está dado por 

$$n = \frac{400}{\varepsilon} + 1$$

Además, considere el vector de grilla de variaciones intermensuales $v_{\varepsilon}$ como un vector fila con los elementos de $V_{\varepsilon}$ ordenados ascendentemente, como se describe a continuación:
   
$$v_{\varepsilon} = \left[ 
\begin{array}{ccccc}
-200 & (-200+\varepsilon) & (-200+2\varepsilon) &\ldots & 200 \\
\end{array} 
\right]$$
"""

# ╔═╡ 84804321-007b-45b6-a639-7e014a8eb94f
V

# ╔═╡ b45d7991-7384-4af9-81c8-de6ac76b84c6
collect(V)

# ╔═╡ 8b493fe6-a3c8-4c4d-9cf0-8ed09eb51a14
md"""
Por ejemplo, con $\varepsilon = 10^{-2}$, el vector de grilla de variaciones es:

$$V_{0.01} = \left[ 
\begin{array}{cccccccccc}
-200.00 & -199.99 & \ldots & -0.01 & 0.00 & 0.01 & \ldots & 199.99 & 200.00 \\
\end{array} 
\right]$$

¿Cuál es el número de posiciones en la grilla?
"""

# ╔═╡ 4dfb444e-fb89-4d0b-bf08-fd848fed318c
md"""
## Cálculo de posiciones en la grilla

- La grilla de variaciones está indexada desde posición $1$, hasta la posición $n$, como se definió anteriormente. 

- La primera posición corresponde a la variación intermensual $-200$, y la posición $n$ a la variación $200$, es decir, $\mathtt{pos}(-200) = 1$ y $\mathtt{pos}(200) = n$.
- En algunos cálculos, es necesario conocer qué posición corresponde a una determinada variación intermensual en el vector de grilla. 

"""

# ╔═╡ 5dbf0091-a34e-4c9d-859e-3a440193cf2b
md"""
- Para esto se utiliza la siguiente ecuación: 
$$\mathtt{pos}(v) = \mathtt{pos}(0) + \left\lfloor \frac{v}{\varepsilon} \right\rceil \qquad \forall \, v \in \left [ -200, 200 \right ]$$

donde $\mathtt{pos}(0)$ representa la posición de la variación cero, calculada como 

$$\mathtt{pos}(0) = \frac{200}{\varepsilon} + 1$$

y $\lfloor \cdot \rceil$ es la función de *entero próximo*.

Como $\lfloor \frac{v}{\varepsilon} \rceil$ mantiene el signo de $v$, para computar la posición de una variación intermensual se suma o resta la posición relativa de $v$ a la posición de la variación cero, dando como resultado la posición absoluta de la variación intermensual $v$, comprendida entre $1$ y $n$. La función de entero próximo se implementa en Julia utilizando `vposition(v, vspace)` en donde `vspace` representa la grilla de variaciones.

"""

# ╔═╡ d7dd2148-de33-45f8-b765-08ff5197678e
md"""
Como ejemplo: con una precisión de $\varepsilon = 10^{-2}$ se tiene una grilla de $40001$ elementos. Si se desea calcular la posición de la variación intermensual $v= -0.130892$ entonces se procede como sigue: 

$$\mathtt{pos}(0) = \frac{200}{0.01} + 1 = 20001$$

Luego: 

$$\mathtt{pos}(v) = \mathtt{pos}(0) + \left\lfloor \frac{-0.130892}{0.01} \right\rceil = 20001 - 13 = 19988$$
"""

# ╔═╡ 187e4642-2e95-4eb8-bc19-7620bf002b2c
vposition

# ╔═╡ b0a34f54-7369-47d5-b1be-3bcd06b2799a
round(Int, -0.130892 / 0.01) 

# ╔═╡ de137105-52b0-4b45-8a2b-81754757871a
vposition(-0.130892, V)

# ╔═╡ e6a87aec-ce7a-4a52-90ac-a86e69a23efa
md"""
# Distribuciones muestrales de variaciones intermensuales

Para llevar a cabo el cómputo de inflación MAI se utilizan las siguientes distribuciones de variaciones intermensuales de índices de precios:
    
- Distribución ponderada de variaciones intermensuales ($g_t$).
- Distribución de frecuencias de ocurrencia de variaciones intermensuales ($f_t$).
"""

# ╔═╡ 2221671b-7a6e-4dba-b7dc-80e271a5ed28
md"""
## Distribución $g_t$

- Consiste en una función discreta, definida sobre $V_\varepsilon$ y se construye a partir de la ocurrencia de las variaciones intermensuales de índices de precios, utilizando las ponderaciones de los gastos básicos en el IPC y puede interpretarse como una función de densidad de ocurrencia de los valores observados: 

$$g_{t}(v) : V_\varepsilon \rightarrow \left[0,1\right]$$

y a la vez, la suma de la densidad para todas las variaciones intermensuales es igual a 1, esto es:  

$$\sum_{v_i \in V_{\varepsilon}} g_{t}(v_i) = 1$$

- Se representa utilizando un vector disperso, con la misma dimensión que el vector de grilla.

- Para su construcción, utilizamos una ventana mensual de variaciones intermensuales $V^{(b)}_t$ y el vector de ponderaciones $W^{(b)}$ correspondiente.
"""

# ╔═╡ 99f469f5-5152-4799-a9d2-9ed77e4c57c0
md"""
### Algoritmo 

Para construir la función de densidad $g_t$ utilizamos el tipo `WeightsDistr`
"""

# ╔═╡ 8908cb22-7e0a-4a0d-86c2-af02470eab40
g = WeightsDistr(gt00.v[1, :], gt00.w, V)

# ╔═╡ 416e4983-035f-4185-b28c-d28be1b10cae
plot(g, xlims=(-7, 7))

# ╔═╡ 0b6f340f-5007-4351-bcd8-4f280880cf16
Dump(g)

# ╔═╡ b1974f1f-f6e1-41f3-8e79-66bc1662de6a
md"""
### Interpretación 

- Si $g_t$ se interpreta como la función muestral de densidad de ocurrencia de las variaciones intermensuales $v_{t,x}$ correspondientes a cualquier ventana $V^{(b)}_t$ de un período en particular, entonces su promedio ponderado:  

$$E(v^{(b)}_t) = g_t\,v_\varepsilon^\prime = \sum_{v_i \in V_{\varepsilon}} v_i\,g_{t}(v_i) = \sum_x w^{(b)}_x v^{(b)}_{t,x} = \mathrm{MPm}^{(b)}_t$$

En el período $t$, $E(v^{(b)}_t)$ es exactamente la media ponderada (MPm) de las variaciones intermensuales del período $t$.

- Esta media ponderada también se puede computar como el producto escalar entre el vector con la función de densidad $g_t$ y el vector de grilla de variaciones intermensuales $V_\varepsilon$.
"""

# ╔═╡ 4a93d0d0-7b13-4220-b076-32a157606c40
md"""
## Distribución $f_t$

- La función de densidad $f_{t}: V_{\varepsilon} \rightarrow \left[0,1\right]$ se construye de forma similar a la función de densidad $g_t$.

- Se consideran idénticas todas las ponderaciones de los gastos básicos correspondientes a las variaciones intermensuales.

- Esta función de densidad se puede interpretar como una función de densidad de ocurrencia de observaciones de variaciones intermensuales.

	
- Para su cómputo, considere el algoritmo utilizado para la distribución $g_t$, considerando las ponderaciones como $w^{(b)}_{x} = 1 / N_b$.
		
- Su construcción sea equivalente a la de obtener un histograma de frecuencias normalizado de las variaciones intermensuales de índices de precios en una ventana o período.
"""

# ╔═╡ 2e2ecd5a-bfda-4b37-b26e-12293831740e
md"""
### Algoritmo 

Para construir la función de densidad $f_t$ utilizamos el tipo `ObservationsDistr`
"""

# ╔═╡ a2fca38f-8519-4956-872e-8d744ebf4d92
f = ObservationsDistr(gt00.v[1, :], V)

# ╔═╡ 640e9426-996a-4fac-8de4-36daacd0f5ac
plot(f, xlims=(-7, 7))

# ╔═╡ 2e28138e-b50d-4345-9e7d-ab9a5804e073
Dump(f)

# ╔═╡ ad923e3b-92ff-4670-9dd5-25022e54df85
Ft = cumsum(f) 

# ╔═╡ 341c042d-e622-41e4-93be-62472a27efb8
plot(Ft, xlims=(-2,7)) 

# ╔═╡ 7652d811-ca5e-43ff-ae0b-ede97c7c6986
md"""
### Interpretación 

- Si la función $f_t$ se interpreta como la función muestral de densidad de probabilidad de las variaciones intermensuales, entonces su valor esperado es: 

$$E(v^{(b)}_t) = f_t\,v_\varepsilon^\prime = \sum_{v_i \in V_{\varepsilon}} v_i\,f_{t}(v_i) = \frac{1}{N_b} \sum_x v^{(b)}_{t,x} = \mathrm{MEm}^{(b)}_t$$

El promedio ponderado de las variaciones intermensuales $E(v^{(b)}_t)$ en el período $t$ es exactamente la media equiponderada (MEm) de las mismas.
- Esta media también se puede computar como el producto escalar entre el vector con la función de densidad $f_t$ y el vector de grilla de variaciones intermensuales $v_\varepsilon$.

"""

# ╔═╡ 342e77e1-a763-48f8-9f83-2e4396db6656
md"""
## Distribución g de largo plazo (*glp*)

- Se construye de forma similar a la función de densidad $g_t$, considerando las ocurrencias observadas históricamente. 

- Se incluyen solamente **años completos** en la historia.

- Puede considerarse un reflejo del comportamiento histórico de las variaciones intermensuales de los índices de precios de los gastos básicos en Guatemala y por lo tanto, **no se encuentra asociada a un período en particular**.
	
- La función de densidad *glp* se conforma utilizando todas las variaciones intermensuales de las bases 2000 y 2010 del IPC. 

- Considere que es posible construir una sola "ventana" $V^{*}$ que contenga todas las variaciones intermensuales de las bases del IPC 2000 y 2010, cuyas ponderaciones asociadas sean $W^{*}$.

- La función *glp* se construye utilizando el algoritmo de la distribución $g_t$, *mutatis mutandis*, con la ventana $V^{*}$ y el vector $W^{*}$ como entradas. 

Mostrar en Julia su construcción y una gráfica de cómo se ve la distribución de largo plazo.
"""

# ╔═╡ f71f0d24-8236-4a12-80d1-738e53ea0e12
begin
	all_v = vcat(gt00.v[:], gt10.v[1:120, :][:])
	all_w = vcat(repeat(gt00.w', 120)[:], repeat(gt10.w', 120)[:])
	glp = WeightsDistr(all_v, all_w, V)
end

# ╔═╡ cc80b7f9-ecb3-442e-a4cb-aa59d71ece26
# with_terminal() do 
# 	println(glp)
# end

# ╔═╡ eae96716-47ae-410e-adbc-bc863b9832c9
plot(glp, xlims=(-1,2), seriestype=:bar, linealpha=0, label = "glp")

# ╔═╡ d591df05-1ac3-4081-9261-ef9ffb7c66d3
glp(0)

# ╔═╡ 7a3b0421-5d0a-47e3-8de8-0557979f3975
md"""

De forma similar con la función $g_t$, si la función $\mathrm{glp}(v)$ se interpreta como la función muestral de densidad de probabilidad de las variaciones intermensuales $v_{t,x}$ correspondientes a la ventana $V^{*}$ que contiene el histórico de variaciones intermensuales, entonces su valor esperado $E(v)$ es exactamente el promedio de la medias ponderadas en todos los períodos de la ventana $V^{*}$.

- Al utilizar una ventana $V^{*}$ de observaciones históricas, su valor esperado $E(v)$ es exactamente el promedio de la medias ponderadas (MPm) en todos los períodos de la ventana $V^{*}$.
$$\begin{split}
E(v) & = glp\cdot v_\varepsilon^\prime = \sum_{v_i \in V_{\varepsilon}} v_i\,glp(v_i) \\
& = \frac{1}{T_{2000} + T^*_{2010}} \sum_{b}\sum_{t=1}^{T_b}\sum_x w^{(b)}_x v^{(b)}_{t,x} \\
& = \frac{1}{T_{2000} + T^*_{2010}} \sum_{b}\sum_{t=1}^{T_b}\mathrm{MPm}^{(b)}_t
\end{split}$$

"""

# ╔═╡ e33f1222-8f29-4591-9db9-dee8938a306f
mean(glp)

# ╔═╡ 2d0aa4be-31d6-4712-b169-2ef25fa4afc2
begin
	mpm0 = gt00.v * gt00.w / 100
	mpm1 = gt10.v * gt10.w / 100
	mpm = vcat(mpm0, mpm1)
	mean(mpm)
end

# ╔═╡ 8251b8fb-f975-45bf-bf74-7a1f037c6c13
md"""
### Distribución acumulada
"""

# ╔═╡ 7f79d6a1-9e3a-4b8e-8478-bf1bc9257241
GLP = cumsum(glp) 

# ╔═╡ 8bb62d79-96f2-4e54-b834-4cef0256c8f4
plot(GLP, xlims=(-2,5))

# ╔═╡ 37d28a04-b2dc-4402-9bec-56ecc27b5550
md"""
## Distribución f de largo plazo (*flp*)

- Similar a la función de densidad $f_t$, pero considera ocurrencias de variaciones intermensuales observadas históricamente y no toma en cuenta las ponderaciones de las variaciones intermensuales en su construcción.

- Similar a la función de densidad *glp*, considera años completos en su cómputo.

- También puede considerarse un reflejo del comportamiento histórico de las variaciones intermensuales en Guatemala.

- Se obtiene el histograma normalizado de variaciones intermensuales de índices de precios de la base 2000 y 2010 del IPC.

- También sería posible, utilizar el algoritmo de la función $g_t$ con ponderaciones $w^{(b)}_{x} = 1 / N_b$ en cada una de las bases y utilizando una sola ventana $V^{*}$ con todas las variaciones intermensuales.

Mostrar una gráfica de cómo se ve la distribución fat en MATLAB.
"""

# ╔═╡ 87b845e0-e778-4ac3-ac4f-f9e2252ea20c
flp = ObservationsDistr(all_v, V)

# ╔═╡ f7e63c15-11aa-4aa7-946f-d489c700df7f
# with_terminal() do 
# 	println(flp)
# end

# ╔═╡ a3bac26b-10a5-451a-82c2-2b730aef9346
plot(flp, xlims=(-1,2), seriestype=:bar, linealpha=0)

# ╔═╡ 9170753e-b5a3-4ee2-8e0d-b343c316a74c
flp(0)

# ╔═╡ 670c5227-49ed-479f-9fa4-0ad97f87a05c
md"""

- Si la función *flp* se interpreta como la función muestral de densidad de probabilidad de las variaciones intermensuales $v_{t,x}$ correspondientes a la ventana $V^{*}$, entonces su valor esperado es el promedio de todas las $\mathrm{MEm}$.
$$\begin{split}
E(v) & = flp\cdot v_\varepsilon^\prime = \sum_{v_i \in V_{\varepsilon}} v_i\,flp(v_i) \\
& = \frac{1}{T_{2000} + T^*_{2010}} \sum_{b}\sum_{t=1}^{T_b}\sum_x (1/N_b) \, v^{(b)}_{t,x} \\
& = \frac{1}{T_{2000} + T^*_{2010}} \sum_{b}\sum_{t=1}^{T_b}\mathrm{MEm}^{(b)}_t
\end{split}$$
entonces su valor esperado $E(v)$ es exactamente el promedio de la medias equiponderadas en todos los períodos de la ventana $V^{*}$. Este promedio también se puede computar como el producto escalar entre el vector con la función de densidad *flp* y el vector de grilla de variaciones intermensuales $v_\varepsilon$.
"""

# ╔═╡ 4a7870fb-9be4-4f72-a54e-1d144f5794b2
mean(flp)

# ╔═╡ 490d77ff-3c79-4cfd-85c9-9d7688be9291
mean(all_v)

# ╔═╡ 90c5a65b-d3a6-4d60-9953-81e718524548
md"""
### Distribución acumulada
"""

# ╔═╡ 3b73f01d-ef58-4a45-8eac-1c1b8ad4c4bb
FLP = cumsum(flp) 

# ╔═╡ df737c62-2754-46e0-818e-2b365c6c906b
plot(FLP, xlims=(-2,5))

# ╔═╡ 4bccbf09-7a05-444d-aa60-7ff3766748e8
md"""
## Comparación de distribuciones de largo plazo
"""

# ╔═╡ 7c755659-4209-4714-936e-28a6d8965669
begin
	plot(FLP, xlims=(-2,5), label="FLP")
	plot!(GLP, xlims=(-2,5), label="GLP")
end

# ╔═╡ 5ee20275-eecf-4738-a018-f96024bf6ba6
md"""
## Percentiles de las distribuciones

- La inflación subyacente MAI se computa utilizando diferentes percentiles de las distribuciones $f_t$ y $g_t$, así como los percentiles de las distribuciones *flp* y *glp*. 

- En particular, es posible computar una inflación intermensual $\mathrm{MAI}_{i}$, representada por $\bar{v}_{\mathrm{MAI}, t}^{(i)}$, utilizando $i$ segmentos de las distribuciones de variaciones intermensuales de cada mes, de acuerdo con la definición siguiente.

"""

# ╔═╡ 8be9921e-4535-4cf8-b6f3-5939dbd37598
md"""
### Percentil próximo

Sea $q_{y,k}^{(i)}$ el percentil $(k/i)$ de la función de densidad $\mathbf{y}$ de variaciones intermensuales, en el cual $k = 0, 1, \ldots, i$ representa el número de percentil, e $i$ el número de segmentos en que se particiona el vector $\mathbf{y}$. Dicho percentil verifica que en la función de densidad acumulada $\mathbf{Y}$, obtenida a partir de $\mathbf{y}$, se acumule una densidad aproximada a $(k/i)$, correspondiente  un percentil teórico, de tal forma que:

$$q_{y,k}^{(i)}  \triangleq \arg\min_{v_j \in V_\varepsilon} |\mathbf{Y}(v_j) - k/i|$$


"""

# ╔═╡ 272d4be4-33af-44df-a313-befb89cb4515
md"""
### Implementación
"""

# ╔═╡ e0047781-6cb3-4cee-a894-78acc5f33fb5
which(quantile, (AccumulatedDistr, Real))

# ╔═╡ 88acf18f-7709-4ba0-b6bf-da77f032dedd
quantile(FLP, 0.5) 

# ╔═╡ 99dd9a8f-2266-4ab9-94d9-61043811fabd
quantile(FLP, 0:0.2:1)

# ╔═╡ 39f116e8-e5c1-439b-9cf9-f15a50d15cb6
md"""

- Note que $q_{y,0}^{(i)}$ representa el percentil $0$, que corresponde a la mínima variación intermensual en el dominio de la función de densidad $\mathbf{y}$. 

- En la función de densidad acumulada $\mathbf{Y}$, permiten que$$Y \left( q_{y,0}^{(i)} \right) = 0, \quad Y \left( q_{y,i}^{(i)} \right) = 1,$$

- En Julia, extendemos el método `Statistics.quantile`.
"""

# ╔═╡ c215620e-a5ea-47bd-b49b-8d8d89ed659c
md"""
# Cómputo de inflación MAI

- La inflación subyacente MAI se obtiene a través de un proceso estadístico que involucra a las distribuciones $f_t$ y $g_t$, así como a las distribuciones de largo plazo *flp* y *glp*.

- Dicho proceso permite reponderar las variaciones intermensuales de un determinado período, tomando en cuenta la baja ocurrencia histórica de los valores extremos.
		
- De esta manera, suaviza variaciones intermensuales asociadas a una ventana, obteniendo una versión suavizada (filtrada) del ritmo inflacionario.

"""

# ╔═╡ 8446f083-253a-4e1e-9ad4-58932d4ca102
md"""
- El cómputo utiliza como *parámetro* el número de percentiles $i$ de las distribuciones muestrales $f_t$ y $g_t$. Así como la distribución, o posiciones, de los percentiles también podrían considerarse hiperparámetros.


- La inflación intermensual $\mathrm{MAI}_{i}$, representada por $\bar{v}_{\mathrm{MAI}, t}^{(i)}$, divide las distribuciones $f_t$ y $g_t$ en $i$ segmentos, indicados por los percentiles $q_{f_{t},k}^{(i)}$ y $q_{g_{t},k}^{(i)}$, definidos anteriormente.


- Por ejemplo, la inflación intermensual $\bar{v}_{\mathrm{MAI}, t}^{(4)}$ se obtiene a través de los cuartiles de las distribuciones de las distribuciones $f_t$ y $g_t$, así como de las distribuciones de largo plazo. 
"""

# ╔═╡ 62076d20-0fa4-42ed-97cb-a4b693074786
md"""
- En cada período, la inflación intermensual $\mathrm{MAI}_{i}$ se obtiene como:

$$\bar{v}_{\mathrm{MAI}, t}^{(i)} = (1-\alpha)\,\bar{v}_{\mathrm{MAI}, f,t}^{(i)} + \alpha\,\bar{v}_{\mathrm{MAI}, f,t}^{(i)}$$
		
- El componente $\bar{v}_{\mathrm{MAI}, f,t}^{(i)}$ se obtiene a través de la distribución $f_t$ normalizada con las distribuciones LP.
		
- El componente $\bar{v}_{\mathrm{MAI}, g,t}^{(i)}$ se obtiene a través de la distribución $g_t$ normalizada con las distribuciones LP.
		
- Actualmente, $\alpha = \frac{1}{2}$ e $i \in \left\lbrace 4,5,10,20,40\right\rbrace$.
		
Es decir, actualmente es un promedio simple de las medidas basadas en cuartiles, quintiles, deciles, en porciones de densidad del $5\%$ y en porciones de densidad del $2.5\%$.
"""

# ╔═╡ 1b4b4ccf-2c66-4699-be6f-5be9900ba354
md"""
- Es posible computar la inflación MAI en versión interanual, actualizando un índice de base mensual y obteniendo la variación interanual: %

$$\begin{split}
\pi_{\mathrm{MAI}, t} = & \frac{I_{\mathrm{MAI},t} - I_{\mathrm{MAI},t-1}}{I_{\mathrm{MAI},t-1}} \\
= & \prod_{j=t-11}^{t} \left(1 + \bar{v}_{\mathrm{MAI}, j}\right)  - 1
\end{split}$$

"""

# ╔═╡ d6d13501-4b14-40e4-bcb3-1c16843eef20
md"""
## Inflación intermensual MAI-G

- Se obtiene como un promedio ponderado de la función de densidad de largo plazo *glp* renormalizada. 
		
- A partir de la imposición de los $i$ percentiles de la función de densidad $g_t$ del mes $t$.
		
- A la función de densidad *glp* renormalizada la llamaremos $glp_{t}$.
		
- Esta función de densidad de las variaciones intermensuales será proporcional, por segmentos, a la distribución de largo plazo *glp* y será consistente con las condiciones inflacionarias representadas por los percentiles de la función de densidad $g_t$.
		
- Los percentiles caracterizan el posicionamiento de la distribución de las variaciones intermensuales de precios del mes $t$.
		
Los percentiles caracterizan el posicionamiento de la distribución de las variaciones intermensuales de precios del mes $t$, sin verse fuertemente afectados por los valores atípicamente extremos que tienen una influencia excesiva en las distribuciones mensuales de variaciones intermensuales de precios $f_t$ y $g_t$, debido a que estas se generan a partir de muestras relativamente pequeñas.
"""

# ╔═╡ 4e9d615c-f16d-42d7-a798-b95156a28559
md"""
La proporcionalidad de $glp_{t}$ respecto a *glp* implica que los valores atípicamente extremos no tienen ponderaciones desproporcionadas, propias de su ocurrencia en muestras pequeñas.

Por el contrario, tienen más bien ponderaciones consistentes con su frecuencia de ocurrencia de largo plazo. Es decir, sus ponderaciones son consistentes con su frecuencia de ocurrencia en una muestra grande, y por lo tanto, tienen efectos moderados sobre la medición de inflación resultante.

Por lo tanto, $glp_{t}$ es: 

- Consistente con las condiciones inflacionarias prevalecientes del período $t$.

- Y a la vez, es consistente con una muestra grande de observaciones de variaciones intermensuales.
"""

# ╔═╡ 2b78811f-d59e-4ac3-9dee-a0c07cb44731
md"""
### Algoritmo de cómputo

**Paso 1.** De los $i$ percentiles en la distribución *glp*, se deben encontrar los dos que rodean la variación intermensual cero.
		
- Sean $q_{glp, \underline{k}}^{(i)}$ y $q_{glp, \overline{k}}^{(i)}$ los percentiles más cercanos a la variación cero.
		
- Formalmente:
$$\begin{split}
\underline{k} = & \arg\max_k \,q_{glp,k}^{(i)} \,, \quad \text{sujeto a} \quad q_{glp,k}^{(i)} < 0 \\
\overline{k} = & \arg\min_k \,q_{glp,k}^{(i)} \,, \quad \text{sujeto a} \quad q_{glp,k}^{(i)} > 0
\end{split}$$ 
"""

# ╔═╡ afdbff35-7d0d-4d48-bcb5-66e422352d2c
md"""
**Paso 2.** En la función de densidad $g_{t}$ del período $t$, se deben encontrar también los percentiles que rodean a la variación intermensual cero.
		
- Sean $q_{g_{t}, \underline{s}}^{(i)}$ y $q_{g_{t}, \overline{s}}^{(i)}$ los percentiles más cercanos a cero.
		
- De tal forma que:
$$\begin{split}
\underline{s} = & \arg\max_s \,q_{g_{t},s}^{(i)} \,, \quad \text{sujeto a} \quad q_{g_{t},s}^{(i)} < 0 \\
\overline{s} = & \arg\min_s \,q_{g_{t},s}^{(i)} \,, \quad \text{sujeto a} \quad q_{g_{t},s}^{(i)} > 0
\end{split}$$
"""

# ╔═╡ 2d7fc594-f3ca-4fc4-8b20-efd5d5925ff9
md"""
**Paso 3.** Para el proceso de normalización de *glp* utilizando los  percentiles de $g_{t}$ se deben considerar el mismo número de segmentos. 
	
- Por lo que se define un segmento especial que rodea a la variación cero, con números de percentiles $\overline{r}$ y $\underline{r}$, dados por:
$$\begin{split}
\overline{r} = & \max \left\lbrace \overline{k}, \overline{s} \right\rbrace \\
\underline{r} = & \min \left\lbrace \underline{k}, \underline{s} \right\rbrace
\end{split}$$
"""

# ╔═╡ b2744061-113e-4348-b7bb-efcc0bb01de8
md"""
**Paso 4.** Ahora se definirá un conjunto de segmentos sobre los cuales se debe aplicar una constante de proporcionalidad (o escalamiento) para obtener la función de densidad $glp_{t}$.
	
- Considere el conjunto de segmentos $I = \left\lbrace0, 1, \ldots, \underline{r}, \ldots, \overline{r}, \ldots, i\right\rbrace$. 
- Y sea el conjunto de segmentos contenidos en el segmento especial $R = \left\lbrace \underline{r}+1, \ldots, \overline{r}-1 \right\rbrace$, definido alrededor de la variación intermensual cero.
		
- Entonces, el conjunto de segmentos a normalizar está dado por: $I-R = \left\lbrace0, 1, \ldots, \underline{r}, \overline{r}, \ldots, i\right\rbrace$. 
"""

# ╔═╡ 0fdf271c-b7ad-482f-affc-0845049c4f8f
md"""
**Paso 5.** Para todos los segmentos $k \in I-R$ (excepto para $k = 0$ o $k = \overline{r}$) la función de densidad $glp_{t}$ en el segmento $k$ estaría dada por:

$$glp_{t}(v) = glp\left(v\right) \, \frac{G_t\left(q_{g_{t}, k}^{\left(i\right)}\right) - G_t\left(q_{g_{t}, k-1}^{\left(i\right)}\right)}{GLP\left(q_{g_{t}, k}^{\left(i\right)}\right) - GLP\left(q_{g_{t}, k-1}^{\left(i\right)}\right)}, \quad q_{g_{t}, k-1}^{\left(i\right)} < v \leq q_{g_{t}, k}^{\left(i\right)}.$$ 

- En el segmento especial ($k = \overline{r}$), la normalización se hace sobre todo el segmento indicado por los percentiles $\underline{r}$ y $\overline{r}$:

$$glp_{t}(v) = glp\left(v\right) \, \frac{G_t\left(q_{g_{t}, \overline{r}}^{\left(i\right)}\right) - G_t\left(q_{g_{t}, \underline{r}}^{\left(i\right)}\right)}{GLP\left(q_{g_{t}, \overline{r}}^{\left(i\right)}\right) - GLP\left(q_{g_{t}, \underline{r}}^{\left(i\right)}\right)}, \quad q_{g_{t}, \underline{r}}^{\left(i\right)} < v \leq q_{g_{t}, \overline{r}}^{\left(i\right)}.$$

Note que en el primer y último segmento, las expresiones requerirán evaluar las funciones de densidad cuando $k=0$ y $k=i$, y por lo tanto, se debe garantizar que las funciones de densidad acumulada correspondan a la evaluación de los valores mínimo y máximo en el conjunto $V_\varepsilon$.
"""

# ╔═╡ 4d336858-d661-46f5-8927-c9901d2eef3f
md"""
**Paso 6.** La inflación intermensual $\mathrm{MAI}_{i,g}$ de $i$ segmentos está dada como el promedio ponderado de $glp_{t}$. Esto es:

$$\overline{v}_{\mathrm{MAI}, g, t}^{(i)} = glp_{t}\cdot v_\varepsilon^\prime = \sum_{v_i \in V_{\varepsilon}} v_i\,glp_{t}(v_i).$$

Como resultado de este proceso de normalización, los percentiles de la función de densidad de largo plazo normalizada son iguales a los de la función de densidad $g_t$, esto es: $q_{glp_{t}, k}^{(i)} = q_{g_{t}, k}^{(i)}$.
"""

# ╔═╡ 0edcdd2e-8b00-4c15-8076-8be69e83d1d4
md"""
## Inflación intermensual MAI-F

- Se obtiene como un promedio simple de la función de densidad de largo plazo *glp* renormalizada. 
		
- A partir de la imposición de los $i$ percentiles de la función de densidad $f_t$ del mes $t$.
		
- A la función de densidad *glp* renormalizada la llamaremos $flp_{t}$.
		
- Esta función de densidad de las variaciones intermensuales será proporcional, por segmentos, a la distribución de largo plazo *glp* y será consistente con las condiciones inflacionarias representadas por los percentiles de la función de densidad $g_t$.
		
- A pesar de que los percentiles utilizados para la imposición y renormalización provienen de las distribuciones $f_t$, se utiliza la función de densidad *glp* para obtener la $flp_{t}$ **debido a que esta considera las ponderaciones asociadas a los gastos básicos en el IPC**.
"""

# ╔═╡ f6b5ce08-4bb1-42ab-9272-42790b33704e
md"""
Nuevamente, la proporcionalidad de $flp_{t}$ respecto a *glp* implica que los valores atípicamente extremos no tienen ponderaciones desproporcionadas, propias de su ocurrencia en muestras pequeñas.

Por lo tanto, $flp_{t}$ es: 
		
- Consistente con las condiciones inflacionarias prevalecientes del período $t$ de acuerdo a los percentiles de ocurrencias.

- Y a la vez, es consistente con una muestra grande (de largo plazo) de observaciones de variaciones intermensuales.

"""

# ╔═╡ 4ebb2e7e-95c9-4ba5-a4f7-344f7f2e706c
md"""
### Algoritmo de cómputo

**Paso 1.** De los $i$ percentiles en la distribución *glp*, se deben encontrar los dos que rodean la variación intermensual cero.
		
**Paso 2.** En la función de densidad $f_{t}$ del período $t$, se deben encontrar también los percentiles que rodean a la variación intermensual cero.$q_{f_{t}, \underline{s}}^{(i)}$ y $q_{f_{t}, \overline{s}}^{(i)}$. 
		 
**Paso 3.** Encontramos los números de percentiles comunes: $\overline{r}$ y $\underline{r}$.
	
**Paso 4.** Definimos el conjunto de segmentos $I-R$ sobre los cuales normalizar.

"""

# ╔═╡ 957b95ff-6a71-4fc0-84c7-ef26a25cf51f
md"""
**Paso 5.** Renormalizar todos los segmentos indicados por el conjunto $I-R$.
	
- Para todos los segmentos $k \in I-R$ (excepto para $k = 0$ o $k = \overline{r}$) la función de densidad $flp_{t}$ en el segmento $k$ estaría dada por:
$$flp_{t}(v) =   glp\left(v\right) \, \frac{GLP\left(q_{flp, k}^{\left(i\right)}\right) - GLP\left(q_{flp, k-1}^{\left(i\right)}\right)}{GLP\left(q_{f_{t}, k}^{\left(i\right)}\right) - GLP\left(q_{f_{t}, k-1}^{\left(i\right)}\right)}, \quad q_{f_{t}, k-1}^{\left(i\right)} < v \leq q_{f_{t}, k}^{\left(i\right)}.$$
- En el segmento especial, en el cual $k = \overline{r}$, la normalización se hace sobre todo el segmento indicado por los percentiles $\underline{r}$ y $\overline{r}$, esto es:

$$flp_{t}(v) =   glp\left(v\right) \, \frac{GLP\left(q_{flp, \overline{r}}^{\left(i\right)}\right) - GLP\left(q_{flp, \underline{r}}^{\left(i\right)}\right)}{GLP\left(q_{f_{t}, \overline{r}}^{\left(i\right)}\right) - GLP\left(q_{f_{t}, \underline{r}}^{\left(i\right)}\right)}, \quad q_{f_{t}, \underline{r}}^{\left(i\right)} < v \leq q_{f_{t}, \overline{r}}^{\left(i\right)}.$$

Note que en el primer y último segmento, las expresiones requerirán evaluar las funciones de densidad cuando $k=0$ y $k=i$, y por lo tanto, se debe garantizar que las funciones de densidad acumulada correspondan a la evaluación de los valores mínimo y máximo en el conjunto $V_\varepsilon$.
"""

# ╔═╡ 3e47548d-2cf9-4840-ba22-0e0c168f7851
md"""
En este caso, normalizar utilizando los percentiles de la distribución de ocurrencias $f_t$ y la función de densidad *glp*, permite que la densidad acumulada en la distribución normalizada $flp_{t}$ en el segmento $k$ sea la acumulada por la densidad acumulada $GLP$ en el segmento indicado por los percentiles de la función de densidad de ocurrencias de largo plazo, esto es:

$$FLP_t(q_{f_{t}, k}^{(i)}) - FLP_t(q_{f_{t}, k-1}^{(i)}) = GLP(q_{flp, k}^{(i)}) - GLP(q_{flp, k-1}^{(i)})$$
"""

# ╔═╡ c51b6e67-06ec-4e54-930c-5abc956bf237
md"""
## Discusión 

- Ventajas y desventajas del procedimiento expuesto.
		
- ¿Qué efecto podría tener computar la inflación subyacente MAI solamente con la base 2010 del IPC?
		
- Para llevar a cabo el cómputo, ¿sería posible utilizar percentiles no igualmente espaciados entre sí?
"""

# ╔═╡ a92aca49-9b7c-48f2-97c2-ba1e3d0aabaf


# ╔═╡ dcee00f6-c94a-4e9f-ba27-b61e09097bea
md"""
#### Funciones y utilidades

Se configuran opciones para mostrar este cuaderno. 
"""

# ╔═╡ Cell order:
# ╟─ec957b42-5a6f-46be-986d-e7b99cfda80d
# ╟─0f5e97c1-2125-4766-99fc-fda1f71bb391
# ╟─4b605b91-44df-49cf-8c0c-8566e30cc598
# ╟─928289db-c42e-4a55-bb04-bac4b33ae379
# ╟─137b9a66-66fb-467a-a3af-20572f5286c2
# ╟─1d59e61c-4cdf-43c6-970f-868beaeffe9b
# ╟─96e18948-5150-4193-bc93-b78daf87f067
# ╟─0d1bf735-062f-44d7-bd70-2c25f16e8f59
# ╟─535f144b-02fa-47b2-9990-9b8c033c42cb
# ╟─793cabab-c5d4-4ad3-bf22-fb1bef99aad1
# ╠═3d5c920b-964d-4755-8867-96bddbe5d83d
# ╟─e1387332-9b1e-4358-8fac-1de63a7f1e92
# ╟─e083e30b-b6c9-4655-90f6-a7ac5f71704b
# ╠═605481ae-77ee-4628-a19c-324307ae5eac
# ╟─3ceec3c2-3bac-4276-8bb7-072c433fe61a
# ╠═ebd08f30-0617-4ff7-b07c-da446bb2745d
# ╠═ab127c7b-e1d4-4b92-aad7-6790bbfabb99
# ╠═7c894360-bae4-4827-b26b-536d05f15338
# ╟─ead7a6c4-c632-41e2-beb4-8ee1303fca74
# ╠═6f57de61-45b4-49e4-b189-d825a887604a
# ╟─11c25418-b567-4c9f-ada2-c0da447c8fb5
# ╟─5ecd2dfc-8630-45c1-b10c-fd447c108a06
# ╠═84804321-007b-45b6-a639-7e014a8eb94f
# ╠═b45d7991-7384-4af9-81c8-de6ac76b84c6
# ╟─8b493fe6-a3c8-4c4d-9cf0-8ed09eb51a14
# ╟─4dfb444e-fb89-4d0b-bf08-fd848fed318c
# ╟─5dbf0091-a34e-4c9d-859e-3a440193cf2b
# ╟─d7dd2148-de33-45f8-b765-08ff5197678e
# ╠═187e4642-2e95-4eb8-bc19-7620bf002b2c
# ╠═b0a34f54-7369-47d5-b1be-3bcd06b2799a
# ╠═de137105-52b0-4b45-8a2b-81754757871a
# ╟─e6a87aec-ce7a-4a52-90ac-a86e69a23efa
# ╟─2221671b-7a6e-4dba-b7dc-80e271a5ed28
# ╟─99f469f5-5152-4799-a9d2-9ed77e4c57c0
# ╠═8908cb22-7e0a-4a0d-86c2-af02470eab40
# ╠═416e4983-035f-4185-b28c-d28be1b10cae
# ╠═0b6f340f-5007-4351-bcd8-4f280880cf16
# ╟─b1974f1f-f6e1-41f3-8e79-66bc1662de6a
# ╟─4a93d0d0-7b13-4220-b076-32a157606c40
# ╟─2e2ecd5a-bfda-4b37-b26e-12293831740e
# ╠═a2fca38f-8519-4956-872e-8d744ebf4d92
# ╠═640e9426-996a-4fac-8de4-36daacd0f5ac
# ╠═2e28138e-b50d-4345-9e7d-ab9a5804e073
# ╠═ad923e3b-92ff-4670-9dd5-25022e54df85
# ╠═341c042d-e622-41e4-93be-62472a27efb8
# ╟─7652d811-ca5e-43ff-ae0b-ede97c7c6986
# ╟─342e77e1-a763-48f8-9f83-2e4396db6656
# ╠═f71f0d24-8236-4a12-80d1-738e53ea0e12
# ╟─cc80b7f9-ecb3-442e-a4cb-aa59d71ece26
# ╠═eae96716-47ae-410e-adbc-bc863b9832c9
# ╠═d591df05-1ac3-4081-9261-ef9ffb7c66d3
# ╟─7a3b0421-5d0a-47e3-8de8-0557979f3975
# ╠═e33f1222-8f29-4591-9db9-dee8938a306f
# ╠═2d0aa4be-31d6-4712-b169-2ef25fa4afc2
# ╟─8251b8fb-f975-45bf-bf74-7a1f037c6c13
# ╠═7f79d6a1-9e3a-4b8e-8478-bf1bc9257241
# ╠═8bb62d79-96f2-4e54-b834-4cef0256c8f4
# ╟─37d28a04-b2dc-4402-9bec-56ecc27b5550
# ╠═87b845e0-e778-4ac3-ac4f-f9e2252ea20c
# ╟─f7e63c15-11aa-4aa7-946f-d489c700df7f
# ╠═a3bac26b-10a5-451a-82c2-2b730aef9346
# ╠═9170753e-b5a3-4ee2-8e0d-b343c316a74c
# ╟─670c5227-49ed-479f-9fa4-0ad97f87a05c
# ╠═4a7870fb-9be4-4f72-a54e-1d144f5794b2
# ╠═490d77ff-3c79-4cfd-85c9-9d7688be9291
# ╟─90c5a65b-d3a6-4d60-9953-81e718524548
# ╠═3b73f01d-ef58-4a45-8eac-1c1b8ad4c4bb
# ╠═df737c62-2754-46e0-818e-2b365c6c906b
# ╟─4bccbf09-7a05-444d-aa60-7ff3766748e8
# ╠═7c755659-4209-4714-936e-28a6d8965669
# ╟─5ee20275-eecf-4738-a018-f96024bf6ba6
# ╟─8be9921e-4535-4cf8-b6f3-5939dbd37598
# ╟─272d4be4-33af-44df-a313-befb89cb4515
# ╠═e0047781-6cb3-4cee-a894-78acc5f33fb5
# ╠═88acf18f-7709-4ba0-b6bf-da77f032dedd
# ╠═99dd9a8f-2266-4ab9-94d9-61043811fabd
# ╟─39f116e8-e5c1-439b-9cf9-f15a50d15cb6
# ╟─c215620e-a5ea-47bd-b49b-8d8d89ed659c
# ╟─8446f083-253a-4e1e-9ad4-58932d4ca102
# ╟─62076d20-0fa4-42ed-97cb-a4b693074786
# ╟─1b4b4ccf-2c66-4699-be6f-5be9900ba354
# ╟─d6d13501-4b14-40e4-bcb3-1c16843eef20
# ╟─4e9d615c-f16d-42d7-a798-b95156a28559
# ╟─2b78811f-d59e-4ac3-9dee-a0c07cb44731
# ╟─afdbff35-7d0d-4d48-bcb5-66e422352d2c
# ╟─2d7fc594-f3ca-4fc4-8b20-efd5d5925ff9
# ╟─b2744061-113e-4348-b7bb-efcc0bb01de8
# ╟─0fdf271c-b7ad-482f-affc-0845049c4f8f
# ╟─4d336858-d661-46f5-8927-c9901d2eef3f
# ╟─0edcdd2e-8b00-4c15-8076-8be69e83d1d4
# ╟─f6b5ce08-4bb1-42ab-9272-42790b33704e
# ╟─4ebb2e7e-95c9-4ba5-a4f7-344f7f2e706c
# ╟─957b95ff-6a71-4fc0-84c7-ef26a25cf51f
# ╟─3e47548d-2cf9-4840-ba22-0e0c168f7851
# ╟─c51b6e67-06ec-4e54-930c-5abc956bf237
# ╟─a92aca49-9b7c-48f2-97c2-ba1e3d0aabaf
# ╟─dcee00f6-c94a-4e9f-ba27-b61e09097bea
# ╠═d722fbf0-eb4f-11eb-2fef-b19a7566ba31
