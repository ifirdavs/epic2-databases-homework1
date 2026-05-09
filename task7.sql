/*
Task 7 — AdventureWorks / PostgreSQL
Question: Use a recursive query over the employee table to obtain subordination chains.

Strategy:
- The employee table stores the hierarchy using EmployeeID and ManagerID.
- A direct subordination relation is: ManagerID -> EmployeeID.
- The anchor part of the recursive CTE starts with every direct manager-subordinate pair.
- The recursive part extends an existing chain by finding employees whose ManagerID is the
  current last employee in the chain.
- path_ids is kept as an integer array so the query can avoid infinite loops if bad data
  accidentally contains a management cycle.
- The output includes all chains and their subchains, which is allowed by the task.
  Example output format: 1 -> 3 -> 12.

Each row is one subordination chain.
*/

WITH RECURSIVE subordination_chains AS (
    -- Anchor step: every direct manager -> employee relationship.
    SELECT
        e."ManagerID" AS "RootManagerID",
        e."EmployeeID" AS "LastEmployeeID",
        ARRAY[e."ManagerID", e."EmployeeID"] AS "path_ids",
        (e."ManagerID"::text || ' -> ' || e."EmployeeID"::text) AS "SubordinationChain"
    FROM employee AS e
    WHERE e."ManagerID" IS NOT NULL

    UNION ALL

    -- Recursive step: append the next subordinate to the existing chain.
    SELECT
        sc."RootManagerID",
        e."EmployeeID" AS "LastEmployeeID",
        sc."path_ids" || e."EmployeeID",
        sc."SubordinationChain" || ' -> ' || e."EmployeeID"::text
    FROM subordination_chains AS sc
    JOIN employee AS e
        ON e."ManagerID" = sc."LastEmployeeID"
    -- Cycle protection: do not add an employee that already exists in this chain.
    WHERE NOT e."EmployeeID" = ANY(sc."path_ids")
)
SELECT
    "RootManagerID",
    "LastEmployeeID",
    array_length("path_ids", 1) AS "ChainLength",
    "SubordinationChain"
FROM subordination_chains
ORDER BY
    "RootManagerID",
    "ChainLength",
    "SubordinationChain";

/*
Optional deduplicated/maximal-chain version:
If you only want chains that cannot be extended further downward, add the NOT EXISTS
condition below to keep only leaf-ending chains.

WITH RECURSIVE subordination_chains AS (
    SELECT
        e."ManagerID" AS "RootManagerID",
        e."EmployeeID" AS "LastEmployeeID",
        ARRAY[e."ManagerID", e."EmployeeID"] AS "path_ids",
        (e."ManagerID"::text || ' -> ' || e."EmployeeID"::text) AS "SubordinationChain"
    FROM employee AS e
    WHERE e."ManagerID" IS NOT NULL

    UNION ALL

    SELECT
        sc."RootManagerID",
        e."EmployeeID" AS "LastEmployeeID",
        sc."path_ids" || e."EmployeeID",
        sc."SubordinationChain" || ' -> ' || e."EmployeeID"::text
    FROM subordination_chains AS sc
    JOIN employee AS e
        ON e."ManagerID" = sc."LastEmployeeID"
    WHERE NOT e."EmployeeID" = ANY(sc."path_ids")
)
SELECT
    "RootManagerID",
    "LastEmployeeID",
    array_length("path_ids", 1) AS "ChainLength",
    "SubordinationChain"
FROM subordination_chains AS sc
WHERE NOT EXISTS (
    SELECT 1
    FROM employee AS child
    WHERE child."ManagerID" = sc."LastEmployeeID"
      AND NOT child."EmployeeID" = ANY(sc."path_ids")
)
ORDER BY
    "RootManagerID",
    "ChainLength",
    "SubordinationChain";
*/
