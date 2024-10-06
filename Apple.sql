WITH Datos2024 AS (
    SELECT 
        [Date], 
        [Close],
        ROW_NUMBER() OVER (ORDER BY [Date]) AS rn_inicial,
        ROW_NUMBER() OVER (ORDER BY [Date] DESC) AS rn_final
    FROM [Apple]
    WHERE YEAR([Date]) = 2024
)
SELECT 
	ROUND((MAX(CASE WHEN Datos2024.rn_final = 1 THEN Datos2024.[Close] END) - 
	MAX(CASE WHEN Datos2024.rn_inicial = 1 THEN Datos2024.[Close] END)) /
     MAX(CASE WHEN Datos2024.rn_inicial = 1 THEN Datos2024.[Close] END) * 100, 2) AS PorcentajeAumento2024
FROM Datos2024;

SELECT TOP (1) 
    [Date], 
    [Close]
FROM 
    Apple
ORDER BY 
    [Date] DESC;
