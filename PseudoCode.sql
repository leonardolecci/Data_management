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

-- (array['I%', 'J%', 'K%', 'L%', 'M%', 'N%', 'O%', 'P%', 'Q%', 'R%', 'S%', 'I%'])
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
-- (array['I%', 'J%', 'K%', 'L%'])
-- (array['M%', 'N%', 'O%', 'P%'])
-- (array['Q%', 'R%', 'S%', 'I%'])
-- (array['T%', 'U%'])
-- (array['V%', 'W%', 'X%'])
-- (array['Y%', 'Z%'])
-- For every case we get to around 140/150 movies remaining
SELECT *
FROM films
WHERE title LIKE ANY (array['A%', 'B%'])
AND release_year > 2005
AND duration > 100;

-- Checking now on gross and budget averages, from this we can ask the next question
SELECT country, certification, PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY gross) AS median_gross, AVG(gross) AS avg_gross, STDDEV(gross) AS SD_gross, PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY budget) AS median_budget, AVG(budget) AS avg_budget, STDDEV(budget) as SD_budget, COUNT(*) AS n_movies
FROM films
WHERE title LIKE ANY (array['A%', 'B%'])
AND release_year > 2005
AND duration > 100
AND budget IS NOT NULL
AND gross IS NOT NULL
GROUP BY country, certification
ORDER BY n_movies DESC;

SELECT country, PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY gross) AS median_gross, AVG(gross) AS avg_gross, STDDEV(gross) AS SD_gross, PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY budget) AS median_budget, AVG(budget) AS avg_budget, STDDEV(budget) as SD_budget, COUNT(*) AS n_movies
FROM films
WHERE title LIKE ANY (array['A%', 'B%'])
AND release_year > 2005
AND duration > 100
AND budget IS NOT NULL
AND gross IS NOT NULL
GROUP BY country
ORDER BY n_movies DESC;


-- Fifth question:
-- Once understood the median for each country and certification, and only for country
-- we want to ask if the budget is greater/lower than the median for the country with highest number of movies left
-- this will allow us to have a better understanding also of the country whe the movies was produced in
-- due to the rules of the game we will ask if the movie was produced in the country with most candidates (aka USA most likely)

SELECT *
FROM films
WHERE title LIKE ANY (array['A%', 'B%'])
AND release_year > 2005
AND duration > 100
AND country = /* insert country*/;

--Sixth question:
-- Once we understand the country we can divide in half the candidate by asking if the movie has gross greater or lower than the median

SELECT *
FROM films
WHERE title LIKE ANY (array['A%', 'B%'])
AND release_year > 2005
AND duration > 100
AND country = /* insert country*/
AND gross > /* insert median*/;

-- Run a check of what's left grouping by certification
SELECT certification, COUNT(*) AS n_left
FROM films
WHERE title LIKE ANY (array['A%', 'B%'])
AND release_year > 2005
AND duration > 100
AND country = 'USA'
AND gross > 25000000
GROUP BY certification;

-- Sixth question:
-- Trying to filter by asking if the movie is contained in the most frequent observation of the attribute certification

SELECT *
FROM films
WHERE title LIKE ANY (array['A%', 'B%'])
AND release_year > 2005
AND duration > 100
AND country = 'USA'
AND gross > 25000000
AND certification ='R';

-- Seventh question:
-- filter per budget so first run a check on the descriptive statistics

SELECT PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY gross) AS median_gross, AVG(gross) AS avg_gross, STDDEV(gross) AS SD_gross, PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY budget) AS median_budget, AVG(budget) AS avg_budget, STDDEV(budget) as SD_budget, COUNT(*) AS n_movies
FROM films
WHERE title LIKE ANY (array['A%', 'B%'])
AND release_year > 2005
AND duration > 100
AND budget IS NOT NULL
AND gross IS NOT NULL
AND country = 'USA'
AND gross > 25000000
AND certification ='R'
ORDER BY n_movies DESC;

-- Now the question:

SELECT *
FROM films
WHERE title LIKE ANY (array['A%', 'B%'])
AND release_year > 2005
AND duration > 100
AND country = /* insert country*/
AND gross > /* insert median*/
AND certification =/* insert most frequent certfication*/
AND budget > /* insert median*/;

-- From here we can ask specific question about the title as well


