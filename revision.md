# SQL Revision Notes

Consolidated from `00_test.sql`, `01_fundamentals.sql`, `02_joins.sql`, `03_subq_cte.sql`.

---

## 1. Setup & Database Basics

```sql
SHOW DATABASES;
CREATE DATABASE IF NOT EXISTS sql_practice;
USE sql_practice;
SELECT DATABASE();      -- current db
SHOW TABLES;
```

---

## 2. Logical Execution Order

```
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```

Consequences of this order:

- `SELECT` runs after `WHERE` → **aliases / computed columns NOT available in WHERE**.
- `WHERE` runs before `GROUP BY` → **cannot filter on aggregates in WHERE**, use `HAVING`.
- `HAVING` runs after grouping → filters groups, not individual rows (unless aggregated).
- `ORDER BY` runs after `SELECT` → **CAN use aliases & aggregate aliases**.
- `LIMIT` runs last (after sort).
- `GROUP BY` collapses rows → every `SELECT` column must be in the `GROUP BY` key OR be aggregated.

---

## 3. Filtering — WHERE

```sql
SELECT * FROM employees WHERE department = 'Engineering';
SELECT * FROM employees WHERE salary > 75000 AND department = 'Engineering';
```

### LIKE patterns
- `%` → any chars, any length
- `_` → any single char
- `LIKE` is **case-insensitive** in MySQL by default.
- For strict (case-sensitive) match:
  ```sql
  WHERE CAST(name AS BINARY) LIKE 'J%';
  WHERE name COLLATE utf8mb4_bin LIKE 'J%';
  ```

> `COLLATE` defines comparison rules (case/accent sensitivity).
> `utf8mb4` defines encoding/storage.
> Check current: `SELECT @@collation_database;`

### NULL handling
- `= NULL` and `!= NULL` always fail.
- Use `IS NULL` / `IS NOT NULL`.

```sql
SELECT * FROM employees WHERE manager_id IS NULL;
```

---

## 4. Aggregation & GROUP BY

| Function | Behavior |
|---|---|
| `COUNT(*)` | counts all rows incl. NULLs |
| `COUNT(col)` | counts non-NULL values |
| `COUNT(DISTINCT col)` | counts unique non-NULL values |
| `SUM`, `AVG`, `MIN`, `MAX` | standard |

```sql
SELECT department, AVG(salary) AS avg_sal
FROM employees
GROUP BY department
HAVING AVG(salary) > 65000;
```

### Composite grouping
```sql
SELECT department, manager_id, COUNT(*)
FROM employees
GROUP BY department, manager_id;
```
Group key = combined values of the columns. Each unique pair → one row.

### Functional dependency (MySQL leniency)
MySQL allows selecting non-grouped columns **if** they are functionally dependent on the GROUP BY key (e.g., grouping by `m.id` lets you select `m.name`).

---

## 5. ORDER BY & LIMIT

- `ORDER BY` defaults to `ASC`.
- Multi-column: sorts left-to-right.
  ```sql
  SELECT * FROM employees ORDER BY department ASC, salary DESC;
  ```
- Can use aliases (runs after SELECT).

### Pagination
```sql
LIMIT page_size OFFSET (page_number - 1) * page_size
```

---

## 6. String / Number / Date Functions

```sql
-- String
UPPER(s), LOWER(s), LENGTH(s), CONCAT(a,' ',b)
SUBSTRING(s, start, len), TRIM(s), REPLACE(s, 'a', 'A')

-- Number
ROUND(3.567, 2), CEIL(3.2)=4, FLOOR(3.7)=3, ABS(-5)=5, MOD(11,3)=1

-- Date
NOW(), CURDATE()
YEAR(d), MONTH(d)
DATEDIFF(curdate(), hire_date)               -- days
TIMESTAMPDIFF(MONTH, hire_date, CURDATE())    -- months/years/etc.
```

> Wrapping a column in a function (e.g., `LOWER(department)`) **breaks index usage**.

