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
-- 8. What are the total items and amount spent for each member before they became a member?
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

-- 6. Which item was purchased first by the customer after they became a member? A - curry - 2021-01-07T00:00:00.000Z, B - sushi - 2021-01-11T00:00:00.000Z

WITH FirstMemberPurchase AS (
    SELECT
        s.customer_id,
        m.product_name,
        s.order_date,
        MIN(s.order_date) OVER (PARTITION BY s.customer_id) as first_purchase_date
    FROM dannys_diner.sales AS s
    JOIN dannys_diner.menu AS m
    ON s.product_id = m.product_id
    JOIN dannys_diner.members AS mem ON s.customer_id = mem.customer_id
    WHERE s.order_date >= mem.join_date
    GROUP BY s.customer_id, m.product_name, s.order_date
)
SELECT
    customer_id,
    product_name AS first_item_after_membership,
    order_date
FROM
    FirstMemberPurchase
WHERE
    order_date = first_purchase_date;

-- 7. Which item was purchased just before the customer became a member? A	curry	2021-01-07T00:00:00.000Z, B	sushi	2021-01-04T00:00:00.000Z

WITH BeforeMemberPurchase AS (
    SELECT
        s.customer_id,
        m.product_name,
        s.order_date,
        MAX(s.order_date) OVER (PARTITION BY s.customer_id) as before_member_date
    FROM dannys_diner.sales AS s
    JOIN dannys_diner.menu AS m
    ON s.product_id = m.product_id
    JOIN dannys_diner.members AS mem ON s.customer_id = mem.customer_id
    WHERE s.order_date <= mem.join_date
    GROUP BY s.customer_id, m.product_name, s.order_date
)
SELECT
    customer_id,
    product_name AS first_item_before_membership,
    order_date
FROM
    BeforeMemberPurchase
WHERE
    order_date = before_member_date;

-- 8. What are the total items (COUNT) and amount spent (SUM) for each member (GROUP BY member) before they became a member (WHERE order date < join date)?

-- Customer A, 2 items, $25 spent - Customer B, 3 items, $40 spent

SELECT s.customer_id, COUNT(*) AS total_items, SUM(m.price) AS dollar_amount_spent
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
JOIN dannys_diner.members AS mem  ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id
ORDER BY dollar_amount_spent DESC;

-- 9.  If each $1 spent equates to (ELSE) 10 points and sushi has a 2x points multiplier (CASE) - how many points would each customer have?
-- Customer B - 940 points, Customer A - 860 points, Customer C - 360 points

SELECT s.customer_id,
	SUM(
      CASE
      	WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
      ELSE m.price * 10
    END
    ) AS total_points
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_points DESC;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? 
-- Customer A - 1520 points, Customer  B - 1480 points

SELECT s.customer_id,
	SUM(
      CASE
      	WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
      	WHEN mem.join_date BETWEEN '2021-01-01' AND '2021-01-31' THEN m.price * 10 * 2
      ELSE m.price * 10
    END
    ) AS total_points
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
JOIN dannys_diner.members AS mem  ON s.customer_id = mem.customer_id
GROUP BY s.customer_id
ORDER BY total_points DESC;

-- Incorrect Query above

-- Correct Query below - Customer A - 1370 points, Customer B - 820 points

SELECT s.customer_id,
    SUM(
        CASE
            WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
            WHEN s.order_date BETWEEN mem.join_date AND mem.join_date + INTERVAL '6 days' THEN m.price * 10 * 2
            ELSE m.price * 10
        END
    ) AS total_points
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
JOIN dannys_diner.members AS mem ON s.customer_id = mem.customer_id
WHERE s.customer_id IN ('A', 'B') AND s.order_date <= '2021-01-31'
GROUP BY s.customer_id;
