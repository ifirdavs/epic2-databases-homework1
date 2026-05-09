/*
Task 9 — AdventureWorks / PostgreSQL

Question:
Investigate if and how an employee's pay rate correlates with age, gender, and
marital status.

Analysis strategy:
The `employee` table contains the demographic columns: BirthDate, Gender, and
MaritalStatus. The pay-rate values are stored in `employeepayhistory`. Since an
employee can have multiple historical pay-rate rows, the analysis below uses the
latest pay-rate row per employee. This avoids counting the same employee several
times. Age is calculated as the employee's age on the latest RateChangeDate,
not as age today, because the AdventureWorks data is historical.

For age, I use PostgreSQL's CORR() function because both age and pay rate are
numeric. For Gender and MaritalStatus, a simple correlation coefficient is less
natural because they are categorical variables. So the main investigation is a
comparison of count, average, median, minimum, and maximum pay rate by group.
For the common two-value fields in AdventureWorks, I also include optional binary
correlations: Male vs not Male and Married vs not Married. These binary
correlations are useful as a rough numerical summary, but the grouped statistics
are easier to interpret.
*/

/* --------------------------------------------------------------------------
Query 1: Employee-level dataset used for the analysis

One row per employee, using only the latest pay-rate record.
-------------------------------------------------------------------------- */

WITH latest_pay AS (
    SELECT
        eph."EmployeeID",
        eph."RateChangeDate",
        eph."Rate",
        eph."PayFrequency",
        eph."ModifiedDate",
        ROW_NUMBER() OVER (
            PARTITION BY eph."EmployeeID"
            ORDER BY eph."RateChangeDate" DESC, eph."ModifiedDate" DESC
        ) AS rn
    FROM public.employeepayhistory AS eph
), employee_pay AS (
    SELECT
        e."EmployeeID",
        e."Gender",
        e."MaritalStatus",
        e."BirthDate"::date AS birth_date,
        lp."RateChangeDate"::date AS rate_change_date,
        DATE_PART('year', AGE(lp."RateChangeDate"::date, e."BirthDate"::date))::int
            AS age_at_rate_change,
        lp."Rate" AS pay_rate,
        lp."PayFrequency"
    FROM public.employee AS e
    JOIN latest_pay AS lp
        ON lp."EmployeeID" = e."EmployeeID"
       AND lp.rn = 1
    WHERE e."BirthDate" IS NOT NULL
      AND lp."Rate" IS NOT NULL
)
SELECT
    "EmployeeID",
    "Gender",
    "MaritalStatus",
    birth_date,
    rate_change_date,
    age_at_rate_change,
    pay_rate,
    "PayFrequency"
FROM employee_pay
ORDER BY "EmployeeID";


/* --------------------------------------------------------------------------
Query 2: Correlation between age and pay rate

Interpretation guide:
- correlation close to +1: older employees tend to have higher pay rates
- correlation close to -1: older employees tend to have lower pay rates
- correlation close to 0: no clear linear relationship
-------------------------------------------------------------------------- */

WITH latest_pay AS (
    SELECT
        eph."EmployeeID",
        eph."RateChangeDate",
        eph."Rate",
        eph."PayFrequency",
        eph."ModifiedDate",
        ROW_NUMBER() OVER (
            PARTITION BY eph."EmployeeID"
            ORDER BY eph."RateChangeDate" DESC, eph."ModifiedDate" DESC
        ) AS rn
    FROM public.employeepayhistory AS eph
), employee_pay AS (
    SELECT
        e."EmployeeID",
        DATE_PART('year', AGE(lp."RateChangeDate"::date, e."BirthDate"::date))::double precision
            AS age_at_rate_change,
        lp."Rate"::double precision AS pay_rate
    FROM public.employee AS e
    JOIN latest_pay AS lp
        ON lp."EmployeeID" = e."EmployeeID"
       AND lp.rn = 1
    WHERE e."BirthDate" IS NOT NULL
      AND lp."Rate" IS NOT NULL
)
SELECT
    COUNT(*) AS employee_count,
    ROUND(MIN(age_at_rate_change)::numeric, 2) AS min_age,
    ROUND(MAX(age_at_rate_change)::numeric, 2) AS max_age,
    ROUND(AVG(age_at_rate_change)::numeric, 2) AS avg_age,
    ROUND(AVG(pay_rate)::numeric, 2) AS avg_pay_rate,
    ROUND(CORR(age_at_rate_change, pay_rate)::numeric, 4) AS age_pay_rate_correlation,
    ROUND(REGR_SLOPE(pay_rate, age_at_rate_change)::numeric, 4) AS pay_rate_change_per_1_year_age,
    CASE
        WHEN CORR(age_at_rate_change, pay_rate) >= 0.30 THEN
            'Positive relationship: older employees tend to have higher pay rates.'
        WHEN CORR(age_at_rate_change, pay_rate) <= -0.30 THEN
            'Negative relationship: older employees tend to have lower pay rates.'
        WHEN CORR(age_at_rate_change, pay_rate) BETWEEN -0.10 AND 0.10 THEN
            'Very weak or no clear linear relationship between age and pay rate.'
        ELSE
            'Weak/moderate relationship; inspect group summaries before making a strong conclusion.'
    END AS interpretation
