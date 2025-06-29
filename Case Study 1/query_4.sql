-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT menu.product_name as most_popular, COUNT(sales.product_id) as times_purchased
FROM sales JOIN menu
ON sales.product_id = menu.product_id
GROUP BY menu.product_name
LIMIT 1;