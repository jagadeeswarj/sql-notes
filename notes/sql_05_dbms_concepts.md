# DBMS Concepts (MCQ Prep)
> **Time budget**: 1 hour
> **Goal**: Cover MCQ topics — normalization, ACID, indexes, transactions, keys, joins theory

---

## 1. Keys (10 min)

| Key | Description |
|-----|-------------|
| **Primary Key** | Unique + NOT NULL. One per table. |
| **Foreign Key** | References primary key in another table. Enforces referential integrity. |
| **Candidate Key** | Any column(s) that COULD be a primary key (unique, not null). |
| **Super Key** | Any superset of a candidate key. |
| **Composite Key** | Primary key made of multiple columns. |
| **Unique Key** | Unique values, but allows ONE NULL (vs primary key which allows none). |

**MCQ trap**: Primary key vs Unique key — both unique, but primary key disallows NULLs and there's only one per table. Unique key allows multiple per table and (typically) one NULL.

---

## 2. Normalization (15 min)

Process of organizing data to reduce redundancy.

| Form | Rule |
|------|------|
| **1NF** | Each cell has atomic (single) values. No repeating groups. |
| **2NF** | 1NF + no partial dependency on composite key (every non-key attribute depends on the WHOLE key). |
| **3NF** | 2NF + no transitive dependency (non-key attributes don't depend on other non-key attributes). |
| **BCNF** | Stricter 3NF. Every determinant must be a candidate key. |

**Memory aid**: 1NF=atomic, 2NF=no-partial, 3NF=no-transitive, BCNF=every-determinant-is-candidate-key.

**Example of denormalized**:
```
StudentID | Name | Course1 | Course2 | Course3   ← violates 1NF (repeating)
```

**1NF**:
```
StudentID | Name | Course
   1      | Jag  | DSA
   1      | Jag  | DBMS
```

**Why normalize**: removes duplicates, prevents update anomalies.
**Why denormalize**: performance — fewer joins.

---

## 3. ACID Properties (10 min)

The 4 guarantees of database transactions:

| Property | Meaning |
|----------|---------|
| **Atomicity** | All or nothing. Transaction commits fully or rolls back fully. |
| **Consistency** | DB moves from one valid state to another. Constraints enforced. |
| **Isolation** | Concurrent transactions don't interfere. |
| **Durability** | Once committed, data persists even after crash. |

**Memory aid**: A-C-I-D. "Atomic Consistent Isolated Durable."

**Real-world example (Razorpay payment in your project)**:
- Atomicity: payment + order_creation either both succeed or both rollback
- Consistency: stock count never goes below 0
- Isolation: two simultaneous purchases of last item — only one wins
- Durability: after commit, even if server crashes, the order persists

---

## 4. Transaction Isolation Levels (10 min)

| Level | Allows |
|-------|--------|
| **READ UNCOMMITTED** | Dirty reads (read uncommitted data) |
| **READ COMMITTED** | Only committed reads, but non-repeatable reads possible |
| **REPEATABLE READ** | Same query returns same result within txn (default in MySQL) |
| **SERIALIZABLE** | Highest. Transactions appear sequential. |

**Anomalies**:
- **Dirty read**: read uncommitted change → that change rolls back
- **Non-repeatable read**: same row read twice → different value (someone updated)
- **Phantom read**: same query → different rows appear (someone inserted)

---

## 5. Indexes (10 min)

A data structure (typically B-Tree) for fast lookups.

```sql
CREATE INDEX idx_email ON users(email);
```

**When indexes help**: WHERE filters, JOIN columns, ORDER BY columns.
**When they hurt**: lots of writes (every INSERT/UPDATE updates index too).

**Types**:
- **Clustered**: data physically sorted by key (1 per table — usually primary key)
- **Non-clustered**: separate structure pointing to data rows
- **Composite**: index on multiple columns (order matters!)
- **Unique**: enforces uniqueness

**MCQ favorite**: A composite index on (a, b) helps queries filtering on `a` or `(a, b)` but NOT on `b` alone. (Leftmost prefix rule.)

---

## 6. JOIN theory (5 min)

| | Returns |
|--|--------|
| INNER JOIN | matching rows in both |
| LEFT JOIN | all left + matched right (NULL else) |
| RIGHT JOIN | all right + matched left |
| FULL OUTER | all from both |
| CROSS JOIN | Cartesian product |
| SELF JOIN | table joined to itself |
| NATURAL JOIN | auto-joins on same-named columns (avoid in practice) |

---

## 7. SQL vs NoSQL (5 min)

| SQL | NoSQL |
|-----|-------|
| Relational, fixed schema | Flexible schema (JSON-like) |
| ACID | BASE (Basically Available, Soft state, Eventual consistency) |
| Vertical scale | Horizontal scale |
| Examples: PostgreSQL, MySQL | MongoDB, Cassandra, DynamoDB |

You've used both: PostgreSQL (VNR Reports) + DynamoDB/Firestore (Realityrift).

---

## 8. Common MCQ Questions (15 min)

**Q1**: Difference between DELETE, TRUNCATE, DROP?
- DELETE: removes rows, can have WHERE, can rollback. Slow.
- TRUNCATE: removes all rows, no WHERE, faster, can't rollback (in some DBs).
- DROP: removes the entire table.

**Q2**: What does GROUP BY do?
- Groups rows with same values into summary rows. Used with aggregate functions.

**Q3**: Difference between WHERE and HAVING?
- WHERE filters rows BEFORE grouping; HAVING filters groups AFTER aggregation.

**Q4**: What is a view?
- A virtual table based on a SELECT query. Doesn't store data (unless materialized).

**Q5**: What is a stored procedure?
- A precompiled SQL block stored on the DB server. Reusable.

**Q6**: SQL data types?
- Numeric: INT, BIGINT, DECIMAL, FLOAT
- String: VARCHAR(n), CHAR(n), TEXT
- Date: DATE, DATETIME, TIMESTAMP
- Boolean: BOOLEAN/BIT
- Other: JSON, BLOB, ENUM

**Q7**: NULL handling?
- `col = NULL` → always NULL (not TRUE)
- Use `IS NULL` / `IS NOT NULL`
- `COALESCE(col, 'default')` returns first non-NULL
- `NULLIF(a, b)` → NULL if a=b, else a

**Q8**: Difference between UNION and UNION ALL?
- UNION: combines + removes duplicates (slower)
- UNION ALL: combines including duplicates (faster)

**Q9**: What is a trigger?
- Automatic procedure that runs on INSERT/UPDATE/DELETE event.

**Q10**: What is a transaction?
- A logical unit of work. Either all operations commit or all rollback.

---

## Cheatsheet

```
KEYS:    Primary (unique+notnull), Foreign (references), Candidate, Composite
NORM:    1NF=atomic, 2NF=no-partial-dep, 3NF=no-transitive-dep, BCNF=stricter
ACID:    Atomic, Consistent, Isolated, Durable
INDEX:   B-Tree, leftmost prefix rule, helps reads hurts writes
ISOL:    Read Uncommitted < Read Committed < Repeatable < Serializable
DEL/TRUNC/DROP: rows w/ WHERE / all rows fast / entire table
NULL:    use IS NULL, COALESCE for defaults
UNION:   removes dupes; UNION ALL keeps them
```

---

## Done with SQL section. Next: DSA topics
