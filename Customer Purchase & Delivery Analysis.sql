CREATE DATABASE analysis;

-- Q1. Identify customers who haven't ordered in the last 60 days but had at leat 2 orders before.
SELECT * FROM customers;
SELECT * FROM delivery_performance;
SELECT * FROM discount_campaign;
SELECT * FROM inventory;
SELECT * FROM orders1;
SELECT * FROM sales_data;

WITH customer_orders AS (
    SELECT customer_id, 
           COUNT(order_id) AS total_orders, 
           MAX(order_date) AS last_order_date
    FROM orders1
    GROUP BY customer_id
)
SELECT customer_id, 
       total_orders, 
       last_order_date
FROM customer_orders
WHERE total_orders >= 2 
AND last_order_date <= DATE_SUB(CURDATE(), INTERVAL 60 DAY);


-- Q2. 	Calculate the average time between consecutive orders for repeat customers.
WITH order_diffs AS (
    SELECT customer_id, 
           order_date, 
           LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_date
    FROM orders1
)
SELECT customer_id, 
       AVG(DATEDIFF(next_order_date, order_date)) AS avg_days_between_orders
FROM order_diffs
WHERE next_order_date IS NOT NULL
GROUP BY customer_id;


-- Q3. Determine the top 10% of customers by total spend and their average order value.
WITH customer_spend AS (
    SELECT customer_id, 
           SUM(total_amount) AS total_spend, 
           COUNT(order_id) AS order_count
    FROM orders1
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT customer_id, total_spend, order_count, 
           NTILE(10) OVER (ORDER BY total_spend DESC) AS percentile_rank
    FROM customer_spend
)
SELECT customer_id, 
       total_spend, 
       (total_spend / order_count) AS avg_order_value
FROM ranked_customers
WHERE percentile_rank = 1;  -- Selecting the top 10% of customers


-- Q4. 4.	Analyze delivery time efficiency by calculating the percentage of on-time deliveries per region.
SELECT s.region, 
       COUNT(CASE WHEN d.delivery_status = 'On Time' THEN 1 END) * 100.0 / COUNT(*) AS on_time_delivery_pct
FROM sales_data s
JOIN delivery_performance d ON s.order_id = d.order_id  -- Assuming order_id is the common key
GROUP BY s.region;