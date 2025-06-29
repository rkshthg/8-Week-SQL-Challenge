**Schema (PostgreSQL v17)**

```sql
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
```

---

**Query #1**

```sql
-- 1. What is the total amount each customer spent at the restaurant?
SELECT sales.customer_id, SUM(menu.price) as amount_spent
FROM sales LEFT JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;
```

| customer_id | amount_spent |
| --- | --- |
| B | 74 |
| C | 36 |
| A | 76 |

---

**Query #2**

```sql
-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT(order_date)) as days_visited
FROM sales
GROUP BY customer_id;
```

| customer_id | days_visited |
| --- | --- |
| A | 4 |
| B | 6 |
| C | 2 |

---

**Query #3**

```sql
-- 3. What was the first item from the menu purchased by each customer?
WITH orders as (
  SELECT customer_id, product_id,
	ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) as row_num
  FROM sales
)
SELECT orders.customer_id, menu.product_name as first_item_purchased
FROM orders JOIN menu
ON orders.product_id = menu.product_id
WHERE row_num = 1;
```

| customer_id | first_item_purchased |
| --- | --- |
| A | sushi |
| B | curry |
| C | ramen |

---

**Query #4**

```sql
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT menu.product_name as most_popular, COUNT(sales.product_id) as times_purchased
FROM sales JOIN menu
ON sales.product_id = menu.product_id
GROUP BY menu.product_name
LIMIT 1;
```

| most_popular | times_purchased |
| --- | --- |
| ramen | 8 |

---

**Query #5**

```sql
-- 5. Which item was the most popular for each customer?
WITH orders as (
  SELECT sales.customer_id, menu.product_name, COUNT(sales.product_id) as times_ordered,
      RANK() OVER (PARTITION BY sales.customer_id ORDER BY COUNT(sales.product_id) DESC)
  FROM sales JOIN menu
  ON sales.product_id = menu.product_id
  GROUP BY sales.customer_id, menu.product_name
  -- ORDER BY sales.customer_id, COUNT(sales.product_id) DESC
)
SELECT customer_id, product_name, times_ordered
FROM orders
WHERE rank = 1
ORDER BY customer_id;
```

| customer_id | product_name | times_ordered |
| --- | --- | --- |
| A | ramen | 3 |
| B | ramen | 2 |
| B | curry | 2 |
| B | sushi | 2 |
| C | ramen | 3 |

---

**Query #6**

```sql
-- 6. Which item was purchased first by the customer after they became a member?
WITH post_join as (
  SELECT sales.*
  FROM sales, members
  WHERE sales.customer_id = members.customer_id AND sales.order_date > members.join_date
  ORDER BY sales.customer_id, sales.order_date
 ),
orders as (
  SELECT customer_id, product_id,
	ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) as row_num
  FROM post_join
)
SELECT orders.customer_id, menu.product_name as first_item_purchased
FROM orders JOIN menu
ON orders.product_id = menu.product_id
WHERE row_num = 1;
```

| customer_id | first_item_purchased |
| --- | --- |
| B | sushi |
| A | ramen |

---

**Query #7**

```sql
-- 7. Which item was purchased just before the customer became a member?
WITH pre_join as (
  SELECT sales.*
  FROM sales, members
  WHERE sales.customer_id = members.customer_id AND sales.order_date < members.join_date
  ORDER BY sales.customer_id, sales.order_date
 ),
orders as (
  SELECT customer_id, product_id,
	ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) as row_num
  FROM pre_join
)
SELECT orders.customer_id, menu.product_name as last_item_purchased
FROM orders JOIN menu
ON orders.product_id = menu.product_id
WHERE orders.row_num = 1
GROUP BY orders.customer_id, menu.product_name;
```

| customer_id | last_item_purchased |
| --- | --- |
| A | sushi |
| B | sushi |

---

**Query #8**

```sql
-- 8. What is the total items and amount spent for each member before they became a member?
WITH pre_join as (
  SELECT sales.*
  FROM sales LEFT JOIN members
  ON sales.customer_id = members.customer_id AND sales.order_date < members.join_date
  ORDER BY sales.customer_id, sales.order_date
 )
SELECT pre_join.customer_id, COUNT(pre_join.product_id) as items_ordered, SUM(menu.price) as amount_spent
FROM pre_join LEFT JOIN menu
ON pre_join.product_id = menu.product_id
GROUP BY pre_join.customer_id;
```

| customer_id | items_ordered | amount_spent |
| --- | --- | --- |
| B | 6 | 74 |
| C | 3 | 36 |
| A | 6 | 76 |

---

**Query #9**

```sql
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points_tbl as (
  SELECT sales.customer_id,
    CASE
    WHEN sales.product_id = 1 THEN 20
    ELSE 10
    END AS points,
    menu.price
  FROM sales LEFT JOIN menu
  ON sales.product_id = menu.product_id
)
SELECT customer_id, SUM(price*points) as points
FROM points_tbl
GROUP BY customer_id;
```

