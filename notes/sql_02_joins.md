# SQL 02 — Joins
> **Time budget**: 1.5 hours
> **Goal**: Master all JOIN types — likely the #1 SQL topic in OA

---

## Why Joins matter for Hartford

Insurance schemas are relational. You'll see tables like:
- `customers(id, name, ...)`
- `policies(id, customer_id, type, premium, ...)`
- `claims(id, policy_id, amount, status, date, ...)`
- `agents(id, name, region, ...)`

To answer questions like "total claims per customer" you NEED joins.

---

## 1. The 5 JOIN types (20 min)

| Type | What it returns |
|------|-----------------|
| **INNER JOIN** | Only rows that match in BOTH tables |
| **LEFT JOIN** | All rows from LEFT, matched rows from RIGHT (NULL if no match) |
| **RIGHT JOIN** | All rows from RIGHT, matched from LEFT |
| **FULL OUTER JOIN** | All rows from BOTH (NULL where no match) |
| **CROSS JOIN** | Cartesian product (every row × every row) |

**Visual mental model**:
```
Table A:    Table B:
 id   |     id
  1   |      2
  2   |      3
  3   |      4

INNER JOIN ON A.id=B.id  →  {2, 3}              -- intersection
LEFT JOIN  ON A.id=B.id  →  {1→NULL, 2→2, 3→3}  -- all of A
RIGHT JOIN ON A.id=B.id  →  {2→2, 3→3, 4→NULL}  -- all of B
FULL OUTER →  all 4 rows with NULLs as needed
```

---

## 2. INNER JOIN (15 min)

```sql
-- Schema:
-- customers(id, name)
-- policies(id, customer_id, premium)

-- Get all customers with their policies
SELECT c.name, p.premium
FROM customers c
INNER JOIN policies p ON c.id = p.customer_id;

-- Customers without policies are EXCLUDED
```

**Multi-table inner join**:
```sql
SELECT c.name, p.premium, cl.amount
FROM customers c
INNER JOIN policies p ON c.id = p.customer_id
INNER JOIN claims cl ON p.id = cl.policy_id;
```

---

## 3. LEFT JOIN — most useful in OA (20 min)

```sql
-- All customers, with their policies (or NULL if none)
SELECT c.name, p.premium
FROM customers c
LEFT JOIN policies p ON c.id = p.customer_id;
```

**Classic pattern: find rows with NO match**:
```sql
-- Customers who have NO policy
SELECT c.name
FROM customers c
LEFT JOIN policies p ON c.id = p.customer_id
WHERE p.id IS NULL;
```

**This pattern (LEFT JOIN + IS NULL) is VERY common in OAs.**

---

## 4. RIGHT JOIN (5 min)

Same as LEFT JOIN but flipped. Rarely used — usually rewritten as LEFT JOIN.

```sql
-- These are equivalent:
SELECT * FROM A RIGHT JOIN B ON A.x = B.x;
SELECT * FROM B LEFT JOIN A ON A.x = B.x;
```

**Recommendation**: always write LEFT JOIN. Easier to read.

---

## 5. SELF JOIN (15 min)

Joining a table to itself — for hierarchical data (e.g., employee→manager).

```sql
-- Schema: employees(id, name, manager_id)

-- Find each employee with their manager's name
SELECT e.name AS employee, m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

**Find pairs**:
```sql
-- Find employees who earn more than their manager
SELECT e.name
FROM employees e
JOIN employees m ON e.manager_id = m.id
WHERE e.salary > m.salary;
```

---

## 6. CROSS JOIN (5 min)

Cartesian product. Rare in OAs but appears in MCQs.

```sql
SELECT * FROM colors CROSS JOIN sizes;
-- If colors has 3 rows and sizes has 4 rows → 12 rows output
```

---

## 7. JOIN with aggregation (20 min)

Most OA questions combine joins + GROUP BY.

```sql
-- Total premium per customer
SELECT c.id, c.name, SUM(p.premium) AS total_premium
FROM customers c
LEFT JOIN policies p ON c.id = p.customer_id
GROUP BY c.id, c.name;

-- Customers with more than 3 policies
SELECT c.id, c.name, COUNT(p.id) AS policy_count
FROM customers c
JOIN policies p ON c.id = p.customer_id
GROUP BY c.id, c.name
HAVING COUNT(p.id) > 3;

