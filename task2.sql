-- Task 2 - Database: world



-- 1. Population per square mile for each country.
WITH country_density AS (
    SELECT
        Code,
        Name,
        Population,
        SurfaceArea AS SurfaceAreaSquareMiles,
        CAST(Population AS REAL) / SurfaceArea AS PopulationPerSquareMile
    FROM country
    WHERE SurfaceArea > 0
)
SELECT
    Code,
    Name,
    Population,
    ROUND(SurfaceAreaSquareMiles, 2) AS SurfaceAreaSquareMiles,
    ROUND(PopulationPerSquareMile, 4) AS PopulationPerSquareMile
FROM country_density
ORDER BY Name;



-- 2. Minimum, Maximum, and Median in three rows.
WITH country_density AS (
    SELECT
        Code,
        Name,
        CAST(Population AS REAL) / SurfaceArea AS PopulationPerSquareMile
    FROM country
    WHERE SurfaceArea > 0
),
ordered_density AS (
    SELECT
        PopulationPerSquareMile,
        row_number() OVER (ORDER BY PopulationPerSquareMile) AS rn,
        count(*) OVER () AS total_rows
    FROM country_density
),
median_density AS (
    SELECT
        avg(PopulationPerSquareMile) AS MedianValue
    FROM ordered_density
    WHERE rn IN ((total_rows + 1) / 2, (total_rows + 2) / 2)
)
SELECT
    'Minimum' AS Metric,
    ROUND(min(PopulationPerSquareMile), 4) AS Value
FROM country_density

UNION ALL

SELECT
    'Maximum' AS Metric,
    ROUND(max(PopulationPerSquareMile), 4) AS Value
FROM country_density

UNION ALL

SELECT
    'Median' AS Metric,
    ROUND(MedianValue, 4) AS Value
FROM median_density;
