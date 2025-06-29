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