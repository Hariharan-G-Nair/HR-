--Creating a database named projects and added a table hr


CREATE DATABASE project; 

USE project;

SELECT * FROM hr;

--DATA CLEANING PROCESS


--Renaming column id to emp_id
ALTER TABLE hr
CHANGE COLUMN ï»¿id emp_id VARCHAR(20) NULL;


--upon looking at the table,we can find that date format in columns like birhdate,hiredate and termdate are not in th eright format.
--so data we need to fix that and make them into a uniform date format also filling in '0000-00-00' in null values for termdate column

SET sql_safe_updates=0;


UPDATE hr
SET birthdate=CASE
	WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate,'%m/%d/%Y'),'%Y-%m-%d')
	WHEN birthdate LIKE '%-%' THEN date_format(str_to_date(birthdate,'%m-%d-%Y'),'%Y-%m-%d')
ELSE NULL
END;

ALTER TABLE hr
MODIFY COLUMN birthdate DATE;

DESCRIBE hr;

UPDATE hr
SET hire_date=CASE
	WHEN hire_date LIKE '%/%' THEN date_format(str_to_date(hire_date,'%m/%d/%Y'),'%Y-%m-%d')
	WHEN hire_date LIKE '%-%' THEN date_format(str_to_date(hire_date,'%m-%d-%Y'),'%Y-%m-%d')
ELSE NULL
END;

ALTER TABLE hr
MODIFY COLUMN hire_date DATE;


UPDATE hr
SET termdate = IF(termdate IS NOT NULL AND termdate != '', date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC')), '0000-00-00')
WHERE true;

SELECT termdate from hr;

SET sql_mode = 'ALLOW_INVALID_DATES';

ALTER TABLE hr
MODIFY COLUMN termdate DATE;


--Creating a new table called age which contains the age of all the employees

ALTER TABLE hr ADD COLUMN age INT;

UPDATE hr
SET age=timestampdiff(YEAR,birthdate,curdate());






select * 
from hr;

--ANALYSIS


-- QUESTIONS

-- 1. What is the gender breakdown of employees in the company?

SELECT gender,count(*) AS count
FROM hr
WHERE termdate='0000-00-00' AND age>=18
GROUP BY gender;

-- 2. What is the race/ethnicity breakdown of employees in the company?

SELECT race,count(*) AS count
FROM hr
WHERE termdate='0000-00-00' AND age>=18
GROUP BY race
ORDER BY count;


-- 3. What is the age distribution of employees in the company?

SELECT CASE
	WHEN age>=18 AND age<=24 THEN '18-24'
    WHEN age>=25 AND age<=34 THEN '25-34'
    WHEN age>=35 AND age<=44 THEN '35-44'
    WHEN age>=45 AND age<=54 THEN '45-54'
    ELSE '55+'
    END AS age_distribution,count(*) AS count
    FROM hr
    WHERE age>=18 AND termdate='0000-00-00'
    GROUP BY age_distribution
    ORDER BY count DESC;
    
    
-- 4. How many employees work at headquarters versus remote locations?

SELECT location,count(*) as count
FROM hr
WHERE age>=18 AND termdate='0000-00-00'
GROUP BY location
ORDER BY count;



-- 5. What is the average length of employment for employees who have been terminated?

SELECT 
round(AVG(datediff(termdate,hire_date))/365,0) AS avg_length_of_employment
FROM hr
WHERE termdate<=curdate() AND termdate!='0000-00-00' AND age>=18;


-- 6. How does the gender distribution vary across departments and job titles?

SELECT gender,department,jobtitle,count(*) AS count
FROM hr
WHERE age>=18 and termdate='0000-00-00'
GROUP BY gender,department,jobtitle
ORDER BY count DESC;


-- 7. What is the distribution of job titles across the company?

SELECT jobtitle,count(*) as count
FROM hr
WHERE age>=18 and termdate='0000-00-00'
GROUP BY jobtitle
ORDER BY count DESC;


-- 8. Which department has the highest turnover rate?

--"Turnover rate" typically refers to the rate at which employees leave a company or department and need to be replaced. It can be calculated as the number of employees who leave over a given time period divided by the average number of employees in the company or department over that same time period.

SELECT department,total_count,termination_count,termination_count/total_count AS termination_rate
FROM
	(SELECT 
	department,
	count(*) AS total_count,
	SUM(CASE WHEN termdate!='0000-00-00' AND termdate<=curdate() THEN 1 ELSE 0 END) AS termination_count
	FROM hr
	WHERE age>=18
	GROUP BY department) AS subquerry
ORDER BY termination_rate;





-- 9. What is the distribution of employees across locations by city and state?



SELECT location_state,count(*) AS count
FROM hr
WHERE age>=18 AND 	termdate='0000-00-00'
GROUP BY location_state
ORDER BY count DESC;


-- 10. How has the company's employee count changed over time based on hire and term dates?

--This query groups the employees by the year of their hire date and calculates the total number of hires, terminations, and net change (the difference between hires and terminations) for each year. The results are sorted by year in ascending order.

SELECT 
year,
hires,
terminations,
hires/terminations AS net_change,
round((hires-terminations)/hires * 100,2) AS net_change_percentage
FROM (
	SELECT YEAR(hire_date) AS year,
	COUNT(*) AS hires,
	SUM(CASE WHEN termdate!='0000-00-00' AND termdate<=curdate() THEN 1 ELSE 0 END) AS terminations
	FROM hr
	WHERE age>=18 
	GROUP BY YEAR(hire_date)
    )AS subquerry
ORDER BY year;





-- 11. What is the tenure distribution for each department


SELECT department,round(AVG(datediff(termdate,hire_date)/365),0) AS average_tenure
FROM hr
WHERE age>=18 AND termdate!='0000-00-00' AND termdate<=curdate()
GROUP BY department
ORDER BY average_tenure;


--Summary of Findings


-- 1.There are more male employees
-- 2.White race is the most dominant while Native Hawaiian and American Indian are the least dominant.
-- 3.The youngest employee is 20 years old and the oldest is 57 years old
-- 4.Five age groups were created (18-24, 25-34, 35-44, 45-54, 55-64). A large number of employees were between 25-34 followed by 35-44 while the smallest group was 55-64.
-- 5.A large number of employees work at the headquarters versus remotely.
-- 6.The average length of employment for terminated employees is around 7 years.
-- 7.The gender distribution across departments is fairly balanced but there are generally more male than female employees.
-- 8.The Marketing department has the highest turnover rate followed by Training. The least turn over rate are in the Research and development, Support and Legal departments.
-- 9.A large number of employees come from the state of Ohio.
-- 10.The net change in employees has increased over the years.
--11.The average tenure for each department is about 8 years with Legal and Auditing having the highest and Services, Sales and Marketing having the lowest.


--Limitations


-- 1.Some records had negative ages and these were excluded during querying(967 records). Ages used were 18 years and above.
-- 2.Some termdates were far into the future and were not included in the analysis(1599 records). The only term dates used were those less than or equal to the current date.
 
