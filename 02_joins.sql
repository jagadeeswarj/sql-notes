-- JOIN runs after from and before where
-- JOIN combines rows from multiple tables by matching keys using a condition (ON clause), producing a new result set.
-- SELECT * FROM customers, policies; -> missing on condition -> this is cross join(all combinations), filter happens based on the ON condition

-- Customers
CREATE TABLE if not exists customers (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    city VARCHAR(50),
    signup_date DATE
);

-- Policies
CREATE TABLE if not exists policies (
    id INT PRIMARY KEY,
    customer_id INT,
    type VARCHAR(50),
    premium INT,
    start_date DATE,
    end_date DATE
);

-- Claims
CREATE TABLE if not exists claims (
    id INT PRIMARY KEY,
    policy_id INT,
    amount INT,
    status VARCHAR(20),
    claim_date DATE
);

-- Agents
CREATE TABLE if not exists agents (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    region VARCHAR(50)
);

-- Mapping table (many-to-many)
CREATE TABLE if not exists customer_agents (
    customer_id INT,
    agent_id INT
);


-- Customers
INSERT INTO customers VALUES
(1, 'Jagadeeswar', 'Hyderabad', '2022-01-10'),
(2, 'Arjun', 'Mumbai', '2021-03-15'),
(3, 'Sneha', 'Delhi', '2020-07-20'),
(4, 'Ravi', 'Mumbai', '2023-02-01');

-- Policies
INSERT INTO policies VALUES
(101, 1, 'Health', 5000, '2022-01-01', '2023-01-01'),
(102, 1, 'Life', 7000, '2022-06-01', '2024-06-01'),
(103, 2, 'Auto', 6000, '2021-04-01', '2022-04-01');

-- Claims
INSERT INTO claims VALUES
(1001, 101, 2000, 'approved', '2022-05-01'),
(1002, 101, 1500, 'pending', '2022-06-01'),
(1003, 103, 3000, 'approved', '2021-08-01');

-- Agents
INSERT INTO agents VALUES
(201, 'Kiran', 'South'),
(202, 'Meena', 'West');

-- Customer-Agents mapping
INSERT INTO customer_agents VALUES
(1, 201),
(2, 202),
(3, 201);

SELECT * FROM customers;
SELECT * FROM policies;
SELECT * FROM claims;
SELECT * FROM agents;
SELECT * FROM customer_agents;

---- END OF TABLE & DATA CREATION -----


-- JOINS
-- Type				What it returns
-- INNER JOIN		Only rows that match in BOTH tables
-- LEFT JOIN		All rows from LEFT, matched rows from RIGHT (NULL if no match)
-- RIGHT JOIN		All rows from RIGHT, matched from LEFT
-- FULL OUTER JOIN	All rows from BOTH (NULL where no match)
-- CROSS JOIN		Cartesian product (every row × every row)


-- inner join
select distinct c.name
from customers c inner join policies p on c.id = p.customer_id;

-- distict in select give only the distinct vals, for that currently omitted col pairs, so almost always used for single cols.
select c.name, p.premium, cl.amount, cl.status, a.name as agent_name, a.region as agent_region
from customers c 
inner join policies p on c.id = p.customer_id
inner join claims cl on p.id = cl.policy_id
inner join customer_agents ca on c.id = ca.customer_id
inner join agents a on a.id = ca.agent_id;


-- left join => enables detection of missing relationships
select c.id, c.name, p.premium from customers c left join policies p on c.id = p.customer_id;
-- -- customer with no policies
select c.id, c.name, p.premium from customers c left join policies p on c.id = p.customer_id where p.id is null;
-- = null and != null will always fail
-- where can break left join behaviour , cause the null checks will always fails, use is null or is not null accordingly

-- right join
-- keep all policies, and match the customers

select c.name,p.premium
from customers c
right join policies p on c.id = p.customer_id;

-- RIGHT JOIN keeps all rows from the right table and is equivalent to swapping tables in a LEFT JOIN, which is why LEFT JOIN is preferred.

-- SELF JOIN - relationship inside same table
-- SELF JOIN = joining a table with itself using aliases, used for recursive cols
-- ex: manager_id refers to another row in the SAME table
select * from employees;

select e.name as employee, m.name as manager
from employees e left join employees m
on e.manager_id = m.id;

-- where left cause, some emp have no manager, and we want all emp

-- if we want to print something else in case of null use -> COALESCE OR IFNULL

select e.name as employee, COALESCE(m.name,'NO-MANAGER') as manager
from employees e left join employees m
on e.manager_id = m.id;

select e.name as employee, IFNULL(m.name,'NO-MANAGER') as manager
from employees e left join employees m
on e.manager_id = m.id;

