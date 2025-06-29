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