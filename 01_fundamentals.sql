CREATE DATABASE IF NOT EXISTS sql_practice;
use sql_practice;
SELECT DATABASE();


show tables;

-- select * from information_schema.tables;

-- exucution order: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
-- FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
-- hence: SELECT runs after WHERE → aliases or computed columns are not available in WHERE
-- WHERE runs before GROUP BY → you cannot filter using aggregates (use HAVING instead)
--- GROUP BY collapses rows into one row per group, so every SELECT column must either be part of the grouping key (single or composite) or be aggregated into a single value — otherwise SQL cannot decide which value to return.
-- HAVING runs after grouping → it cannot filter individual rows, only groups
-- ORDER BY runs after SELECT → it can use aliases and computed values
-- GROUP BY multiple columns creates groups based on their combined values (composite key), and each group must resolve to a single row via grouping or aggregation.
-- HAVING filters aggregated groups after GROUP BY, so it cannot directly filter individual row values unless they are aggregated.

-- creating test data
create table if not exists employees (
	id INT primary key AUTO_INCREMENT,
	name varchar(50),
	department varchar(50),
	salary INT,
	manager_id INT,
	hire_date DATE
);

INSERT INTO employees (name, department, salary, manager_id, hire_date) VALUES
('Jagadeeswar', 'Engineering', 70000, NULL, '2022-01-10'),
('Arjun', 'Engineering', 80000, 1, '2021-03-15'),
('Sneha', 'HR', 50000, NULL, '2020-07-20'),
('Ravi', 'Sales', 60000, 3, '2023-02-01'),
('Priya', 'Engineering', 90000, 1, '2019-11-11'),
('Kiran', 'Sales', 55000, 4, '2022-06-30'),
('Anita', 'HR', 52000, NULL, '2021-08-25'),
('Vikram', 'Engineering', 75000, 1, '2023-01-01');


INSERT INTO employees (name, department, salary, manager_id, hire_date) VALUES
('john', 'Engineering', 80000, NULL, '2021-01-10');

select * from employees;

select * from employees where department = 'Engineering';
select * from employees where salary > 70000;
select * from employees where salary > 75000 and department = 'Engineering';
select * from employees where name like 'J%';
-- case sensitive matching
select * from employees where cast(name as binary) like 'j%';
-- or 
select * from employees where name collate utf8mb4_bin like 'j%';

-- COLLATE defines comparison rules (case/accent sensitivity), while utf8mb4 defines how text is encoded and stored.

-- like
-- % -> anything of any length
-- _ -> anything of certain length
-- like is case-insensitive in mySQL, for strict matching use cast to binary -> WHERE CAST(name AS BINARY) LIKE 'J%'
-- SELECT @@collation_database; => gives current collation setting, case insensive and accent insensitive and the encoding config!

select * from employees where manager_id is null;
-- null means not equal to anything, shouldn't use = for null, use is null and is not null


-- group by
select department, count(manager_id) as cnt from employees group by department;

-- agg
-- COUNT(*)              -- counts all rows including NULLs
-- COUNT(column)         -- counts non-NULL values
-- COUNT(DISTINCT col)   -- counts unique non-NULL values
-- SUM(column)
-- AVG(column)
-- MIN(column)
-- MAX(column)

select department, avg(salary) as avg_sal from employees group by department having avg(salary) > 65000;


select * from employees where salary > 70000 and department = 'Engineering';



-- order by and limit
 select * from employees order by salary desc limit 3;




-- combined
select department , count(*) as cnt, avg(salary) as avg_sal  from employees where salary > 60000 group by department having count(*) > 2 order by avg_sal desc;


-- composite grouping
SELECT department, manager_id, COUNT(*)
FROM employees
GROUP BY department, manager_id;
-- creates a commposing grouping -> give count for each unique pair of dept and manager.
-- GROUP BY rule => every col in select just be in the grp by clause or in an aggregate!



-- order by -> asc by default

-- multi col order by
select * from employees order by  department asc, salary desc;
-- in multi col => 
-- Step 1: group by department (sorted)
-- Step 2: inside each department → sort by salary DESC

-- order by runs after select, so we can use aliases  and aggregates(using aggregate alias)
select
	department,
	COUNT(*) as cnt
from
	employees
group by
	department
order by
	cnt desc;

-- limit -> runs last, after sorting
SELECT * 
FROM employees
ORDER BY salary DESC
LIMIT 3;

-- offset => skiping first n rows
SELECT * 
FROM employees
ORDER BY salary DESC
LIMIT 3 offset 3;
--  3 rows after first 3.

-- pagination pattern => 
-- LIMIT page_size OFFSET (page_number - 1) * page_size

SELECT * FROM employees LIMIT 3;


-- STRING FUNCTIONS
SELECT name, UPPER(name), LOWER(name)
FROM employees;

SELECT name, LENGTH(name) as nameL FROM employees where LENGTH(name) > 4 order by nameL desc;

SELECT CONCAT(name, ' - ', department) as 'name&department'
FROM employees;

select substring(name,1,5) from employees;
SELECT TRIM('   hello   ');

SELECT REPLACE(name, 'a', 'A') as 'replaced' FROM employees;

-- Number functions

select
	round(3.567, 2);

SELECT CEIL(3.2);   -- 4
SELECT FLOOR(3.7);  -- 3
SELECT ABS(-5);  -- 5
SELECT MOD(11, 3);  -- 1


-- date functions
select now();
SELECT CURDATE();

select year(hire_date), month(hire_date) from employees;

select year(hire_date) as hire_year, count(*) as hireCnt from employees group by year(hire_date) order by hireCnt desc;

select year(hire_date) as hire_year, count(*) as hireCnt from employees group by year(hire_date) having count(*) >= 2 order by hireCnt desc;


-- datediff
select datediff(curdate(),hire_date) from employees;

-- to get month or year diff, use timestampdiff

select timestampdiff(month,hire_date,CURDATE()) from employees;
select timestampdiff(year,hire_date, CURDATE()) from employees;


-- practice set
-- 1. Find all employees in 'Engineering' department.
select * from employees where lower(department) = 'engineering';
-- lower => breaks index
-- checking collation
select @@collation_database;
-- 2. Find employees whose name starts with 'J' and salary > 50000.
select * from employees where cast(name as binary) like 'J%' and salary > 50000;
select * from employees where name collate utf8mb4_bin like 'J%' and salary > 50000;

-- 3. Count employees per department.
select department, count(*) from employees group by department;
-- 4. Find departments with average salary > 60000.
select department, avg(salary) from employees group by department having avg(salary) > 60000;
-- 5. Top 3 highest-paid employees.
select * from employees order by salary desc limit 3 ;

-- 6. Employees who don't have a manager (manager_id IS NULL).
select * from employees where manager_id is null;
-- 7. Total salary paid per department, sorted descending.
select department, sum(salary) as total_sal from employees group by department order by total_sal desc;
-- 8. Number of employees hired each year.
select year(hire_date) as hire_year, count(*) from employees group by year(hire_date) order by hire_year;



select @@collation_database;
select @@version;
select @@sql_mode;

-- @@ are used to access variables in db, @@ for system vars, @ for user vars
set @var1 = 2;
select @var1;
-- lifetime of user vars is session -> resets on connection restart
-- cant drop/destroy explicitly, just set to NULL
