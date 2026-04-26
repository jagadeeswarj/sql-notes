CREATE DATABASE IF NOT EXISTS sql_practice;
use sql_practice;
SELECT DATABASE();


show tables;

-- select * from information_schema.tables;

-- exucution order: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT



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


select * from employees;