---

## 7. Variables

- `@@var` → system variable (`@@version`, `@@sql_mode`, `@@collation_database`).
- `@var`  → user/session variable. Lifetime = session. Set to `NULL` to "drop".

```sql
SET @x = 2; SELECT @x;
```

---

## 8. JOINS

Runs **after FROM, before WHERE**. Combines rows by matching keys via `ON`.

| Type | Returns |
|---|---|
| `INNER JOIN` | rows matching in BOTH |
| `LEFT JOIN` | all from LEFT + matched RIGHT (NULL if no match) |
| `RIGHT JOIN` | all from RIGHT + matched LEFT |
| `FULL OUTER JOIN` | all from both (NULL where no match) |
| `CROSS JOIN` | cartesian product |

```sql
-- Implicit cross join (avoid):
SELECT c.color, s.size FROM colors c, sizes s;
-- Everything is cross join by default; ON conditions filter it.
```

### Detecting missing relationships (LEFT JOIN + IS NULL)
```sql
SELECT c.id, c.name
FROM customers c
LEFT JOIN policies p ON c.id = p.customer_id
WHERE p.id IS NULL;     -- customers with no policies
```

> **WHERE kills LEFT JOIN**: any equality/inequality on the right table will eliminate the NULL rows, silently turning it into an INNER JOIN. Use `IS NULL` / `IS NOT NULL`.

### Multi-table chain
```sql
SELECT c.name, p.premium, cl.amount, cl.status, a.name AS agent_name
FROM customers c
INNER JOIN policies p        ON c.id = p.customer_id
INNER JOIN claims cl         ON p.id = cl.policy_id
INNER JOIN customer_agents ca ON c.id = ca.customer_id
INNER JOIN agents a          ON a.id = ca.agent_id;
```

### SELF JOIN
Joining a table to itself (e.g., manager_id refers to same table).

```sql
SELECT e.name AS employee, COALESCE(m.name, 'NO-MANAGER') AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

- `COALESCE(x, fallback)` / `IFNULL(x, fallback)` for null replacement.
- Aliases inside same `SELECT` are **not** visible to other expressions in the same SELECT.

### JOIN with aggregation
```sql
-- Total premium per customer (incl. zero)
SELECT c.id, c.name, COALESCE(SUM(p.premium), 0) AS total_premium
FROM customers c
LEFT JOIN policies p ON c.id = p.customer_id
GROUP BY c.id, c.name
ORDER BY total_premium DESC;
```

`COUNT(*)` vs `COUNT(col)` matters in left-join aggregates: `COUNT(*)` counts the row produced (1 even with no match), `COUNT(p.id)` counts only matched rows (gives 0 correctly).

---

## 9. Subqueries

A SELECT nested inside another statement. Runs first (uncorrelated) or once per outer row (correlated).

### Where they can live
1. **SELECT** — repeats a value across rows
   ```sql
   SELECT name, salary, (SELECT AVG(salary) FROM employees) AS cavg
   FROM employees;
   ```
2. **WHERE**
   ```sql
   SELECT name, salary FROM employees
   WHERE salary > (SELECT AVG(salary) FROM employees);
   ```
3. **FROM** (derived table — must alias)
   ```sql
   SELECT dept, max_sal
   FROM (
     SELECT department AS dept, MAX(salary) AS max_sal
     FROM employees GROUP BY department
   ) AS dept_max;
   ```

### Scalar subquery
Returns exactly **1 row, 1 column**. Achieved via:
- aggregates without GROUP BY
- `LIMIT 1`

```sql
SELECT name, salary - (SELECT AVG(salary) FROM employees) AS diff
FROM employees ORDER BY diff DESC;
```

If subquery returns nothing → NULL → comparisons fail. Use `IN` or guarantee scalar via `MAX/MIN/LIMIT 1`.

### IN / NOT IN
Shorthand for many `OR`s. Subquery must return exactly one column.
```sql
SELECT * FROM customers WHERE id IN (SELECT customer_id FROM policies);
```

#### NOT IN + NULL trap
`NOT IN (..., NULL)` becomes `... AND id != NULL` → always fails.
Fixes:
1. `WHERE col IS NOT NULL` inside subquery, OR
2. Use `NOT EXISTS` (immune).

### EXISTS / NOT EXISTS
- Boolean check: TRUE if subquery returns ≥ 1 row.
- Almost always **correlated** (references outer row).
- `SELECT 1` is just a placeholder — values are unused.

```sql
-- Customers with no policy
SELECT * FROM customers c
WHERE NOT EXISTS (
  SELECT 1 FROM policies p WHERE p.customer_id = c.id
);

