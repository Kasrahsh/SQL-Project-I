-- Create a new database named 'projects' for storing project-related data
CREATE DATABASE projects;

-- Switch to the 'projects' database to perform further operations
USE projects;

-- Display all records from the 'hr' table to inspect the initial data
SELECT * FROM hr;

-- Data Cleaning Process

--  Rename the 'ï»¿id' column to 'emp_id' due to special characters in the column name.
-- Changing the data type to VARCHAR(20) to accommodate potential non-numeric IDs.
ALTER TABLE hr 
CHANGE COLUMN ï»¿id emp_id VARCHAR(20) NULL;

-- Verify the structure of the 'hr' table after the column change
DESCRIBE hr;

--  Standardize the 'birthdate' column by converting different date formats to 'YYYY-MM-DD'.
-- This ensures consistency and accuracy across all date records in the 'birthdate' column.
SET sql_safe_updates = 0;
UPDATE hr 
SET birthdate = CASE 
    WHEN birthdate LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(birthdate, '%m/%d/%Y'),'%Y-%m-%d')
    WHEN birthdate LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(birthdate, '%m-%d-%Y'),'%Y-%m-%d')
    ELSE NULL 
END;
SELECT birthdate FROM hr;
-- Modify the 'birthdate' column's data type to DATE for proper date handling
ALTER TABLE hr 
MODIFY COLUMN birthdate DATE;

--  Standardize the 'hire_date' column similar to 'birthdate', converting to 'YYYY-MM-DD'.
-- This ensures uniform date formatting for employee hire dates.
UPDATE hr 
SET hire_date = CASE 
    WHEN hire_date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(hire_date, '%m/%d/%Y'),'%Y-%m-%d')
    WHEN hire_date LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(hire_date, '%m-%d-%Y'),'%Y-%m-%d')
    ELSE NULL 
END;
SELECT hire_date FROM hr;
DESCRIBE hr;
--  Investigate and clean up the 'termdate' column, converting valid dates and handling missing values.
-- Non-empty dates are formatted to 'YYYY-MM-DD', and empty values are set to '0000-00-00'.
SELECT termdate FROM hr;

UPDATE hr
SET termdate = IF(termdate IS NOT NULL AND termdate != '', DATE(STR_TO_DATE(termdate, '%Y-%m-%d %H:%i:%s UTC')), '0000-00-00')
WHERE true;

-- Display the cleaned 'termdate' data for verification
SELECT termdate FROM hr;

-- Set SQL mode to allow invalid dates to handle specific cases where necessary
SET sql_mode = 'ALLOW_INVALID_DATES';

-- Change 'termdate' column's data type to DATE for consistency
ALTER TABLE hr
MODIFY COLUMN termdate DATE;

--  Add a new 'age' column to the 'hr' table to store the calculated age of each employee.
ALTER TABLE hr ADD COLUMN age INT;

-- Calculate and populate the 'age' column based on the 'birthdate' and current date
UPDATE hr 
SET age = TIMESTAMPDIFF(YEAR, birthdate, CURDATE());

-- Retrieve the youngest and oldest ages among employees
SELECT 
    MIN(age) AS youngest, 
    MAX(age) AS oldest
FROM hr;

-- Count the number of employees who are under 18 years old
SELECT COUNT(*) FROM hr WHERE age < 18;

-- : Calculate the gender breakdown of employees who are currently employed( and logically are aged 18 or older)
SELECT gender, COUNT(*) AS count 
FROM hr 
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY gender;

-- : Calculate the breakdown of employees by race and ethnicity, showing the most common groups first
SELECT race, COUNT(*) AS count 
FROM hr 
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY race
ORDER BY count DESC;

-- : Group employees into age brackets to visualize the age distribution within the company

SELECT 
		MIN(age) AS youngest,
		MAX(age) AS oldest 
FROM hr 
WHERE age >= 18 AND termdate = '0000-00-00';

SELECT 
    CASE
        WHEN age BETWEEN 18 AND 24 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        WHEN age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS age_group, 
    COUNT(*) AS count 
FROM hr 
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY age_group
ORDER BY age_group;

-- : Analyze the distribution of employees by age group and gender
SELECT 
    CASE
        WHEN age BETWEEN 18 AND 24 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        WHEN age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS age_group, 
    gender,
    COUNT(*) AS count 
FROM hr 
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY age_group, gender
ORDER BY age_group, gender;

-- : Count the number of employees working at each location, distinguishing between headquarters and remote
SELECT location, COUNT(*) AS count
FROM hr 
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY location;

-- : Calculate the average length of employment in years for employees who have been terminated
SELECT 
    ROUND(AVG(DATEDIFF(termdate, hire_date) / 365), 0) AS avg_length_employment 
FROM hr 
WHERE termdate <= CURDATE() AND termdate <> '0000-00-00' AND age >= 18;

-- : Show the gender distribution across different job titles and departments
SELECT department, gender, COUNT(*) AS count 
FROM hr 
WHERE age >= 18 AND termdate = '0000-00-00' 
GROUP BY department, gender
ORDER BY department;

-- : Count the number of employees in each job title, ordering by job title in descending order
SELECT jobtitle, COUNT(*) AS count 
FROM hr 
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY jobtitle 
ORDER BY jobtitle DESC;

-- : Identify the department with the highest turnover rate by comparing terminations to total employees
SELECT department, total_count, terminated_count, 
       terminated_count / total_count AS termination_rate 
FROM (
    SELECT department, 
           COUNT(*) AS total_count, 
           SUM(CASE WHEN termdate <> '0000-00-00' AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminated_count
    FROM hr 
    WHERE age >= 18
    GROUP BY department
) AS sub 
ORDER BY termination_rate DESC;

-- : Show the distribution of employees by city and state, sorted by the number of employees
SELECT location_state, COUNT(*) AS count
FROM hr 
WHERE age >= 18 AND termdate = '0000-00-00'
GROUP BY location_state
ORDER BY count DESC;

-- : Track the change in employee count over time, based on yearly hires and terminations
SELECT 
    year,
    hires,
    terminations,
    hires - terminations AS net_change,
    ROUND(((hires - terminations) / hires) * 100, 2) AS net_percentage_change 
FROM (
    SELECT YEAR(hire_date) AS year, 
           COUNT(*) AS hires, 
           SUM(CASE WHEN termdate <> '0000-00-00' AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminations
    FROM hr 
    WHERE age >= 18
    GROUP BY YEAR(hire_date)
) AS sub 
ORDER BY year ASC;

-- : Calculate the average tenure (in years) for each department, focusing on terminated employees
SELECT department, ROUND(AVG(DATEDIFF(termdate, hire_date) / 365), 0) AS avg_tenure 
FROM hr
WHERE termdate <= CURDATE() AND termdate <> '0000-00-00' AND age >= 18
GROUP BY department;
