-- Task 6 — AdventureWorks, PostgreSQL


WITH
table_with_previous_day_rate AS (
    SELECT
        "CurrencyRateDate"::date AS "Date",
        "FromCurrencyCode",
        "ToCurrencyCode",
        "EndOfDayRate",
        LAG("EndOfDayRate") OVER (
            PARTITION BY "FromCurrencyCode", "ToCurrencyCode"      -- by each pair (to be on a safe side, even though there's only 'USD' in "FromCurrencyCode")
            ORDER BY "CurrencyRateDate"
        ) AS "PreviousEndOfDayRate"
    FROM currencyrate
    WHERE "FromCurrencyCode" = 'USD' AND "ToCurrencyCode" = 'CAD'
)
SELECT
    "Date",
    "FromCurrencyCode",
    "ToCurrencyCode",
    "EndOfDayRate",
    "PreviousEndOfDayRate",
    ABS("EndOfDayRate" - "PreviousEndOfDayRate") AS "AbsoluteChange"
FROM table_with_previous_day_rate
ORDER BY "AbsoluteChange" DESC
-- LIMIT 1;