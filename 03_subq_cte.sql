-- A subquery is just a SELECT statement nested inside another SQL statement. It runs first 
-- type of outputs from the sub query
	-- 


-- places where a subquery can live
-- 1. in SELECT -> when we want to value to repeat for all rows
select name, salary ,(select avg(salary) from employees) as cavg from employees;
-- 2. in WHERE
  SELECT name, salary
  FROM employees
  WHERE salary > (SELECT AVG(salary) FROM employees);

-- 3. in FROM
-- The subquery acts as a temporary table the outer query reads from.

  SELECT dept, max_sal
  FROM (
      SELECT department AS dept, MAX(salary) AS max_sal
      FROM employees
      GROUP BY department
  ) AS dept_max;
  
  
  
  -- scalar sub Q - is a subquery that returns exactly one value — 1 row, 1 column.
    SELECT name, salary - (SELECT AVG(salary) FROM employees) AS diff_from_avg
  FROM employees order by diff_from_avg desc;
  
  -- ways to get that scalar sub Q
  -- aggregates without group by
  select * from employees;
    SELECT COUNT(*) FROM employees; 
  -- select with limit 1
  SELECT salary FROM employees ORDER BY salary DESC LIMIT 1;
  -- either make it scalar (use MAX, MIN, LIMIT 1), or switch from = to IN:
      SELECT * FROM employees
  WHERE salary IN (SELECT salary FROM employees WHERE department = 'Engineering')
-- in a sub query if there are no results it returns null, which fails in where comparison in outer queries
  
  select name, salary from employees where salary = (select max(salary) from employees);
  --   A scalar subquery in SELECT or WHERE (without correlation) typically runs once and the database caches the result.
  
  
-- IN and NOT IN Subqueries 
  --   IN is just shorthand for many ORs. 
    SELECT * FROM customers
  WHERE city IN ('Mumbai', 'Delhi', 'Hyderabad');
-- customer who have atleast 1 policy
select * from customers where id in (select customer_id from policies);
--  the subquery must return exactly one column. IN compares one value to a list of one-column values.
  -- Customers who have NO policy
  SELECT * FROM customers
  WHERE id NOT IN (SELECT customer_id FROM policies where );

-- NOT IN + NULL trap
-- is the sub Q result has null and we are using not it, it will always fail, cause
-- NOT IN is rewritten internally as a chain of ANDs:
--   id != 1 AND id != 2 AND id != NULL
-- and the id != NULL will always fail
-- fix for the  NOT IN with NULLs
-- 1. use is not null in the subquery
-- 2. Use NOT EXISTS -> immune to this prob

  SELECT * FROM customers c
  WHERE NOT EXISTS (
      SELECT 1 FROM policies p WHERE p.customer_id = c.id
  );
  
  
  -- multi col IN -  we can use tuple comparison
  
  select * from customers where (city,year(signup_date)) in (('Mumbai', 2023), ('Delhi', 2023));
  
  -- EXISTS only does a boolean check , doesn't use those values
  --   EXISTS (subquery) is true if the subquery produces ≥ 1 row, false if it produces 0 rows.
  
  
select * from customers c where not exists (select 1 from policies p where p.customer_id = c.id);
-- The number 1 is just a placeholder., cause we dont use that result, only boolean check
-- EXISTS is almost always correlated
  
-- Customers who have at least one APPROVED claim above 5000
select c.*,cl.amount from customers c where exists (select 1 from policies p join claims cl on p.id = cl.policy_id where c.id = p.customer_id and cl.status = 'approved' and cl.amount > 1000);


-- policies that never had a cliam
select * from policies p where not exists (select 1 from claims cl where cl.policy_id = p.id);

--   ▎ EXISTS = "does at least one row exist?" → TRUE/FALSE.
--   ▎ Always correlated (references outer row).
--   ▎ NOT EXISTS is the safe default for "find rows with no match."


-- EMPLOYEES EARNGIN ABOVE THERE DEPARTMENT AVG
select * from employees e1 where e1.salary > (select avg(salary) from employees e2 where e1.department = e2.department);

select * from employees e1 where e1.salary < (select max(salary) from employees e2);


-- 2nd max sal
select * from employees e order by salary desc limit 1 offset 1;
-- it doesn;t handle duplicates
select max(salary) from employees e where e.salary < (select max(salary) from employees);

select * from employees e where e.salary = (select max(salary) from employees e where e.salary < (select max(salary) from employees));


 select  * from employees e1 where
 e1.salary = (select max(e2.salary) from employees e2 where e2.department  = e1.department 
 and e2.salary < (select max(e3.salary) from employees e3 where e3.department = e1.department)) order by salary desc;
 
 
 
 create table a (id int);
  create table b (id int);
 
 insert into a values (1),(2),(null), (1),(2);
 
 insert into b values (1),(2),(null);
 
 select * from a inner join b on a.id = b.id;
 
  select count(*) from a left join b on a.id = b.id;
 
    select * from a right join b on a.id = b.id;
 
    select * from a full outer join b on a.id = b.id;