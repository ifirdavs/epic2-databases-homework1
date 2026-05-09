/*
Task 8 — AdventureWorks / PostgreSQL

Question:
Investigate if and how vendor CreditRating correlates with the total monetary amount
of purchase transactions with that vendor.

## Analysis strategy:
I treat each purchase order as one transaction and use purchaseorderheader."TotalDue"
as the monetary value of that transaction. This is the best single column for the
"total monetary amount" because it is stored at the order level and includes the
order subtotal, tax, and freight. The relationship to analyze is therefore:

    vendor."CreditRating"  <->  SUM(purchaseorderheader."TotalDue") per vendor

CreditRating is an ordinal numeric value. 
In AdventureWorks, a smaller CreditRating number means a better rating. 
Therefore:
  - a negative correlation means better-rated vendors tend to receive larger purchase totals,
  - a positive correlation means worse-rated vendors tend to receive larger purchase totals, and 
  - a value near 0 means there is no clear linear relationship. 

For the correlation query, I use only vendors that have at least one purchase order,
because vendors with zero transactions would add artificial zero totals and may distort 
the relationship.
*/


/* --------------------------------------------------------------------------
Query 1: Total transaction amount per vendor

This query gives the main data table used for the analysis: one row per vendor,
with its CreditRating and total purchase-order amount.
-------------------------------------------------------------------------- */
WITH vendor_transaction_totals AS (
    SELECT
        v."VendorID",
        v."Name" AS vendor_name,
        v."CreditRating",
        COUNT(poh."PurchaseOrderID") AS purchase_order_count,
        COALESCE(SUM(poh."TotalDue"), 0) AS total_transaction_amount
    FROM public.vendor AS v
    LEFT JOIN public.purchaseorderheader AS poh
        ON poh."VendorID" = v."VendorID"
    GROUP BY
        v."VendorID",
        v."Name",
        v."CreditRating"
)
SELECT
    "VendorID",
    vendor_name,
    "CreditRating",
    purchase_order_count,
    ROUND(total_transaction_amount::numeric, 2) AS total_transaction_amount
FROM vendor_transaction_totals
ORDER BY
    "CreditRating",
    total_transaction_amount DESC,
    vendor_name;


/* --------------------------------------------------------------------------
Query 2: Summary statistics by CreditRating

This groups vendors by CreditRating and shows whether better/worse rating groups
receive more total purchasing volume on average and in median terms.
-------------------------------------------------------------------------- */
WITH vendor_transaction_totals AS (
    SELECT
        v."VendorID",
        v."Name" AS vendor_name,
        v."CreditRating",
        COUNT(poh."PurchaseOrderID") AS purchase_order_count,
        COALESCE(SUM(poh."TotalDue"), 0) AS total_transaction_amount
    FROM public.vendor AS v
    LEFT JOIN public.purchaseorderheader AS poh
        ON poh."VendorID" = v."VendorID"
    GROUP BY
        v."VendorID",
        v."Name",
        v."CreditRating"
),
active_vendors AS (
    SELECT *
    FROM vendor_transaction_totals
    WHERE purchase_order_count > 0
)
SELECT
    "CreditRating",
    COUNT(*) AS vendors_with_transactions,
    SUM(purchase_order_count) AS purchase_order_count,
    ROUND(SUM(total_transaction_amount)::numeric, 2) AS total_amount_for_rating,
    ROUND(AVG(total_transaction_amount)::numeric, 2) AS average_amount_per_vendor,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_transaction_amount)::numeric,
        2
    ) AS median_amount_per_vendor,
    ROUND(MIN(total_transaction_amount)::numeric, 2) AS minimum_amount_per_vendor,
    ROUND(MAX(total_transaction_amount)::numeric, 2) AS maximum_amount_per_vendor
FROM active_vendors
GROUP BY "CreditRating"
ORDER BY "CreditRating";


/* --------------------------------------------------------------------------
Query 3: Correlation between CreditRating and vendor transaction total

Pearson correlation treats CreditRating as a numeric ordinal variable.
The Spearman-like correlation ranks both variables first, which is useful here
because CreditRating is ordinal and transaction totals are usually skewed.
-------------------------------------------------------------------------- */
WITH vendor_transaction_totals AS (
    SELECT
        v."VendorID",
        v."CreditRating",
        COUNT(poh."PurchaseOrderID") AS purchase_order_count,
        COALESCE(SUM(poh."TotalDue"), 0) AS total_transaction_amount
    FROM public.vendor AS v
    LEFT JOIN public.purchaseorderheader AS poh
        ON poh."VendorID" = v."VendorID"
    GROUP BY
        v."VendorID",
        v."CreditRating"
),
active_vendors AS (
    SELECT *
    FROM vendor_transaction_totals
    WHERE purchase_order_count > 0
),
ranked AS (
    SELECT
        "VendorID",
        "CreditRating",
        total_transaction_amount,
        DENSE_RANK() OVER (ORDER BY "CreditRating") AS credit_rating_rank,
        RANK() OVER (ORDER BY total_transaction_amount) AS amount_rank
    FROM active_vendors
),
correlations AS (
    SELECT
        COUNT(*) AS vendors_with_transactions,
        CORR("CreditRating"::double precision, total_transaction_amount::double precision)
            AS pearson_corr,
        CORR(credit_rating_rank::double precision, amount_rank::double precision)
            AS spearman_like_corr
    FROM ranked
)
SELECT
    vendors_with_transactions,
    ROUND(pearson_corr::numeric, 4) AS pearson_corr_creditrating_vs_amount,
    ROUND(spearman_like_corr::numeric, 4) AS spearman_like_corr_creditrating_vs_amount,
    CASE
        WHEN pearson_corr <= -0.30 THEN
            'Negative correlation: better-rated vendors, with lower CreditRating values, tend to have larger total purchase amounts.'
        WHEN pearson_corr >= 0.30 THEN
            'Positive correlation: worse-rated vendors, with higher CreditRating values, tend to have larger total purchase amounts.'
        WHEN pearson_corr BETWEEN -0.10 AND 0.10 THEN
            'Very weak or no clear linear correlation between CreditRating and total purchase amount.'
        ELSE
            'Weak/moderate relationship; check the grouped summary by CreditRating before making a conclusion.'
    END AS interpretation
FROM correlations;


/* --------------------------------------------------------------------------
The analysis first converts purchase orders into one total amount per vendor by
joining vendor to purchaseorderheader and summing purchaseorderheader."TotalDue".
Then it compares those vendor-level totals across CreditRating groups and computes
correlation coefficients between CreditRating and total transaction amount.

The main answer is the Pearson/Spearman result from Query 3. If the value is negative,
then vendors with better ratings, meaning lower CreditRating numbers, generally receive
higher purchase totals. If the value is positive, worse-rated vendors generally receive
higher purchase totals. If the value is close to zero, the database does not show a
strong relationship between vendor CreditRating and total purchase transaction amount.
-------------------------------------------------------------------------- */
"vendors_with_transactions",	"pearson_corr_creditrating_vs_amount",	"spearman_like_corr_creditrating_vs_amount",	"interpretation"
79,	0.0269,	0.0022,	"Very weak or no clear linear correlation between CreditRating and total purchase amount."