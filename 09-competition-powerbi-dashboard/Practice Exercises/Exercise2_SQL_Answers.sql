/* ============================================================
   Exercise 2 - ANSWERS (no peeking until you tried!)
   All queries use: FactPropertyValue F, DimLocation L, DimDate D,
   DimCategory C. Adjust column names if yours differ.
   ============================================================ */

USE PropertyDW;
GO

-- A1
SELECT L.Suburb, D.DateKey, F.PropertyMedianValue,
       ROW_NUMBER() OVER (PARTITION BY F.LocationKey ORDER BY F.DateKey DESC) AS rn
FROM dbo.FactPropertyValue F
JOIN dbo.DimLocation L ON L.LocationKey = F.LocationKey
JOIN dbo.DimDate D     ON D.DateKey = F.DateKey;

-- A2
WITH X AS (
    SELECT *, COUNT(*) OVER (PARTITION BY LocationKey, DateKey) AS cnt
    FROM dbo.FactPropertyValue)
SELECT * FROM X WHERE cnt > 1;

-- A3
WITH R AS (
    SELECT L.City, L.Suburb, AVG(F.PropertyMedianValue) AS AvgVal,
           RANK() OVER (PARTITION BY L.City ORDER BY AVG(F.PropertyMedianValue) DESC) AS rnk
    FROM dbo.FactPropertyValue F
    JOIN dbo.DimLocation L ON L.LocationKey = F.LocationKey
    GROUP BY L.City, L.Suburb)
SELECT City, Suburb, AvgVal FROM R WHERE rnk = 1 ORDER BY AvgVal DESC;

-- A4
SELECT DISTINCT L.City,
       AVG(F.PropertyMedianValue) OVER (PARTITION BY L.City) AS CityAvg,
       AVG(F.PropertyMedianValue) OVER ()                    AS NswAvg
FROM dbo.FactPropertyValue F
JOIN dbo.DimLocation L ON L.LocationKey = F.LocationKey;

-- A5
SELECT L.Suburb, F.DateKey, F.PropertyMedianValue AS ThisMonth,
       LAG(F.PropertyMedianValue) OVER (PARTITION BY F.LocationKey ORDER BY F.DateKey) AS LastMonth,
       F.PropertyMedianValue
         - LAG(F.PropertyMedianValue) OVER (PARTITION BY F.LocationKey ORDER BY F.DateKey) AS Diff
FROM dbo.FactPropertyValue F
JOIN dbo.DimLocation L ON L.LocationKey = F.LocationKey;

-- A6
WITH M AS (
    SELECT F.LocationKey, F.DateKey, F.PropertyMedianValue,
           LAG(F.PropertyMedianValue) OVER (PARTITION BY F.LocationKey ORDER BY F.DateKey) AS PrevVal
    FROM dbo.FactPropertyValue F)
SELECT L.Suburb, M.DateKey, M.PrevVal, M.PropertyMedianValue,
       M.PropertyMedianValue - M.PrevVal AS Drop_
FROM M JOIN dbo.DimLocation L ON L.LocationKey = M.LocationKey
WHERE M.PropertyMedianValue < M.PrevVal
ORDER BY Drop_;

-- A7
SELECT C.CategoryName, L.Suburb, F.PropertyMedianValue,
       RANK() OVER (PARTITION BY C.CategoryName ORDER BY F.PropertyMedianValue ASC) AS CheapestFirst
FROM dbo.FactPropertyValue F
JOIN dbo.DimCategory C ON C.CategoryKey = F.CategoryKey
JOIN dbo.DimLocation L ON L.LocationKey = F.LocationKey;
-- cheapest in $2.5M+ club = rows where CategoryName = '$2.5M+' AND CheapestFirst = 1

-- A8
SELECT L.Suburb, F.DateKey, F.PropertyMedianValue,
       AVG(F.PropertyMedianValue) OVER (
           PARTITION BY F.LocationKey ORDER BY F.DateKey
           ROWS UNBOUNDED PRECEDING) AS RunningAvg
FROM dbo.FactPropertyValue F
JOIN dbo.DimLocation L ON L.LocationKey = F.LocationKey;

-- A9
SELECT L.City, L.Suburb, F.PropertyMedianValue,
       F.PropertyMedianValue * 100.0
         / SUM(F.PropertyMedianValue) OVER (PARTITION BY L.City) AS PctOfCity
FROM dbo.FactPropertyValue F
JOIN dbo.DimLocation L ON L.LocationKey = F.LocationKey
ORDER BY L.City, PctOfCity DESC;

-- A10
WITH X AS (
    SELECT L.City, L.Suburb, F.PropertyMedianValue,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY F.PropertyMedianValue)
               OVER (PARTITION BY L.City) AS CityMedian
    FROM dbo.FactPropertyValue F
    JOIN dbo.DimLocation L ON L.LocationKey = F.LocationKey)
SELECT * FROM X
WHERE PropertyMedianValue > 2 * CityMedian
ORDER BY City, PropertyMedianValue DESC;