FROM employee_pay;


/* --------------------------------------------------------------------------
Query 3: Pay-rate summary by Gender

This is the main way to investigate the categorical Gender variable.
-------------------------------------------------------------------------- */

WITH latest_pay AS (
    SELECT
        eph."EmployeeID",
        eph."RateChangeDate",
        eph."Rate",
        eph."ModifiedDate",
        ROW_NUMBER() OVER (
            PARTITION BY eph."EmployeeID"
            ORDER BY eph."RateChangeDate" DESC, eph."ModifiedDate" DESC
        ) AS rn
    FROM public.employeepayhistory AS eph
), employee_pay AS (
    SELECT
        e."EmployeeID",
        e."Gender",
        lp."Rate" AS pay_rate
    FROM public.employee AS e
    JOIN latest_pay AS lp
        ON lp."EmployeeID" = e."EmployeeID"
       AND lp.rn = 1
    WHERE e."Gender" IS NOT NULL
      AND lp."Rate" IS NOT NULL
)
SELECT
    "Gender",
    COUNT(*) AS employee_count,
    ROUND(AVG(pay_rate)::numeric, 2) AS average_pay_rate,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pay_rate)::numeric, 2) AS median_pay_rate,
    ROUND(MIN(pay_rate)::numeric, 2) AS minimum_pay_rate,
    ROUND(MAX(pay_rate)::numeric, 2) AS maximum_pay_rate
FROM employee_pay
GROUP BY "Gender"
ORDER BY "Gender";


/* --------------------------------------------------------------------------
Query 4: Pay-rate summary by MaritalStatus

This is the main way to investigate the categorical MaritalStatus variable.
-------------------------------------------------------------------------- */

WITH latest_pay AS (
    SELECT
        eph."EmployeeID",
        eph."RateChangeDate",
        eph."Rate",
        eph."ModifiedDate",
        ROW_NUMBER() OVER (
            PARTITION BY eph."EmployeeID"
            ORDER BY eph."RateChangeDate" DESC, eph."ModifiedDate" DESC
        ) AS rn
    FROM public.employeepayhistory AS eph
), employee_pay AS (
    SELECT
        e."EmployeeID",
        e."MaritalStatus",
        lp."Rate" AS pay_rate
    FROM public.employee AS e
    JOIN latest_pay AS lp
        ON lp."EmployeeID" = e."EmployeeID"
       AND lp.rn = 1
    WHERE e."MaritalStatus" IS NOT NULL
      AND lp."Rate" IS NOT NULL
)
SELECT
    "MaritalStatus",
    COUNT(*) AS employee_count,
    ROUND(AVG(pay_rate)::numeric, 2) AS average_pay_rate,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pay_rate)::numeric, 2) AS median_pay_rate,
    ROUND(MIN(pay_rate)::numeric, 2) AS minimum_pay_rate,
    ROUND(MAX(pay_rate)::numeric, 2) AS maximum_pay_rate
FROM employee_pay
GROUP BY "MaritalStatus"
ORDER BY "MaritalStatus";


/* --------------------------------------------------------------------------
Query 5: Pay-rate summary by both Gender and MaritalStatus

This helps detect whether a difference visible in one category is actually mixed
with another category.
-------------------------------------------------------------------------- */

