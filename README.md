# AppleStockPrice
Objetivo: Observar la evolución del precio de apertura, cierre y volumen de operación de las acciones de Apple. Crecimiento histórico y visualización de cambios. 

## Tecnologías utilizadas
<img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTLJNzpWzLTK7VlJmOZrWCEpMPT1KdRiimk5A&s" width="150px">
<img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRVwFOtI815edmYmWMHV-CZsvZT1SJfAuDmBg&s" width="150px">
<img src="https://fundacionconfemetal.com/wp-content/uploads/elementor/thumbs/banner_excel_query-q8abhwo2j1bvkedr6mo38zo4kunpqloaar6zu1v0y0.jpg" width="150px">
<img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR2jMJHpxI-ZcDFBujrCfNGK9TlMho7HhnhFQ&s" width="150px">
<img src="https://i0.wp.com/www.rbasesoria-madrid.com/wp-content/uploads/2019/10/Power-BI.jpg?fit=826%2C527&ssl=1" width="150px">
<img src="https://capacitacion.uc.cl/images/cursos/Google_Sheets.jpg" width="150px">

# Desarrollo del proyecto
Se descarga el dataset Apple Stock Price Dataset con la extensión .csv para luego subirlo a SQL server y de allí realizar la conexión a power bi. 

### Transformación de datos en Power Query: 

Se agrega columna personalizada con el cálculo del porcentaje de variación entre el precio de cierre (close) del día con respecto al del día siguiente. Se realiza lo mismo para open o apertura y volumen de operación. 

Para poder realizar dichos cálculos se debió combinar consultas. 

### Lenguaje M 

```
if [Índice] = 0 then null else ([Close] - [Apple2.Close]) / [Apple2.Close] * 100 
```

``` 
if [Índice] = 0 then null else ([Open] - [Apple2.Open]) / [Apple2.Open] * 100
``` 

``` 
if [Índice] = 0 then null else ([Volume] - [Apple2.Volume]) / [Apple2.Volume] * 100
```

Varianza entre close y open del mercado: 

``` 
([Close] / [Open] *100) -100)
```

 

### Transformación del dashboard con lenguaje DAX: 

### Lenguaje DAX: 

Suma de la Varianza Open o Varianza al abrir el mercado. De esta forma se obtiene el valor acumulativo del porcentaje de aumento de la acción.  

```
SumaVarOpen =  
VAR IndiceActual = 'Apple final'[Índice] 
RETURN 
    CALCULATE ( 
        SUM ( 'Apple final'[Varianza Open] ), 
        FILTER ( 
            ALL('Apple final'), 
            'Apple final'[Índice] <= IndiceActual 
        ) 
    )
```

Se suman los porcentajes de Varianza Close o Varianza al cerrar el mercado 

``` 
SumaVarClose =  
VAR IndiceActual = 'Apple final'[Índice] 
RETURN 
    CALCULATE ( 
        SUM ( 'Apple final'[Varianza Close] ), 
        FILTER ( 
            ALL('Apple final'), 
            'Apple final'[Índice] <= IndiceActual 
        ) 
    )
```


Aclaración: De la combinación de las tablas para poder hacer los cálculos de varianza no se pude eliminar las columnas duplicadas, por lo que se ocultan para no obstruir el análisis. 

Se realiza una tabla fechas apartada de la tabla original para facilitar el análisis. 

```  
TablaFechas = CalendarAuto()
```

Se agrega una columna calculada para sacar el promedio entre valor de apertura y cierre del mercado.  

```
Promedio_Open_Close =  
  ('Apple final'[Close] + 'Apple final'[Open]) / 2
 ```


Se agrega una medida rápida para sacar el promedio de la varianza en el volumen anualmente.  

Se importa una query a la base de datos para obtener la media móvil a 30 días del precio de cierre y apertura, tomando como fecha para el cálculo 1/5/2024. 

```
Select  
AVG([Open]) AS PromedioMovilOpen, 
AVG([Close]) AS PromedioMovilClose 
FROM Apple 
WHERE Date >= '2024-05-01'
 ```

 

Se importa desde SQL server una query que calcule el porcentaje de aumento en lo que respecta al 2024. 

