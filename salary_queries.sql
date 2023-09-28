-- Which job titles have the highest average pay in recent years?
SELECT job_title,
        AVG(salary) avg_salary
FROM salaries
WHERE DATE_TRUNC('year', submit_date) >= '2017-01-01'
        AND salary > 11.8 * 20 * 52 --Minimum wage
        AND case_status = 'CERTIFIED'
GROUP BY job_title
ORDER BY avg_salary DESC;

--Which job title seems poised for the most salary growth?
WITH prev_salaries AS (
        SELECT job_title,
                DATE_TRUNC('year', submit_date) curr_year,
                AVG(salary) curr_salary,
                LAG(AVG(salary)) OVER (PARTITION BY job_title ORDER BY DATE_TRUNC('year',submit_date)) prev_salary,
                COUNT(salary) num_salaries
        FROM salaries
        WHERE salary > 11.8 * 20 * 52
                AND case_status = 'CERTIFIED'
        GROUP BY job_title, curr_year
        ORDER BY job_title, curr_year
        ),

growth_per_title AS (
        SELECT job_title,
                curr_year,
                ROUND(100.0 * (curr_salary - prev_salary) / prev_salary, 2) yoy_growth,
                num_salaries
        FROM prev_salaries
        ORDER BY job_title, curr_year
        )

SELECT job_title,
        SUM(CASE WHEN EXTRACT(YEAR FROM curr_year) = 2017 THEN yoy_growth ELSE NULL END) growth_2017,
        SUM(CASE WHEN EXTRACT(YEAR FROM curr_year) = 2018 THEN yoy_growth ELSE NULL END) growth_2018,
        SUM(CASE WHEN EXTRACT(YEAR FROM curr_year) = 2019 THEN yoy_growth ELSE NULL END) growth_2019,
        SUM(CASE WHEN EXTRACT(YEAR FROM curr_year) = 2020 THEN yoy_growth ELSE NULL END) growth_2020,
        SUM(CASE WHEN EXTRACT(YEAR FROM curr_year) = 2021 THEN yoy_growth ELSE NULL END) growth_2021,
        AVG(CASE WHEN curr_year >= '2017-01-01' THEN yoy_growth END) avg_growth,
        SUM(num_salaries) num_salaries
FROM growth_per_title
GROUP BY job_title
ORDER BY avg_growth DESC;


--During what period are the highest salaries offered?
SELECT EXTRACT(QUARTER FROM submit_date) qtr,
        AVG(salary) avg_salary
FROM salaries
WHERE salary > 11.8 * 20 * 52
        AND case_status = 'CERTIFIED'
        AND EXTRACT(YEAR FROM submit_date) >= 2017
GROUP BY qtr
ORDER BY qtr;


--During what period are the highest salaries offered for each job title?
SELECT EXTRACT(QUARTER FROM submit_date) qtr,
        job_title,
        AVG(salary) avg_salary
FROM salaries
WHERE salary > 11.8 * 20 * 52
        AND case_status = 'CERTIFIED'
GROUP BY qtr, job_title
ORDER BY job_title, qtr;


--------------------------------------------------------------------------------
-- Other queries I that explored but didn't provide valuable enough insights;
-- there were no evident correlations,
-- or the level of detail had too few data points per group
--------------------------------------------------------------------------------


--Which locations have the highest average pay?
SELECT RIGHT(TRIM(TRAILING FROM location), 2) state,
        AVG(salary) avg_salary,
        COUNT(salary) num_salaries
FROM salaries
WHERE salary > 11.8 * 20 * 52
        AND case_status = 'CERTIFIED'
GROUP BY state
ORDER BY avg_salary DESC;


--What is the average pay for a given job title in a given location?
SELECT job_title,
        RIGHT(TRIM(TRAILING FROM location), 2) state,
        AVG(salary) avg_salary,
        COUNT(salary) num_salaries
FROM salaries
WHERE salary > 11.8 * 20 * 52
        AND case_status = 'CERTIFIED'
GROUP BY state, job_title
ORDER BY job_title, avg_salary DESC;


--What are the year-over-year changes in average salary per state?
WITH prev_salaries AS (
        SELECT RIGHT(TRIM(TRAILING FROM location), 2) state,
                DATE_TRUNC('year', submit_date) curr_year,
                AVG(salary) curr_salary,
                LAG(AVG(salary)) OVER
                        (PARTITION BY RIGHT(TRIM(TRAILING FROM location), 2)
                        ORDER BY DATE_TRUNC('year',submit_date)) prev_salary,
                COUNT(salary) num_salaries
        FROM salaries
        WHERE salary > 11.8 * 20 * 52
                AND case_status = 'CERTIFIED'
        GROUP BY state, curr_year
        ORDER BY state, curr_year
        ),

growth_by_state AS (
        SELECT state,
                curr_year,
                (curr_salary - prev_salary) / prev_salary::decimal * 100 yoy_growth
        FROM prev_salaries
        WHERE num_salaries > 10
        ORDER BY state, curr_year
        )
        
