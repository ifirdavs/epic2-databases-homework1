-- Task 3 - Database: world


-- WITH capital_population_share AS (
--     SELECT
--         c.Code AS CountryCode,
--         c.Name AS CountryName,
--         capital.Name AS CapitalName,
--         c.Population AS CountryPopulation,
--         capital.Population AS CapitalPopulation,
--         100.0 * capital.Population / c.Population AS CapitalPopulationPercentage
--     FROM country AS c
--     INNER JOIN city AS capital
--         ON capital.ID = c.Capital
--     WHERE c.Population > 0
--       AND c.Capital IS NOT NULL
-- )
-- SELECT
--     CountryCode,
--     CountryName,
--     CapitalName,
--     CountryPopulation,
--     CapitalPopulation,
--     ROUND(CapitalPopulationPercentage, 4) AS CapitalPopulationPercentage
-- FROM capital_population_share
-- ORDER BY CapitalPopulationPercentage ASC, CountryName ASC
-- LIMIT 10;


SELECT 
    c.Code AS CountryCode,
    c.Name AS CountryName,
    capital.Name AS CapitalName,
    c.Population AS CountryPopulation,
    capital.Population AS CapitalPopulation,
    ROUND(100.0 * capital.Population / c.Population, 4) AS CapitalPopulationPercentage
FROM country AS c
JOIN city AS capital
	ON capital.ID = c.Capital
WHERE c.Population > 0 AND c.Capital IS NOT NULL
ORDER BY CapitalPopulationPercentage ASC, CountryName ASC
LIMIT 10;