```
 WITH Datos2024 AS ( 
    SELECT  
        [Date],  
        [Close], 
        ROW_NUMBER() OVER (ORDER BY [Date]) AS rn_inicial, 
       ROW_NUMBER() OVER (ORDER BY [Date] DESC) AS rn_final 
    FROM [Apple] 
    WHERE YEAR([Date]) = 2024 
) 
```

```
SELECT  
	ROUND((MAX(CASE WHEN Datos2024.rn_final = 1 THEN Datos2024.[Close] END) -  
	MAX(CASE WHEN Datos2024.rn_inicial = 1 THEN Datos2024.[Close] END)) / 
   MAX(CASE WHEN Datos2024.rn_inicial = 1 THEN Datos2024.[Close] END) * 100, 2) AS PorcentajeAumento2024 
FROM Datos2024;
```

De esta forma se crea el primer KPI, obteniendo de la página web mencionada el porcentaje esperado de aumento de las acciones para el 2024 y el resultado de la query a SQL server. Se importa esta consulta y no se realiza un direct query porque en este caso la información es estática, no se posee actualización de los valores de las acciones.  


Para el otro KPI, valor final objetivo versus valor actual, se importa otra query a SQL server. Trayendo el valor más actual de la acción de Apple. 

```
SELECT TOP (1)  
    [Date],  
    [Close] 
FROM  
    Apple 
ORDER BY  
    [Date] DESC;
```

# Creación de gráficos 

### Hoja Apertura 

Precio Máximo, Mínimo y Promedio de Apertura del mercado. Aquí se  tomaron los úlitmos 14 años de la acción donde se observó el mayor crecimiento de los valores. 

Porcentaje de Aumento Anual. Tomando la columna (SumaVarOpen ) donde se calcula el porcentaje de aumento que tuvo a lo largo de la historia la acción, se grafica el mínimo, máximo y promedio del porcentaje de aumento que tuvo la acción en la apertura del mercado. 

Máxima varianza en el precio de apertura por año. Tomando la columna (Varianza Open) que toma el precio del día anterior y saca el porcentaje de variación día a día. Teniendo en cuenta el máximo, se grafica la varianza que hubo a lo largo de los últimos 14 años considerados en el estudio. 

Tabla indicativa donde se exponen los datos de apertura, cierre, precio más bajo y más alto resumidos en suma por año, y se agregan dos columnas de YTY Close y YTY Open, donde se calcula el porcentaje de aumento de una acción de un año a otro, tomando en cuenta el cierre y la apertura. Considerar que los datos del 2024 no se encuentran completos ya que el año no finalizó. 


### Hoja Cierre 

Promedio de precio de cierre y apertura por año. Teniendo en cuenta los últimos 14 años del precio de mercado de las acciones, se predice el precio de los siguientes 3 años.  

Precio Máximo, Mínimo y Promedio de Cierre por Año. Se toman los últimos 14 años para evaluar sobre el precio de cierre de la acción el mínimo, máximo y promedio anual.  

Porcentaje de Aumento Anual. Considerando el mínimo, máximo y promedio del precio de cierre se toman los últimos 14 años para evaluar el porcentaje de aumento. 

Máxima Varianza Cierre por Año. Se grafica el máximo de la varianza día a día que hubo anualmente. 


### Hoja Volumen 

Promedio de Volumen por Close. Se toma el promedio del volumen y el precio de cierre de los últimos 14 años para realizar el análisis.  

Promedio de Volumen por año. Se toman los últimos 14 años y se grafica promedio de volumen  anual. 

Promedio de Varianza en Volumen por año. Se grafica el promedio anual de la varianza del volumen, tomando los últimos 14 años.  


### Hoja 2024 

Media Móvil de Apertura a 30 días y Media Móvil de Cierre a 30 días obtenidos desde SQL. 

Promedio de Open y Close por Año, Mes y Día. Se toma el promedio de  los valores de apertura y cierre del mercado, por separado. Se grafica en función a la fecha y se añade una línea de tendencia- 

Promedio de Open y Promedio Close por Año y Mes, se grafica lo mismo del ítem anterior pero en vez de utilizar el precio diario se utiliza el promedio mensual. 

 
### Hoja KPI 

