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