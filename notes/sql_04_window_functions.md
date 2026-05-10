# SQL 04 — Window Functions
> **Time budget**: 1.5 hours
> **Goal**: Master ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, running totals
> **Note**: For Hartford intern OA, basic window functions are nice-to-have, not critical. Skip if running short on time.

---

## 1. What is a window function? (10 min)

Aggregates that DON'T collapse rows. They give each row a value computed over a "window" of related rows.

**Without window**:
```sql
-- 1 row per dept
SELECT department, AVG(salary) FROM employees GROUP BY department;
```

**With window**:
```sql
-- All employee rows + their dept's avg salary as a column
SELECT name, department, salary,
       AVG(salary) OVER (PARTITION BY department) AS dept_avg
FROM employees;
```

**Syntax**:
```sql
function() OVER (
    PARTITION BY column      -- group by (optional)
    ORDER BY column          -- sort within group (required for ranking)
)
```

---

## 2. ROW_NUMBER, RANK, DENSE_RANK (25 min)

| Function | Behavior on ties |
|----------|------------------|
| `ROW_NUMBER()` | 1, 2, 3, 4, 5... (always unique) |
| `RANK()` | 1, 2, 2, 4, 5 (skips after ties) |
| `DENSE_RANK()` | 1, 2, 2, 3, 4 (no skip) |

```sql
-- Rank employees by salary (highest first)
SELECT name, salary,
       ROW_NUMBER() OVER (ORDER BY salary DESC) AS rn,
       RANK()       OVER (ORDER BY salary DESC) AS rk,
       DENSE_RANK() OVER (ORDER BY salary DESC) AS drk
FROM employees;
```

**KILLER PATTERN — Top N per group**:
```sql
-- Top 3 highest-paid employees per department
WITH ranked AS (
    SELECT name, department, salary,
           ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS rn
    FROM employees
)
SELECT name, department, salary
FROM ranked
WHERE rn <= 3;
```

**This pattern shows up in 80% of OA SQL questions.** Memorize it.

---

## 3. LAG and LEAD (20 min)

Access previous/next row's value within a window.

```sql
-- Compare each month's revenue with previous month
SELECT month, revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev_month,
       revenue - LAG(revenue) OVER (ORDER BY month) AS diff
FROM monthly_revenue;

-- LEAD looks forward
SELECT month, revenue,
       LEAD(revenue) OVER (ORDER BY month) AS next_month
FROM monthly_revenue;
```

**Default values**: `LAG(col, 1, 0)` → 1 row back, default 0 if no prior row.

---

## 4. Running totals & moving avg (15 min)

```sql
-- Running total of salary by hire_date
SELECT name, hire_date, salary,
       SUM(salary) OVER (ORDER BY hire_date) AS running_total
FROM employees;

-- Running total per department
SELECT name, department, hire_date, salary,
       SUM(salary) OVER (PARTITION BY department ORDER BY hire_date) AS dept_running_total
FROM employees;
```

---

## 5. FIRST_VALUE, LAST_VALUE (10 min)

```sql
-- First and last hired employee per department
SELECT name, department, hire_date,
       FIRST_VALUE(name) OVER (PARTITION BY department ORDER BY hire_date) AS first_hire,
       LAST_VALUE(name)  OVER (PARTITION BY department ORDER BY hire_date
                               ROWS BETWEEN UNBOUNDED PRECEDING
                               AND UNBOUNDED FOLLOWING) AS last_hire
FROM employees;
```

**Note**: LAST_VALUE often needs the explicit frame clause to behave correctly.

---

## 6. Practice Set (20 min)

Schema:
```
sales(id, salesperson, region, amount, sale_date)
employees(id, name, department, salary, hire_date)
```

Solve:

1. Rank salespeople within each region by total sales.
2. For each sale, show the previous sale's amount by the same person.
3. Top 2 sales per region.
4. Running total of sales per region (sorted by date).
5. Each employee's salary minus their department's average salary.

**Solutions**:

```sql
-- 1
WITH totals AS (
    SELECT salesperson, region, SUM(amount) AS total
    FROM sales GROUP BY salesperson, region
)
SELECT salesperson, region, total,
       RANK() OVER (PARTITION BY region ORDER BY total DESC) AS rk
FROM totals;

-- 2
SELECT id, salesperson, sale_date, amount,
       LAG(amount) OVER (PARTITION BY salesperson ORDER BY sale_date) AS prev_amount
FROM sales;

-- 3
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY region ORDER BY amount DESC) AS rn
    FROM sales
)
SELECT * FROM ranked WHERE rn <= 2;

-- 4
SELECT id, region, sale_date, amount,
       SUM(amount) OVER (PARTITION BY region ORDER BY sale_date) AS running_total
FROM sales;

-- 5
SELECT name, department, salary,
       salary - AVG(salary) OVER (PARTITION BY department) AS diff_from_avg
FROM employees;
```

---

## Cheatsheet

```
ROW_NUMBER() OVER (PARTITION BY X ORDER BY Y)  → unique 1,2,3...
RANK()       → skips ranks after ties (1,2,2,4)
DENSE_RANK() → no skip (1,2,2,3)

TOP-N PER GROUP pattern (memorize!):
  WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY G ORDER BY X DESC) AS rn
    FROM t
  ) SELECT * FROM ranked WHERE rn <= N;

LAG / LEAD: previous / next row in window
SUM/AVG OVER (ORDER BY ...): running aggregate
```

---

## Next: `sql_05_dbms_concepts.md` (1 hr — for MCQs)
