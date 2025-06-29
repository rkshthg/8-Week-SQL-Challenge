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