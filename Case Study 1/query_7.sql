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