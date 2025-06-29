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