-- Avg claim amount per policy type
SELECT p.type, AVG(cl.amount) AS avg_claim
FROM policies p
JOIN claims cl ON p.id = cl.policy_id
GROUP BY p.type;
```

---

## 8. Common Pitfalls (10 min)

### Pitfall 1: Forgetting GROUP BY columns
```sql
-- ❌ WRONG (in strict SQL)
SELECT c.name, COUNT(p.id) FROM customers c JOIN policies p ON c.id = p.customer_id;

-- ✅ RIGHT
SELECT c.name, COUNT(p.id) FROM customers c JOIN policies p ON c.id = p.customer_id
GROUP BY c.name;
```

### Pitfall 2: WHERE on LEFT JOIN nullifying it
```sql
-- ❌ Customers WITH a non-existent policy (returns nothing useful)
SELECT * FROM customers c
LEFT JOIN policies p ON c.id = p.customer_id
WHERE p.premium > 100;
-- This kills the LEFT JOIN behavior. Customers w/o policies are excluded
-- because p.premium is NULL.

-- ✅ Put condition in JOIN
SELECT * FROM customers c
LEFT JOIN policies p ON c.id = p.customer_id AND p.premium > 100;
```

### Pitfall 3: Counting wrong
```sql
-- COUNT(*) counts rows including those with NULL columns
-- COUNT(p.id) on a LEFT JOIN gives 0 for unmatched (which is what you want)

SELECT c.name, COUNT(*) AS rows_count, COUNT(p.id) AS policy_count
FROM customers c
LEFT JOIN policies p ON c.id = p.customer_id
GROUP BY c.name;
-- If customer has no policy: rows_count=1 (the LEFT JOIN row), policy_count=0
```

---

## 9. Practice Set (30 min)

Schema:
```
customers(id, name, city, signup_date)
policies(id, customer_id, type, premium, start_date, end_date)
claims(id, policy_id, amount, status, claim_date)
agents(id, name, region)
customer_agents(customer_id, agent_id)
```

Write SQL for each:

1. Names of all customers and their policy types.
2. Customers from 'Mumbai' with at least one policy.
3. Customers who have NO policy.
4. Total premium each customer pays.
5. Customers with more than 2 policies.
6. Total claim amount per policy.
7. Find policies that have NO claims.
8. Names of customers and their agent's name.
9. Top 5 customers by total premium.
10. Number of claims per customer (including those with 0 claims).

**Solutions**:

```sql
-- 1
SELECT c.name, p.type
FROM customers c
JOIN policies p ON c.id = p.customer_id;

-- 2
SELECT DISTINCT c.id, c.name
FROM customers c
JOIN policies p ON c.id = p.customer_id
WHERE c.city = 'Mumbai';

-- 3
SELECT c.id, c.name
FROM customers c
LEFT JOIN policies p ON c.id = p.customer_id
WHERE p.id IS NULL;

-- 4
SELECT c.id, c.name, SUM(p.premium) AS total_premium
FROM customers c
LEFT JOIN policies p ON c.id = p.customer_id
GROUP BY c.id, c.name;

-- 5
SELECT c.id, c.name, COUNT(p.id) AS num_policies
FROM customers c
JOIN policies p ON c.id = p.customer_id
GROUP BY c.id, c.name
HAVING COUNT(p.id) > 2;

-- 6
SELECT p.id, SUM(cl.amount) AS total_claims
FROM policies p
LEFT JOIN claims cl ON p.id = cl.policy_id
GROUP BY p.id;

-- 7
SELECT p.id, p.type
FROM policies p
LEFT JOIN claims cl ON p.id = cl.policy_id
WHERE cl.id IS NULL;

-- 8
SELECT c.name AS customer, a.name AS agent
FROM customers c
JOIN customer_agents ca ON c.id = ca.customer_id
JOIN agents a ON ca.agent_id = a.id;

-- 9
SELECT c.id, c.name, SUM(p.premium) AS total
FROM customers c
JOIN policies p ON c.id = p.customer_id
GROUP BY c.id, c.name
ORDER BY total DESC
LIMIT 5;

-- 10
SELECT c.id, c.name, COUNT(cl.id) AS claim_count
FROM customers c
LEFT JOIN policies p ON c.id = p.customer_id
LEFT JOIN claims cl ON p.id = cl.policy_id
GROUP BY c.id, c.name;
```

---

## Cheatsheet

```
INNER JOIN  → only matches
LEFT JOIN   → all left + matched right (NULL if no match)
SELF JOIN   → table joined to itself (use aliases!)

Find missing: LEFT JOIN ... WHERE right.id IS NULL
JOIN + GROUP BY: classic pattern for "X per Y"
```

---

## Next: `sql_03_subqueries_cte.md` (1.5 hr)
