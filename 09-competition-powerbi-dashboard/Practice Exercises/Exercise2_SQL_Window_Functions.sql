/* ============================================================
   Exercise 2 - SQL Window Functions practice
   Run these against your own PropertyDW in SSMS.
   Try each question BEFORE looking at the answers file!
   Difficulty goes up as you go. Questions 1-4 you should
   manage today; 5-8 need some thinking; 9-10 are stretch.
   ============================================================ */

USE PropertyDW;
GO

-- Q1. Number every property value row per suburb, newest month first.
--     (ROW_NUMBER + PARTITION BY + ORDER BY)
--     Expected: each suburb's rows numbered 1, 2, 3...



-- Q2. Are there any exact duplicate rows in FactPropertyValue?
--     Same LocationKey + DateKey appearing more than once?
--     (ROW_NUMBER or COUNT(*) OVER, then filter rn > 1)



-- Q3. Show the TOP 1 most expensive suburb in EACH city
--     (by average PropertyMedianValue).
--     (RANK or ROW_NUMBER over PARTITION BY city)



-- Q4. For each city: its average property value AND the overall
--     NSW average side by side in one row, no GROUP BY subqueries.
--     (AVG(...) OVER () with empty parentheses)



-- Q5. Month-over-month: for each suburb, show this month's value,
--     last month's value, and the difference.
--     (LAG over PARTITION BY LocationKey ORDER BY DateKey)



-- Q6. Which suburbs had a value DROP compared to the previous month?
--     (build on Q5, filter where diff < 0)



-- Q7. Rank all suburbs within their price-bucket category
--     (join DimCategory) - who is the cheapest in the $2.5M+ club?
--     (RANK over PARTITION BY CategoryName)



-- Q8. Running average: for each suburb ordered by month, the
--     cumulative average value up to that month.
--     (AVG(...) OVER (PARTITION BY ... ORDER BY ... ROWS UNBOUNDED PRECEDING))



-- Q9. Percent of city total: each suburb's value as a % of the sum
--     of all suburb values in its city, in one query.
--     (value * 100.0 / SUM(value) OVER (PARTITION BY city))



-- Q10. Find suburbs whose value is more than 2x the MEDIAN value
--      of their city. SQL Server has no MEDIAN() - use
--      PERCENTILE_CONT(0.5) WITHIN GROUP ... OVER (PARTITION BY city).



/* When done, compare with Exercise2_SQL_Answers.sql.
   Your answer counts as correct if the result set matches,
   even if you wrote it differently! */
