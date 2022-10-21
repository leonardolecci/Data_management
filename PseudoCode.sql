--Pseudocode Team1



-- I want to look for how many movies are made for each first letter or number

SELECT COUNT(*)
FROM films
WHERE title LIKE 'E%';

-- A: 323 movies
-- B: 283
-- C: 248
-- D: 233
-- E: 113
-- F: 180
-- G: 132
-- H: 207
-- A:H 1719

-- I: 135
-- J: 84
-- K: 64
-- L: 156
-- M: 268
-- N: 85
-- O: 89
-- P: 157
-- Q: 12
-- R: 174
-- S: 438
-- I:S 1662

-- T: 1209
-- U: 48
-- V: 37
-- W: 153
-- X: 8
-- Y: 29
-- Z: 16
-- T:Z 1500

-- Select from groups, creating three groups in the alphabet that have similar amount of movies
SELECT *
FROM films
WHERE title LIKE ANY (array['A%', 'B%', 'C%', 'D%', 'E%', 'F%', 'G%', 'H%']);

-- (array['I%', 'J%', 'K%', 'L%', 'M%', 'N%', 'O%', 'P%', 'M%', 'N%', 'O%', 'P%'])
-- (array['T%', 'U%', 'V%', 'W%', 'X%', 'Y%', 'Z%'])

-- SECOND QUESTION: filter by "median" year weighted by number of movies
SELECT *
FROM films
WHERE title LIKE ANY (array['A%', 'B%', 'C%', 'D%', 'E%', 'F%', 'G%', 'H%'])
AND release_year > 2005;
-- IF false construct on : WHERE release_year < 2005

-- Third question: divide the list in duration < or > than 100 minutes
-- This divides more or less in half again the list of movies in all cases considered before
SELECT *
FROM films
WHERE title LIKE ANY (array['A%', 'B%', 'C%', 'D%', 'E%', 'F%', 'G%', 'H%'])
AND release_year > 2005
AND duration > 100;
-- USA always have more movies than all the other countries put together
-- in all three groups of the alphabet and for both before and after 2005


-- Fourth question:
-- Trying to narrow down the first letter of the tables
-- (array['C%', 'D%', 'E%'])
-- (array['F%', 'G%', 'H%'])
-- For every case we get to around 140/150 movies remaining
SELECT *
FROM films
WHERE title LIKE ANY (array['A%', 'B%'])
AND release_year > 2005
AND duration > 100;

-- Checking now on gross and budget averages, from this we can ask the next question
SELECT AVG(gross) AS avg_gross, STDDEV_POP(gross) AS SD_gross,  AVG(budget) AS avg_budget, STDDEV_POP(budget) as SD_budget
FROM films
WHERE title LIKE ANY (array['A%', 'B%'])
AND release_year > 2005
AND duration > 100
AND budget IS NOT NULL
AND gross IS NOT NULL;


