-- 1. What is the total amount each customer spent at the restaurant?

SELECT sales.customer_id, SUM(menu.price) as amount_spent
FROM sales LEFT JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;