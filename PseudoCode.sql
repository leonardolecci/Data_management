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

-- CHECKING
SELECT country, COUNT(*) AS n_movies
FROM films
WHERE title LIKE ANY (array['A%', 'B%', 'C%', 'D%', 'E%', 'F%', 'G%', 'H%'])
AND release_year > 2005
GROUP BY country
ORDER BY n_movies DESC;
-- USA always have more movies than all the other countries put together
-- in all three groups of the alphabet and for both before and after 2005


-- THIRD QUESTION: country of movie being in north america (USA, Canada)
SELECT *
FROM films
WHERE title LIKE ANY (array['A%', 'B%', 'C%', 'D%', 'E%', 'F%', 'G%', 'H%'])
AND release_year > 2005
AND country IN ('USA', 'Canada');