| customer_id | points |
| --- | --- |
| B | 940 |
| C | 360 |
| A | 860 |

---

**Query #10**

```sql
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH sales_info AS (
SELECT sales.customer_id, sales.order_date, members.join_date, menu.product_name, menu.price,
  CASE
  WHEN sales.order_date < members.join_date THEN 'N'
  WHEN members.join_date IS NULL THEN 'N'
  ELSE 'Y'
  END AS member_at_order
FROM sales
LEFT JOIN menu ON sales.product_id = menu.product_id
LEFT JOIN members ON sales.customer_id = members.customer_id
ORDER BY sales.order_date
),
loyalty_points AS (
SELECT customer_id,
  CASE
  WHEN member_at_order = 'N'
  THEN
    CASE
    WHEN product_name = 'sushi' THEN 2
    ELSE 1
    END
  WHEN member_at_order = 'Y'
  THEN
    CASE
    WHEN (join_date - order_date) <= 7 AND (join_date - order_date) >= 0 THEN 2
    WHEN product_name = 'sushi' THEN 2
    ELSE 1
    END
  END AS bonus,
  price * 10 as points
FROM sales_info
)
SELECT customer_id, SUM(points * bonus) as points
FROM loyalty_points
GROUP BY customer_id;
```

| customer_id | points |
| --- | --- |
| B | 940 |
| C | 360 |
| A | 1010 |

---

**Bonus Query #1**

```sql
-- Join All The Things
SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
  CASE
  WHEN sales.order_date < members.join_date THEN 'N'
  WHEN members.join_date IS NULL THEN 'N'
  ELSE 'Y'
  END AS member
FROM sales
LEFT JOIN menu ON sales.product_id = menu.product_id
LEFT JOIN members ON sales.customer_id = members.customer_id
ORDER BY sales.customer_id, sales.order_date;
```

| customer_id | order_date | product_name | price | member |
| --- | --- | --- | --- | --- |
| A | 2021-01-01 | sushi | 10 | N |
| A | 2021-01-01 | curry | 15 | N |
| A | 2021-01-07 | curry | 15 | Y |
| A | 2021-01-10 | ramen | 12 | Y |
| A | 2021-01-11 | ramen | 12 | Y |
| A | 2021-01-11 | ramen | 12 | Y |
| B | 2021-01-01 | curry | 15 | N |
| B | 2021-01-02 | curry | 15 | N |
| B | 2021-01-04 | sushi | 10 | N |
| B | 2021-01-11 | sushi | 10 | Y |
| B | 2021-01-16 | ramen | 12 | Y |
| B | 2021-02-01 | ramen | 12 | Y |
| C | 2021-01-01 | ramen | 12 | N |
| C | 2021-01-01 | ramen | 12 | N |
| C | 2021-01-07 | ramen | 12 | N |

---

**Bonus Query #2**

```sql
-- Rank All The Things
WITH sales_info AS (
SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
  CASE
  WHEN sales.order_date < members.join_date THEN 'N'
  WHEN members.join_date IS NULL THEN 'N'
  ELSE 'Y'
  END AS member
FROM sales
LEFT JOIN menu ON sales.product_id = menu.product_id
LEFT JOIN members ON sales.customer_id = members.customer_id
)
SELECT *,
  CASE
  WHEN member = 'Y' THEN RANK() OVER ( PARTITION BY customer_id, CASE WHEN member = 'Y' THEN 1 ELSE 2 END ORDER BY customer_id, order_date)
  ELSE NULL
  END AS ranking
FROM sales_info
ORDER BY customer_id, order_date;
```

| customer_id | order_date | product_name | price | member | ranking |
| --- | --- | --- | --- | --- | --- |
| A | 2021-01-01 | sushi | 10 | N |  |
| A | 2021-01-01 | curry | 15 | N |  |
| A | 2021-01-07 | curry | 15 | Y | 1 |
| A | 2021-01-10 | ramen | 12 | Y | 2 |
| A | 2021-01-11 | ramen | 12 | Y | 3 |
| A | 2021-01-11 | ramen | 12 | Y | 3 |
| B | 2021-01-01 | curry | 15 | N |  |
| B | 2021-01-02 | curry | 15 | N |  |
| B | 2021-01-04 | sushi | 10 | N |  |
| B | 2021-01-11 | sushi | 10 | Y | 1 |
| B | 2021-01-16 | ramen | 12 | Y | 2 |
| B | 2021-02-01 | ramen | 12 | Y | 3 |
| C | 2021-01-01 | ramen | 12 | N |  |
| C | 2021-01-01 | ramen | 12 | N |  |
| C | 2021-01-07 | ramen | 12 | N |  |

---