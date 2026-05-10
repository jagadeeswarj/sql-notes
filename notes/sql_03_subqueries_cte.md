# SQL 03 — Subqueries & CTEs
> **Time budget**: 1.5 hours
> **Goal**: Master subqueries (scalar, IN, EXISTS, correlated) and CTEs (WITH)

---

## 1. What is a subquery? (10 min)

A query inside another query. Three places they live:

```sql
-- In SELECT (scalar subquery — returns 1 value)
SELECT name, (SELECT AVG(salary) FROM employees) AS avg_sal
FROM employees;

-- In WHERE (most common)
SELECT * FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- In FROM (derived table)
SELECT dept, max_sal
FROM (SELECT department AS dept, MAX(salary) AS max_sal
      FROM employees GROUP BY department) AS dept_max;
```

---

## 2. Scalar subquery (15 min)

Returns ONE value (1 row, 1 column).

```sql
-- Find employees earning more than the average
SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Top earner's department
SELECT department FROM employees
WHERE salary = (SELECT MAX(salary) FROM employees);
```

**Trap**: if subquery returns multiple rows, this fails. Use `IN` or `EXISTS` instead.

---

## 3. IN, NOT IN subqueries (20 min)

```sql
-- Customers who have at least one claim
SELECT * FROM customers
WHERE id IN (SELECT customer_id FROM policies WHERE id IN
             (SELECT policy_id FROM claims));

-- Cleaner with joins, but IN works for OAs
SELECT * FROM customers
WHERE id IN (SELECT customer_id FROM policies);

-- Customers with NO policies
SELECT * FROM customers
WHERE id NOT IN (SELECT customer_id FROM policies WHERE customer_id IS NOT NULL);
```

**Trap with NOT IN**: if the subquery returns ANY NULL, NOT IN returns NOTHING.
- Always add `WHERE col IS NOT NULL` inside the subquery.
- Or prefer `NOT EXISTS`.

---

## 4. EXISTS, NOT EXISTS (15 min)

Checks for existence — returns TRUE/FALSE.

```sql
-- Customers who have at least one policy
SELECT * FROM customers c
WHERE EXISTS (SELECT 1 FROM policies p WHERE p.customer_id = c.id);

-- Customers with NO policies (safer than NOT IN)
SELECT * FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM policies p WHERE p.customer_id = c.id);
```

**Why `SELECT 1`?** EXISTS only checks if rows exist — actual columns don't matter. Convention: `SELECT 1`.

---

## 5. Correlated subquery (20 min)

Subquery that references the outer query.

```sql
-- Employees earning more than their department's average
SELECT name, department, salary
FROM employees e1
WHERE salary > (
    SELECT AVG(salary) FROM employees e2
    WHERE e2.department = e1.department      -- correlation
);
```

**How it runs**: For each row in outer query, the inner query runs again with the current row's values. Slow but powerful.

**Common pattern: highest in each group**
```sql
-- Top earner in each department
SELECT name, department, salary
FROM employees e1
WHERE salary = (
    SELECT MAX(salary) FROM employees e2
    WHERE e2.department = e1.department
);
```

---

## 6. CTE — WITH clause (20 min)

Same as a subquery in FROM, but readable.

```sql
-- Without CTE (ugly)
SELECT dept, max_sal FROM
(SELECT department AS dept, MAX(salary) AS max_sal FROM employees GROUP BY department) sub
WHERE max_sal > 100000;

-- With CTE (clean)
WITH dept_max AS (
    SELECT department, MAX(salary) AS max_sal
    FROM employees
    GROUP BY department
)
SELECT department, max_sal
FROM dept_max
WHERE max_sal > 100000;
```

**Multi-CTE**:
```sql
WITH
high_earners AS (
    SELECT * FROM employees WHERE salary > 100000
),
dept_count AS (
    SELECT department, COUNT(*) AS cnt FROM high_earners GROUP BY department
)
SELECT * FROM dept_count WHERE cnt > 5;
```

**Why CTEs in OAs**: cleaner code = easier to debug under time pressure.

---

## 7. Practice Set (30 min)

Schema:
```
employees(id, name, department, salary, manager_id, hire_date)
projects(id, name, lead_id)         -- lead_id → employees.id
assignments(employee_id, project_id, hours)
```

Solve:

1. Employees earning above company average.
2. Employees earning above their department's average.
3. Departments with at least one employee earning > 200000.
4. Employees who lead at least one project.
5. Employees who are NOT assigned to any project.
6. Top earner per department.
7. Departments where avg salary > avg salary across the whole company.
8. Employees and the count of projects they're assigned to (use CTE).
9. Top 3 highest-paid employees per department (use ROW_NUMBER — see next file).

**Solutions**:

```sql
-- 1
SELECT name, salary FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- 2 (correlated)
SELECT name, department, salary
FROM employees e1
WHERE salary > (SELECT AVG(salary) FROM employees e2 WHERE e2.department = e1.department);

-- 3
SELECT DISTINCT department FROM employees
WHERE department IN (SELECT department FROM employees WHERE salary > 200000);

-- 4
SELECT * FROM employees
WHERE id IN (SELECT lead_id FROM projects WHERE lead_id IS NOT NULL);

-- Better: EXISTS
SELECT * FROM employees e
WHERE EXISTS (SELECT 1 FROM projects p WHERE p.lead_id = e.id);

-- 5
SELECT * FROM employees e
WHERE NOT EXISTS (SELECT 1 FROM assignments a WHERE a.employee_id = e.id);

-- 6 (correlated)
SELECT name, department, salary FROM employees e1
WHERE salary = (SELECT MAX(salary) FROM employees e2 WHERE e2.department = e1.department);

-- 7
WITH company_avg AS (SELECT AVG(salary) AS sal FROM employees),
     dept_avg AS (SELECT department, AVG(salary) AS dsal FROM employees GROUP BY department)
SELECT department FROM dept_avg, company_avg
WHERE dept_avg.dsal > company_avg.sal;

-- 8
WITH proj_count AS (
    SELECT employee_id, COUNT(DISTINCT project_id) AS cnt
    FROM assignments GROUP BY employee_id
)
SELECT e.name, COALESCE(pc.cnt, 0) AS project_count
FROM employees e
LEFT JOIN proj_count pc ON e.id = pc.employee_id;
```

---

## Cheatsheet

```
Scalar subquery:  returns 1 value, used in WHERE/SELECT
IN:               column IN (subquery returning many rows)
NOT IN:           DANGEROUS with NULLs — prefer NOT EXISTS
EXISTS / NOT EXISTS:   safer for "has match" / "no match"
Correlated:       inner query references outer (slower but powerful)
CTE (WITH):       readable named subquery, can be multi
```

---

## Next: `sql_04_window_functions.md` (1.5 hr)
