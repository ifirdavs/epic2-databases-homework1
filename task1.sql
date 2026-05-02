/*
Using DBeaver.
Using SQLlite syntax for all tasks related to 'world' database
Using Postgres syntax for all tasks related to 'adventureworks' database
*/

-- Task 1 - Database: world

-- Create alphabet table
WITH alphabet(letter) AS (
    VALUES
        ('A'), ('B'), ('C'), ('D'), ('E'), ('F'), ('G'), ('H'), ('I'),
        ('J'), ('K'), ('L'), ('M'), ('N'), ('O'), ('P'), ('Q'), ('R'),
        ('S'), ('T'), ('U'), ('V'), ('W'), ('X'), ('Y'), ('Z')
)
-- Find letters that don't appear in the first place
SELECT
    'First place' AS Position,
    group_concat(a.letter, ', ') AS MissingLetters
FROM alphabet AS a
WHERE NOT EXISTS (
    SELECT 1
    FROM country AS c
    WHERE substr(upper(c.Code), 1, 1) = a.letter
)

UNION ALL

-- Find letters that don't appear in the second place
SELECT
    'Second place' AS Position,
    group_concat(a.letter, ', ') AS MissingLetters
FROM alphabet AS a
WHERE NOT EXISTS (
    SELECT 1
    FROM country AS c
    WHERE substr(upper(c.Code), 2, 1) = a.letter
)

UNION ALL

-- Find letters that don't appear in the third place
SELECT
    'Third place' AS Position,
    group_concat(a.letter, ', ') AS MissingLetters
FROM alphabet AS a
WHERE NOT EXISTS (
    SELECT 1
    FROM country AS c
    WHERE substr(upper(c.Code), 3, 1) = a.letter
);