select e.name as employee, m.name as manager
from employees e left join employees m
on e.manager_id = m.id
where m.id is null;

-- SELECT expressions are evaluated at the same stage
-- Aliases are NOT available to other expressions in the same SELECT list

-- emp earn more than manager
select e.name ,e.salary as emp_sal,m.salary as manager_sal, (e.salary - m.salary) as sal_diff from employees e join employees m 
on e.manager_id = m.id where e.salary > m.salary order by sal_diff desc;


-- People who have subordinates
select distinct m.name 
from employees m
join employees e
on m.id = e.manager_id;

-- People who do NOT have subordinates
select m.name 
from employees m
left join employees e
on m.id = e.manager_id
where e.id is null;

-- number of subords
-- People who have subordinates
select m.name,count(e.id) as subord_count
from employees m
left join employees e
on m.id = e.manager_id
group by m.id
order by subord_count desc;

-- MySQL allows selecting non-grouped columns IF they are functionally dependent on GROUP BY columns,
-- m.id → uniquely determines m.name => For each group of m.id → there is exactly ONE m.name
-- count(e.id) returns the count of non-null values, so that we get 0 in case of no subords




-- CROSS JOIN
CREATE TABLE colors (
    id INT PRIMARY KEY,
    color VARCHAR(20)
);

CREATE TABLE sizes (
    id INT PRIMARY KEY,
    size VARCHAR(20)
);

INSERT INTO colors VALUES
(1, 'Red'),
(2, 'Blue'),
(3, 'Green');

INSERT INTO sizes VALUES
(1, 'S'),
(2, 'M'),
(3, 'L'),
(4, 'XL');

select c.color,s.size from colors c cross join sizes s;

-- implicity using 2 tables without join keyword -> it uses cross join
-- cause by default eveything is a cross joing, the ON conditions do the filtering
SELECT c.color, s.size
FROM colors c, sizes s;


-- JOIN with aggregation
-- total premium per customer
select c.id, c.name, COALESCE(sum(p.premium),0) as total_premium
from customers c 
left join policies p on c.id = p.customer_id 
group by c.id, c.name
order by total_premium desc;

-- customer with mroe than 3 policies
select c.id, c.name, count(p.id) as total_policies
from customers c
join policies p on c.id = p.customer_id 
group by c.id,c.name
having count(p.id) >= 1
order by total_policies desc;


-- avg claim per policy type
select 
p.type, avg(cl.amount) as avg_claim
from claims cl left join policies p on cl.policy_id = p.id
group by p.type
order by avg_claim desc;

-- note
-- WHERE kills LEFT JOIN -> cause the null check will always fail in logical operators so left join becomes inner join as the null valued rows are removed


SELECT c.name,
       COUNT(*) AS rows_count,
       COUNT(p.id) AS policy_count
FROM customers c
LEFT JOIN policies p ON c.id = p.customer_id
GROUP BY c.name;

-- here count(*) gives total rows, but count(col) give non null rows only

-- Practice Set

-- Names of all customers and their policy types.

select c.name,coalesce(p.type,'no-policy') from customers c left join policies p on c.id = p.customer_id;

-- Customers from 'Mumbai' with at least one policy.

select c.id, c.name, count(p.id) as total_polices from customers c left join policies p
on c.id = p.customer_id where c.city = 'Mumbai' group by c.id,c.name having count(p.id) >= 1 order by total_polices desc;

-- Customers who have NO policy.
select c.id,c.name from customers c left join policies p on c.id = p.customer_id where p.id is null;
-- Total premium each customer pays.
select c.id,c.name, sum(p.premium) as total_premium from customers c join policies p on c.id = p.customer_id group by c.id, c.name;
-- Customers with more than 2 policies.
select c.id,c.name, count(p.id) as total_policies from customers c join policies p on c.id = p.customer_id group by c.id,c.name having count(p.id) >= 3;
-- Total claim amount per policy.
select p.id, sum(cl.amount) as total_claim
from claims cl left join policies p on cl.policy_id = p.id group by p.id;
-- Find policies that have NO claims.
select p.id
from claims cl right join policies p on cl.policy_id = p.id where cl.id is null;
-- Names of customers and their agent's name.
select c.name ,a.name from 
customers c 
join customer_agents ca on c.id = ca.customer_id
join agents a on ca.agent_id = a.id;
-- Top 5 customers by total premium.
select c.name, coalesce(sum(p.premium),0) as total_premium from 
customers c
left join policies p on c.id = p.customer_id
group by c.id,c.name
order by total_premium desc
limit 5;
-- Number of claims per customer (including those with 0 claims)

