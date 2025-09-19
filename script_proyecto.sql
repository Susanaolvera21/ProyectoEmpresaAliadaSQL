---Creando la base de datos 
CREATE DATABASE ProyectoEmpresaAliada;
GO

USE ProyectoEmpresaAliada;
GO

ALTER TABLE DIM_SEGMENT
ADD ID INT IDENTITY(1,1) PRIMARY KEY;

ALTER TABLE FACT_SALES
ADD ID INT IDENTITY(1,1) PRIMARY KEY;

--Revisar que carguen correctamente las tablas 
SELECT TOP 10 * FROM DIM_CALENDAR;
SELECT TOP 10 * FROM DIM_CATEGORY;
SELECT TOP 10 * FROM DIM_PRODUCT;
SELECT TOP 10 * FROM DIM_SEGMENT;
SELECT TOP 10 * FROM FACT_SALES;

ALTER TABLE DIM_CATEGORY
ALTER COLUMN CATEGORY NVARCHAR(255);

ALTER TABLE DIM_PRODUCT
ALTER COLUMN CATEGORY NVARCHAR(255);

--Ventas globales
SELECT
    SUM(fs.Total_Unit_Sales) AS Total_Unidades,
    SUM(fs.Total_Value_Sales) AS Total_Valor_Ventas
FROM FACT_SALES fs;

--Promedio de Ventas por Unidad:
SELECT
    SUM(fs.Total_Value_Sales) * 1.0 / NULLIF(SUM(fs.Total_Unit_Sales), 0) AS Promedio_Venta_Por_Unidad
FROM FACT_SALES fs;

--Ventas mensuales:
SELECT
    YEAR(cal.DATE) AS Año,
    MONTH(cal.DATE) AS Mes,
    SUM(fs.TOTAL_VALUE_SALES) AS Ventas_Mensuales
FROM FACT_SALES fs
JOIN DIM_CALENDAR cal
    ON fs.WEEK = cal.WEEK
GROUP BY YEAR(cal.DATE), MONTH(cal.DATE)
ORDER BY Año, Mes;

--Tasa de Crecimiento de Ventas
WITH VentasMensuales AS (
    SELECT
        YEAR(cal.DATE) AS Anio,
        MONTH(cal.DATE) AS Mes,
        SUM(fs.TOTAL_VALUE_SALES) AS Ventas
    FROM FACT_SALES fs
    JOIN DIM_CALENDAR cal
        ON fs.WEEK = cal.WEEK
    GROUP BY YEAR(cal.DATE), MONTH(cal.DATE)
),
CrecimientoMensual AS (
    SELECT
        Anio,
        Mes,
        Ventas,
        LAG(Ventas) OVER (ORDER BY Anio, Mes) AS VentasMesAnterior
    FROM VentasMensuales
)
SELECT
    Anio,
    Mes,
    Ventas,
    CASE 
        WHEN VentasMesAnterior IS NULL THEN NULL
        WHEN VentasMesAnterior = 0 THEN NULL
        ELSE ROUND(((Ventas - VentasMesAnterior) * 100.0) / VentasMesAnterior, 2)
    END AS Porcentaje_Crecimiento
FROM CrecimientoMensual
ORDER BY Anio, Mes;

-- participación de mercado por región:
WITH VentasPorRegion AS (
    SELECT
        REGION,
        SUM(TOTAL_VALUE_SALES) AS Ventas_Region
    FROM FACT_SALES
    GROUP BY REGION
),
VentasTotales AS (
    SELECT SUM(TOTAL_VALUE_SALES) AS Ventas_Totales
    FROM FACT_SALES
)
SELECT
    vr.REGION,
    vr.Ventas_Region,
    vt.Ventas_Totales,
    ROUND((vr.Ventas_Region * 100.0) / vt.Ventas_Totales, 2) AS Participacion_Porcentual
FROM VentasPorRegion vr
CROSS JOIN VentasTotales vt
ORDER BY Participacion_Porcentual DESC;
-----

--Ventas agregadas por categoría, región y año
SELECT
    dp.Category AS Categoria,
    fs.Region,
    cal.Year,
    SUM(fs.Total_Unit_Sales) AS Total_Unidades,
    SUM(fs.Total_Value_Sales) AS Total_Valor_Ventas
FROM
    FACT_SALES fs
JOIN DIM_PRODUCT dp ON fs.Item_Code = dp.Item
JOIN DIM_CALENDAR cal ON fs.Week = cal.Week
GROUP BY
    dp.Category,
    fs.Region,
    cal.Year
ORDER BY
    dp.Category,
    fs.Region,
    cal.Year;

	----
