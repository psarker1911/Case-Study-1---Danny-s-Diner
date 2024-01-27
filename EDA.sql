/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- Example Query:
SELECT *
FROM dannys_diner.sales;

SELECT *
FROM dannys_diner.menu;

SELECT *
FROM dannys_diner.members;

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) AS total_spent
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id DESC;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT (DISTINCT order_date) AS visit_count_days
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY visit_count_days DESC;

-- 3. What was the first item from the menu purchased by each customer?

-- A = sushi, B = curry, C = ramen

SELECT s.customer_id, MIN(s.order_date) AS first_order_date, m.product_name
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m
ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
ORDER BY s.customer_id, first_order_date;

WITH RankedSales AS (
    SELECT
        s.customer_id,
        s.order_date,
        m.product_name,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date, s.product_id) as rank
    FROM
        dannys_diner.sales AS s
    JOIN
        dannys_diner.menu AS m ON s.product_id = m.product_id
)
SELECT
    customer_id,
    order_date AS first_order_date,
    product_name AS first_product
FROM
    RankedSales
WHERE
    rank = 1;
    
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers? Ramen 8 times

SELECT m.product_name, COUNT(*) AS times_purchased
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m
ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY times_purchased DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer? A - Ramen 3 times, B - Ramen, curry and sushi 2 times each, C - Ramen 3 times

WITH CustomerOrders AS (
    SELECT
        s.customer_id,
        m.product_name,
        COUNT(*) AS order_count
    FROM
        dannys_diner.sales AS s
    JOIN
        dannys_diner.menu AS m ON s.product_id = m.product_id
    GROUP BY
        s.customer_id, m.product_name
),
RankedCustomerOrders AS (
    SELECT
        customer_id,
        product_name,
        order_count,
        RANK() OVER (PARTITION BY customer_id ORDER BY order_count DESC) as rank
    FROM
        CustomerOrders
)
SELECT
    customer_id,
    product_name AS most_popular_item,
    order_count
FROM
    RankedCustomerOrders
WHERE
    rank = 1;