Objetivos 2024 Apple: https://markets.businessinsider.com/news/stocks/apple-stock-price-outlook-stay-bullish-5-reasons-ai-plan-2024-3 

 Tomando los objetivos del 2024 de Apple se compara con los valores actuales. 

Objetivo de porcentaje de aumento de la acción. Se agrega un KPI y una barra de temperatura para mostrar el avanza sobre el objetivo. 

Objetivo de precio actual con respecto al objetivo. Se agrega un KPI y una barra de temperatura para mostrar el avanza sobre el objetivo. 

 
# Conclusión 

En el precio de apertura y ciere se puede observar un quiebre del precio en el 2017 pero con una curva de crecimiento empinada que comienza en 2020. Esto se relaciona al crecimiento exponencial que tuvieron las empresas tecnológicas en dicho año.  
De los años analizados en la tabla, se observan dos años con balance negativo, 2013 y 2016. Según los portales la caída del 2013 y 2016 se debió a que no se lograron las ventas que preveían para el año.  

En cuanto al porcentaje de aumento anual, se puede observar un crecimiento lineal hasta el 2011 donde comenzó a ser más paralelo al eje x, por este motivo induzco que el aumento del valor de la acción en la apertura se mantuvo constante. En el caso del valor de cierre aparece la misma paralelización, con el eje x, a partir del 2021. 

En el gráfico máximo de varianza apertura por año, los años 2012, 2015 y 2020 tuvieron la máxima varianza en el valor de la acción en la apertura, o sea, que de un día al otro sufrió la mayor variación del precio con respecto al día anterior. En cambio en el caso del valor del cierre de la acción, la mayor variación se observa en 2012, 2014, 2020 y 2022.  Siendo la mayor variación observado en 2015 en el valor de apertura, seguido por el 2020 en el cierre.  

Para el gráfico del promedio del precio de cierre y apertura observamos dos quiebres, uno de 2019 a 2021 y el último de 2021 a 2024. En el primero podemos observar que hay un aumento de la pendiente, indicando que hubo un aumento del crecimiento y luego, en el segundo tramo, se observa que esa pendiente disminuye haciéndose más paralela al eje x. Para este gráfico se destaca la predicción futura del precio, la línea media indica un leve aumento de la pendiente por lo que podría haber un crecimiento del valor de las acciones. 

Observando el gráfico promedio de volumen por cierre vemos que a medida que aumenta el precio en el tiempo se puede ver un descenso exponencial del volumen. El mayor descenso del volumen se puede observar a partir del 2015. 

En promedio de volumen por año afirmamos lo observado en el gráfico anterior y las predicciones se confirma este pronóstico de descenso del volumen operatorio. 

Para el gráfico promedio de varianza en volumen por año tenemos una gran variación del volumen día a día, siendo positivo cuando hubo un mayor aumento del volumen, en cambio para los valores negativos se puede decir que la disminuyó el volumen. Esto no necesariamente debe cumplir con esta observación, puede deberse a una gran variación del volumen operatorio de un día a otro de forma constante. Por lo que el valor sea negativo no implica que sea algo negativo. 

Analizando el gráfico promedio de open y close por año, mes y día, tenemos una línea de tendencia negativa en general pero desglosando en porciones el primer trimestre se observa una pendiente negativa y en el segundo un positiva. Lo que se confirma en el gráfico promedio open y promedio close por año y mes, donde desde abril del 2024 se ve una tendencia alcista de la acción. 

De forma orientativa se incluyó la media móvil de apertura y cierre a 30 días, tomando el mes de mayo, considerando que el mes de abril termino en un promedio de 170 dólares la acción, se puede considerar un aumento del 8% aproximadamente en un mes. 

Para finalizar, uno de los objetivos de la empresa se encuentra muy por debajo de lo que se planificó para el año. El aumento de la acción no está siendo ni aproximado al número que planteó la empresa como objetivo para el 2024. Por otro lado, el precio actual con respecto al objetivo se encuentra a un 24% de cumplir la meta.  

#### Fuentes
https://www.mac-history.net/2022/12/15/timeline-the-history-of-apple-2010-2020/
https://www.bbc.com/mundo/noticias/2016/04/160426_eeuu_apple_caida_ventas_historica_iphone_ab