SELECT state,
        SUM(CASE WHEN EXTRACT(YEAR FROM curr_year) = 2014 THEN yoy_growth ELSE NULL END) growth_2014,
        SUM(CASE WHEN EXTRACT(YEAR FROM curr_year) = 2015 THEN yoy_growth ELSE NULL END) growth_2015,
        SUM(CASE WHEN EXTRACT(YEAR FROM curr_year) = 2016 THEN yoy_growth ELSE NULL END) growth_2016,
        SUM(CASE WHEN EXTRACT(YEAR FROM curr_year) = 2017 THEN yoy_growth ELSE NULL END) growth_2017,
        SUM(CASE WHEN EXTRACT(YEAR FROM curr_year) = 2018 THEN yoy_growth ELSE NULL END) growth_2018,
        SUM(CASE WHEN EXTRACT(YEAR FROM curr_year) = 2019 THEN yoy_growth ELSE NULL END) growth_2019,
        SUM(CASE WHEN EXTRACT(YEAR FROM curr_year) = 2020 THEN yoy_growth ELSE NULL END) growth_2020,
        SUM(CASE WHEN EXTRACT(YEAR FROM curr_year) = 2021 THEN yoy_growth ELSE NULL END) growth_2021
FROM growth_by_state
GROUP BY state;


--For each year, which titles had the highest average salaries?
SELECT job_title,
        DATE_TRUNC('year', submit_date) submit_year,
        AVG(salary) avg_salary
FROM salaries
WHERE salary > 11.8 * 20 * 52
        AND case_status = 'CERTIFIED'
GROUP BY job_title, submit_year
ORDER BY submit_year, avg_salary DESC;


--What are the states with the highest average salaries, for each role and overall?
--By role; noisy
WITH avg_salaries AS (
SELECT job_title,
        RIGHT(TRIM(TRAILING FROM location), 2) state,
        AVG(salary) avg_salary,
        COUNT(salary) num_salaries,
        RANK() OVER (PARTITION BY job_title ORDER BY AVG(salary) DESC) AS rank
FROM salaries
WHERE salary > 11.8 * 20 * 52
        AND case_status = 'CERTIFIED'
GROUP BY job_title, state
HAVING num_salaries > 10
)

SELECT job_title,
        state,
        avg_salary,
        num_salaries
FROM avg_salaries
WHERE rank < 11
ORDER BY job_title, rank;

--Overall; not as noisy
SELECT RIGHT(TRIM(TRAILING FROM location), 2) state,
        AVG(salary) avg_salary,
        COUNT(salary) num_salaries
FROM salaries
WHERE salary > 11.8 * 20 * 52
        AND case_status = 'CERTIFIED'
GROUP BY state
ORDER BY avg_salary DESC;


--What are the year-over year changes in average salary for each title?
WITH prev_salaries AS (
        SELECT job_title,
                DATE_TRUNC('year', submit_date) curr_year,
                AVG(salary) curr_salary,
                LAG(AVG(salary)) OVER (PARTITION BY job_title ORDER BY DATE_TRUNC('year',submit_date)) prev_salary,
                COUNT(salary) num_salaries
        FROM salaries
        WHERE salary > 11.8 * 20 * 52
                AND case_status = 'CERTIFIED'
        GROUP BY job_title, curr_year
        ORDER BY job_title, curr_year
        )

SELECT job_title,
        curr_year,
        (curr_salary - prev_salary) / prev_salary::decimal * 100 yoy_growth,
        num_salaries
FROM prev_salaries
ORDER BY job_title, curr_year;


--How has the overall average data salary changed over time?
SELECT DATE_TRUNC('quarter', submit_date) submit_year,
        ROUND(AVG(salary),2) avg_salary
FROM salaries
WHERE salary > 11.8 * 20 * 52
        AND case_status = 'CERTIFIED'
GROUP BY submit_year
ORDER BY submit_year;


--What are the year-over-year changes in average salary per state?
WITH prev_salaries AS (
        SELECT RIGHT(TRIM(TRAILING FROM location), 2) state,
                DATE_TRUNC('year', submit_date) curr_year,
                AVG(salary) curr_salary,
                LAG(AVG(salary)) OVER
                        (PARTITION BY RIGHT(TRIM(TRAILING FROM location), 2)
                        ORDER BY DATE_TRUNC('year',submit_date)) prev_salary,
                COUNT(salary) num_salaries
        FROM salaries
        WHERE salary > 11.8 * 20 * 52
                AND case_status = 'CERTIFIED'
        GROUP BY state, curr_year
        ORDER BY state, curr_year
        )

SELECT state,
        curr_year,
        (curr_salary - prev_salary) / prev_salary::decimal * 100 yoy_growth,
        num_salaries
FROM prev_salaries
ORDER BY state, curr_year;

