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