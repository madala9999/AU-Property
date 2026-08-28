SELECT state, COUNT(city) AS city_count
FROM AUS_Post_suburb
GROUP BY state
ORDER BY city_count DESC;

SELECT[city], 
COUNT(DISTINCT [postcode]) AS DistinctPostcode,
COUNT(DISTINCT [suburb]) AS DistinctSuburbs
FROM [dbo].[AUS_Post_suburb]
GROUP BY city
ORDER BY city;

SELECT [Suburb],
AVG([Property_Median_Value]) AS avg_Median_Value
FROM [dbo].[NSW_PropertyMedianValue]
WHERE [Property_Median_Value] IS NOT NULL
GROUP BY [Suburb]
ORDER BY avg_Median_Value DESC;

SELECT [Postcode],
AVG([Property_Median_Value]) AS avg_Median_Value
FROM [dbo].[NSW_PropertyMedianValue]
WHERE [Property_Median_Value] IS NOT NULL
GROUP BY [Postcode]
ORDER BY avg_Median_Value DESC;

SELECT [Suburb],[postcode],AVG([Property_Median_Value]) AS avg_Median_Value
FROM [dbo].[NSW_PropertyMedianValue]
WHERE [Property_Median_Value] IS NOT NULL
GROUP BY [Suburb],[postcode]
ORDER BY avg_Median_Value DESC;