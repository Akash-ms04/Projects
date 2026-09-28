CREATE TABLE Nike_Sales_Data (
    Retailer VARCHAR(50),
    Retailer_ID INT,
    Invoice_Date DATE,
    Sales_Quater VARCHAR(10),
    State VARCHAR(50),
    City VARCHAR(50),
    Product VARCHAR(50),
    Price_per_Unit DECIMAL(10, 2),
    Units_Sold INT,
    Sales_Method VARCHAR(50),
    Total_Sales DECIMAL(15, 2),
    Operating_Cost DECIMAL(15, 2),
    Operating_Profit DECIMAL(15, 2),
    Operating_Margin VARCHAR(10)
);

SELECT * FROM nike_sales_data;

--Normalization--

--Retailer Table

CREATE TABLE retailers (
    retailer_id INT PRIMARY KEY,
    retailer_name VARCHAR(100) NOT NULL
);

INSERT INTO retailers (retailer_id, retailer_name)
SELECT DISTINCT retailer_id, retailer
FROM nike_sales_data
ON CONFLICT (retailer_id) DO NOTHING;

SELECT * FROM retailers;


--Location Table
CREATE TABLE Locations (
    location_id SERIAL PRIMARY KEY,
    state VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    UNIQUE(state, city)
);

INSERT INTO locations (state, city)
SELECT DISTINCT state, city
FROM nike_sales_data;

SELECT * FROM locations;


--Products Table
CREATE TABLE Products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO products (product_name)
SELECT DISTINCT product
FROM nike_sales_data
ON CONFLICT (product_name) DO NOTHING;

SELECT * FROM products;


--Sales_Transactions Table
CREATE TABLE Sales_Transactions (
    sales_id SERIAL PRIMARY KEY,
    retailer_id INT REFERENCES Retailers(retailer_id),
    location_id INT REFERENCES Locations(location_id),
    product_id INT REFERENCES Products(product_id),
    invoice_date DATE NOT NULL,
    sales_quarter VARCHAR(2) NOT NULL,
    price_per_unit DECIMAL(10, 2),
    units_sold INT,
    sales_method VARCHAR(50),
    total_sales DECIMAL(15, 2),
    operating_cost DECIMAL(15, 2),
    operating_profit DECIMAL(15, 2),
    operating_margin DECIMAL(5, 2)
);

INSERT INTO sales_transactions
(retailer_id, location_id, product_id, invoice_date, sales_quarter, price_per_unit, units_sold, sales_method, total_sales, operating_cost, operating_profit, operating_margin)
SELECT
r.retailer_id,
l.location_id,
p.product_id,
n.invoice_date,
n.sales_quarter,
n.units_sold,
n.sales_method,
n.total_sales,
n.operating_cost,
n.operating_profit,
n.operating_margin
FROM nike_sales_data n
JOIN retailers r ON n.retailer_id = r.retailer_id
JOIN locations l ON n.state = l.state AND n.city = l.city
JOIN products p ON n.product = p.product_name;

SELECT * FROM sales_transactions;

--Problems

--Top 5 retailers based on total sales

SELECT r.retailer_name,
SUM(s.total_sales) AS total_revenue
FROM sales s
JOIN retailers r ON s.retailer_id = r.retailer_id
GROUP BY r.retailer_name
ORDER BY total_revenue DESC
LIMIT 5;

--Best selling products by units sold

SELECT p.product_name,
SUM(s.units_sold) AS total_units
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_units DESC;

--Sales performance by state and city

SELECT l.state,
l.city,
SUM(s.total_sales) AS total_revenue
FROM sales s
JOIN locations l ON s.location_id = l.location_id
GROUP BY l.state, l.city
ORDER BY total_revenue DESC;

--Sales performance by sales method

SELECT s.sales_method,
SUM(s.total_sales) AS total_revenue,
SUM(s.units_sold) AS total_units
FROM sales s
GROUP BY s.sales_method
ORDER BY total_revenue DESC;

--Most profitable products

SELECT p.product_name,
SUM(s.operating_profit) AS total_profit
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_profit DESC;

--Quarterly sales trends

SELECT sales_quarter,
SUM(total_sales) AS total_revenue
FROM sales
GROUP BY sales_quarter
ORDER BY sales_quarter;

--Retailers with highest average operating margin

SELECT r.retailer_name,
AVG(s.operating_margin) AS avg_margin
FROM sales s
JOIN retailers r ON s.retailer_id = r.retailer_id
GROUP BY r.retailer_name
ORDER BY avg_margin DESC;

--Cities with declining sales compared with previous quarter

WITH quarterly_sales AS (
SELECT l.city,
s.sales_quarter,
SUM(s.total_sales) AS revenue
FROM sales s
JOIN locations l ON s.location_id = l.location_id
GROUP BY l.city, s.sales_quarter
),
sales_comparison AS (
SELECT city,
sales_quarter,
revenue,
LAG(revenue) OVER (PARTITION BY city ORDER BY sales_quarter) AS previous_revenue
FROM quarterly_sales
)
SELECT city,
sales_quarter,
revenue,
previous_revenue
FROM sales_comparison
WHERE revenue < previous_revenue;

--Products with high sales but low margin

SELECT p.product_name,
SUM(s.total_sales) AS total_revenue,
AVG(s.operating_margin) AS avg_margin
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
HAVING AVG(s.operating_margin) < (
SELECT AVG(operating_margin) FROM sales
)
ORDER BY total_revenue DESC;

--Top performing retailer in each state

WITH retailer_sales AS (
SELECT l.state,
r.retailer_name,
SUM(s.total_sales) AS total_revenue
FROM sales s
JOIN retailers r ON s.retailer_id = r.retailer_id
JOIN locations l ON s.location_id = l.location_id
GROUP BY l.state, r.retailer_name
),
ranked_sales AS (
SELECT state,
retailer_name,
total_revenue,
RANK() OVER (PARTITION BY state ORDER BY total_revenue DESC) AS rank_position
FROM retailer_sales
)
SELECT state,
retailer_name,
total_revenue
FROM ranked_sales
WHERE rank_position = 1;
