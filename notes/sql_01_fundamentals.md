# SQL 01 — Fundamentals
> **Time budget**: 1.5 hours
> **Goal**: Master SELECT, WHERE, GROUP BY, HAVING, ORDER BY, LIMIT, basic functions

---

## 1. Anatomy of a SELECT query (15 min)

```sql
SELECT column1, column2          -- WHAT to fetch
FROM table_name                  -- FROM where
WHERE condition                  -- FILTER rows BEFORE grouping
GROUP BY column                  -- GROUP rows
HAVING condition                 -- FILTER groups AFTER grouping
ORDER BY column ASC|DESC         -- SORT result
LIMIT n OFFSET m;                -- PAGINATE
```

**Execution order (memorize this — interview favorite!):**
```
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```

**Why it matters**: column aliases defined in SELECT are NOT available in WHERE, but ARE available in ORDER BY.

---

## 2. WHERE — Filtering rows (15 min)

```sql
-- Comparison
SELECT * FROM employees WHERE salary > 50000;
SELECT * FROM employees WHERE name = 'Jagadeeswar';
SELECT * FROM employees WHERE department != 'HR';

-- Logical
SELECT * FROM employees WHERE salary > 50000 AND department = 'Engineering';
SELECT * FROM employees WHERE salary > 50000 OR years_exp > 5;
SELECT * FROM employees WHERE NOT department = 'HR';

-- Range
SELECT * FROM employees WHERE salary BETWEEN 50000 AND 100000;

-- Set membership
SELECT * FROM employees WHERE department IN ('Engineering', 'Sales');
SELECT * FROM employees WHERE department NOT IN ('HR');

-- Pattern matching
SELECT * FROM employees WHERE name LIKE 'J%';      -- starts with J
SELECT * FROM employees WHERE name LIKE '%ar';     -- ends with ar
SELECT * FROM employees WHERE name LIKE '_a%';     -- second letter is 'a'

-- NULL handling (CRITICAL!)
SELECT * FROM employees WHERE manager_id IS NULL;
SELECT * FROM employees WHERE manager_id IS NOT NULL;
-- ❌ WRONG: WHERE manager_id = NULL  (always returns nothing!)
```

**Trap**: `NULL = NULL` returns NULL (not TRUE). Always use `IS NULL`.

---

## 3. Aggregations (20 min)

```sql
COUNT(*)              -- counts all rows including NULLs
COUNT(column)         -- counts non-NULL values
COUNT(DISTINCT col)   -- counts unique non-NULL values
SUM(column)
AVG(column)
MIN(column)
MAX(column)
```

**Examples**:
```sql
-- Total employees
SELECT COUNT(*) FROM employees;

-- Average salary
SELECT AVG(salary) FROM employees;

-- Highest paid in each department
SELECT department, MAX(salary) FROM employees GROUP BY department;
```

---

## 4. GROUP BY (20 min)

**Rule**: Every column in SELECT must be either:
- in GROUP BY, OR
- inside an aggregate function

```sql
-- Count employees per department
SELECT department, COUNT(*) AS emp_count
FROM employees
GROUP BY department;

-- Multi-column grouping
SELECT department, job_title, COUNT(*) AS cnt
FROM employees
GROUP BY department, job_title;

-- Aggregate with WHERE (filters BEFORE grouping)
SELECT department, AVG(salary) AS avg_sal
FROM employees
WHERE hire_date > '2020-01-01'
GROUP BY department;
```

---

## 5. HAVING vs WHERE (15 min)

| WHERE | HAVING |
|-------|--------|
| Filters individual rows | Filters groups |
| Runs BEFORE GROUP BY | Runs AFTER GROUP BY |
| Cannot use aggregate functions | Can use aggregate functions |

```sql
-- Departments with avg salary > 70000
SELECT department, AVG(salary) AS avg_sal
FROM employees
GROUP BY department
HAVING AVG(salary) > 70000;

-- Departments with more than 5 employees, avg salary > 70000
SELECT department, COUNT(*) AS cnt, AVG(salary) AS avg_sal
FROM employees
WHERE status = 'active'           -- filter rows first
GROUP BY department
HAVING COUNT(*) > 5 AND AVG(salary) > 70000;  -- filter groups
```

---

## 6. ORDER BY + LIMIT (10 min)

```sql
-- Sort ascending (default)
SELECT * FROM employees ORDER BY salary;

-- Descending
SELECT * FROM employees ORDER BY salary DESC;

-- Multi-column (sort by dept, then by salary descending)
SELECT * FROM employees ORDER BY department ASC, salary DESC;

-- Top 5 highest paid
SELECT * FROM employees ORDER BY salary DESC LIMIT 5;

-- Pagination: rows 11-20
SELECT * FROM employees ORDER BY id LIMIT 10 OFFSET 10;

-- Sort by aggregate
SELECT department, COUNT(*) AS cnt
FROM employees
GROUP BY department
ORDER BY cnt DESC;
```

---

## 7. String + Number Functions (15 min)

```sql
-- String
UPPER('hello')           -- HELLO
LOWER('HELLO')           -- hello
LENGTH('hello')          -- 5
CONCAT('a', 'b')         -- ab
SUBSTRING('hello', 1, 3) -- hel  (varies by DB: MySQL is 1-indexed)
TRIM('  hi  ')           -- hi
REPLACE('hello', 'l', 'L') -- heLLo

-- Number
ROUND(3.567, 2)          -- 3.57
CEIL(3.2)                -- 4
FLOOR(3.7)               -- 3
ABS(-5)                  -- 5
MOD(10, 3)               -- 1

-- Date
NOW()                    -- current timestamp
CURDATE()                -- current date
YEAR(date_col)
MONTH(date_col)
DATEDIFF(d1, d2)         -- days between dates
```

---

## 8. Practice Set (30 min)

Schema:
```
employees(id, name, department, salary, manager_id, hire_date)
```

Try writing these without looking:

1. Find all employees in 'Engineering' department.
2. Find employees whose name starts with 'J' and salary > 50000.
3. Count employees per department.
4. Find departments with average salary > 60000.
5. Top 3 highest-paid employees.
6. Employees who don't have a manager (manager_id IS NULL).
7. Total salary paid per department, sorted descending.
8. Number of employees hired each year.

**Solutions**:

```sql
-- 1
SELECT * FROM employees WHERE department = 'Engineering';

-- 2
SELECT * FROM employees WHERE name LIKE 'J%' AND salary > 50000;

-- 3
SELECT department, COUNT(*) AS cnt FROM employees GROUP BY department;

-- 4
SELECT department, AVG(salary) AS avg_sal
FROM employees
GROUP BY department
HAVING AVG(salary) > 60000;

-- 5
SELECT * FROM employees ORDER BY salary DESC LIMIT 3;

-- 6
SELECT * FROM employees WHERE manager_id IS NULL;

-- 7
SELECT department, SUM(salary) AS total
FROM employees
GROUP BY department
ORDER BY total DESC;

-- 8
SELECT YEAR(hire_date) AS hire_year, COUNT(*) AS cnt
FROM employees
GROUP BY YEAR(hire_date)
ORDER BY hire_year;
```

---

## Cheatsheet to memorize

```
EXEC ORDER:    FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
NULL:          Use IS NULL / IS NOT NULL (never = NULL)
WHERE vs HAVING: rows vs groups
COUNT(*) vs COUNT(col): * includes NULLs, col doesn't
GROUP BY rule: every non-aggregate SELECT column must be in GROUP BY
```

---

## Next: `sql_02_joins.md` (1.5 hr)