-- Customers with an approved claim > 1000
SELECT * FROM customers c
WHERE EXISTS (
  SELECT 1 FROM policies p
  JOIN claims cl ON p.id = cl.policy_id
  WHERE c.id = p.customer_id
    AND cl.status = 'approved'
    AND cl.amount > 1000
);
```

### Multi-column IN (tuple comparison)
```sql
SELECT * FROM customers
WHERE (city, YEAR(signup_date)) IN (('Mumbai', 2023), ('Delhi', 2023));
```

### Correlated subquery — employees above their dept avg
```sql
SELECT * FROM employees e1
WHERE e1.salary > (
  SELECT AVG(salary) FROM employees e2
  WHERE e1.department = e2.department
);
```

### Nth highest salary patterns

```sql
-- 2nd highest (ignores duplicates correctly):
SELECT MAX(salary) FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- All employees earning the 2nd-highest salary per department:
SELECT * FROM employees e1
WHERE e1.salary = (
  SELECT MAX(e2.salary) FROM employees e2
  WHERE e2.department = e1.department
    AND e2.salary < (
      SELECT MAX(e3.salary) FROM employees e3
      WHERE e3.department = e1.department
    )
)
ORDER BY salary DESC;
```

> `LIMIT 1 OFFSET 1` does NOT handle duplicates — use the nested-MAX trick instead.

---

## 10. Common Practice Queries (cheat-sheet)

```sql
-- Top N by salary
SELECT * FROM employees ORDER BY salary DESC LIMIT 3;

-- Departments with avg salary > 60000
SELECT department, AVG(salary)
FROM employees GROUP BY department
HAVING AVG(salary) > 60000;

-- Hires per year
SELECT YEAR(hire_date) AS y, COUNT(*)
FROM employees GROUP BY YEAR(hire_date) ORDER BY y;

-- People with subordinates
SELECT DISTINCT m.name
FROM employees m JOIN employees e ON m.id = e.manager_id;

-- People without subordinates (LEFT JOIN + IS NULL)
SELECT m.name
FROM employees m LEFT JOIN employees e ON m.id = e.manager_id
WHERE e.id IS NULL;

-- Subordinate counts per manager
SELECT m.name, COUNT(e.id) AS subord_count
FROM employees m LEFT JOIN employees e ON m.id = e.manager_id
GROUP BY m.id ORDER BY subord_count DESC;

-- Policies that never had a claim
SELECT * FROM policies p
WHERE NOT EXISTS (SELECT 1 FROM claims cl WHERE cl.policy_id = p.id);
```

---

## 11. Key Gotchas Summary

- `SELECT` aliases unusable in `WHERE` / same-`SELECT` expressions; usable in `ORDER BY` / `HAVING` (MySQL).
- `LIKE` is case-insensitive by default → use `BINARY` cast or `COLLATE utf8mb4_bin`.
- `WHERE` on right-table cols breaks `LEFT JOIN` semantics — use `IS NULL`.
- `NOT IN` + NULL → always empty; prefer `NOT EXISTS`.
- `COUNT(*)` vs `COUNT(col)` differs on left-join rows.
- Wrapping indexed columns in functions disables index usage.
- `LIMIT … OFFSET …` for Nth-highest does **not** dedupe.