WITH latest_pay AS (
    SELECT
        eph."EmployeeID",
        eph."RateChangeDate",
        eph."Rate",
        eph."ModifiedDate",
        ROW_NUMBER() OVER (
            PARTITION BY eph."EmployeeID"
            ORDER BY eph."RateChangeDate" DESC, eph."ModifiedDate" DESC
        ) AS rn
    FROM public.employeepayhistory AS eph
), employee_pay AS (
    SELECT
        e."EmployeeID",
        e."Gender",
        e."MaritalStatus",
        lp."Rate" AS pay_rate
    FROM public.employee AS e
    JOIN latest_pay AS lp
        ON lp."EmployeeID" = e."EmployeeID"
       AND lp.rn = 1
    WHERE e."Gender" IS NOT NULL
      AND e."MaritalStatus" IS NOT NULL
      AND lp."Rate" IS NOT NULL
)
SELECT
    "Gender",
    "MaritalStatus",
    COUNT(*) AS employee_count,
    ROUND(AVG(pay_rate)::numeric, 2) AS average_pay_rate,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pay_rate)::numeric, 2) AS median_pay_rate,
    ROUND(MIN(pay_rate)::numeric, 2) AS minimum_pay_rate,
    ROUND(MAX(pay_rate)::numeric, 2) AS maximum_pay_rate
FROM employee_pay
GROUP BY
    "Gender",
    "MaritalStatus"
ORDER BY
    "Gender",
    "MaritalStatus";


/* --------------------------------------------------------------------------
Query 6: Optional compact numerical summary

This gives one row with:
- age/pay-rate Pearson correlation
- rough binary correlation for Gender = 'M'
- rough binary correlation for MaritalStatus = 'M'

For the last two, remember that these are binary encodings of categorical fields,
so they should support, not replace, the grouped summaries above.
-------------------------------------------------------------------------- */

WITH latest_pay AS (
    SELECT
        eph."EmployeeID",
        eph."RateChangeDate",
        eph."Rate",
        eph."ModifiedDate",
        ROW_NUMBER() OVER (
            PARTITION BY eph."EmployeeID"
            ORDER BY eph."RateChangeDate" DESC, eph."ModifiedDate" DESC
        ) AS rn
    FROM public.employeepayhistory AS eph
), employee_pay AS (
    SELECT
        e."EmployeeID",
        e."Gender",
        e."MaritalStatus",
        DATE_PART('year', AGE(lp."RateChangeDate"::date, e."BirthDate"::date))::double precision
            AS age_at_rate_change,
        lp."Rate"::double precision AS pay_rate
    FROM public.employee AS e
    JOIN latest_pay AS lp
        ON lp."EmployeeID" = e."EmployeeID"
       AND lp.rn = 1
    WHERE e."BirthDate" IS NOT NULL
      AND e."Gender" IS NOT NULL
      AND e."MaritalStatus" IS NOT NULL
      AND lp."Rate" IS NOT NULL
)
SELECT
    COUNT(*) AS employee_count,
    ROUND(CORR(age_at_rate_change, pay_rate)::numeric, 4) AS corr_age_vs_pay_rate,
    ROUND(CORR(("Gender" = 'M')::int::double precision, pay_rate)::numeric, 4)
        AS corr_is_male_vs_pay_rate,
    ROUND(CORR(("MaritalStatus" = 'M')::int::double precision, pay_rate)::numeric, 4)
        AS corr_is_married_vs_pay_rate
FROM employee_pay;


/* --------------------------------------------------------------------------
Plain-text answer to use after running the queries:

The analysis uses one latest pay-rate row per employee from employeepayhistory and
joins it to employee demographic data. Age is computed at the employee's latest
RateChangeDate, which is more appropriate for the historical AdventureWorks data
than using the current date. The age relationship is measured with CORR(age,
pay_rate) and REGR_SLOPE(pay_rate, age), where the slope shows the expected pay
rate change for one additional year of age.

Gender and marital status are categorical variables, so the best interpretation
comes from the grouped summaries by Gender, by MaritalStatus, and by both fields
together. If the average and median pay rates are similar across groups, then the
data does not show a strong relationship. If one group has consistently higher
average and median values, then the data suggests a relationship, but it should
be described as association only, not proof that gender or marital status causes
the pay-rate difference.
-------------------------------------------------------------------------- */
