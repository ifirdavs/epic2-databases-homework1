-- Task 5 — AdventureWorks, PostgreSQL
-- Using pgAdmin4, but also used DBeaver later.

SELECT
    "DepartmentID",
    COUNT(DISTINCT "EmployeeID") AS "EmployeeCountPerDepartment"
FROM employeedepartmenthistory
WHERE "StartDate" <= DATE '1999-05-01' AND ("EndDate" IS NULL OR "EndDate" >= DATE '1999-05-01')
GROUP BY "DepartmentID"
ORDER BY "DepartmentID";