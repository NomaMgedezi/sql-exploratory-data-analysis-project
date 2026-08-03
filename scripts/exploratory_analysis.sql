-- Create Database and Schemas -- 
/*
Script Purpose:
    This script creates a new database named 'DataWarehouseAnalytics' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, this script creates a schema called gold
	
WARNING:
    Running this script will drop the entire 'DataWarehouseAnalytics' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouseAnalytics' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics;
END;
GO

-- Create the 'DataWarehouseAnalytics' database
CREATE DATABASE DataWarehouseAnalytics;
GO

USE DataWarehouseAnalytics;
GO

-- Create Schemas

CREATE SCHEMA gold;
GO

CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);
GO

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);
GO

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);
GO

TRUNCATE TABLE gold.dim_customers;
GO

BULK INSERT gold.dim_customers
FROM 'C:\Users\nomam\SQL\SQL_Data_Analytics_Project\csv-files\gold.dim_customers.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.dim_products;
GO

BULK INSERT gold.dim_products
FROM 'C:\Users\nomam\SQL\SQL_Data_Analytics_Project\csv-files\gold.dim_products.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.fact_sales;
GO

BULK INSERT gold.fact_sales
FROM 'C:\Users\nomam\SQL\SQL_Data_Analytics_Project\csv-files\gold.fact_sales.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO


-- Database Exploration
/*
Purpose:
    - To explore the structure of the database, including the list of tables and their schemas.
    - To inspect the columns and metadata for specific tables.

Table Used:
    - INFORMATION_SCHEMA.TABLES
    - INFORMATION_SCHEMA.COLUMNS
*/


SELECT DISTINCT
customer_id
FROM gold.dim_customers

-- Wxplore All Objects in the Database
SELECT * FROM INFORMATION_SCHEMA.TABLES

-- Explore All Columns in the Database
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers'


-- Dimension Exploration (Identifying unique values or categories in each dimension. Recognizing how data might be grouped or segmented, which is used for later analysis.)
-- Explore All Countries our customers come from.
SELECT DISTINCT 
country
FROM gold.dim_customers

-- Explore All Categories "The major Divisons"
SELECT DISTINCT
category, subcategory, product_name
FROM gold.dim_products
ORDER BY 1,2,3

-- Date Exploration(identify the earliest and latest dates(boundries)) understand the the scope of data and the timespan.
-- Find the date of the first and last order
-- How many years of sales are available
SELECT 
MIN(order_date) AS first_order_date,
MAX(order_date) AS last_order_date,
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS order_range_months
FROM gold.fact_sales

-- Find the  youngest and the oldest customer
SELECT 
MIN(birthdate) AS oldest_birthdate,
MAX(birthdate) AS youngest_birthdate
FROM gold.dim_customers

-- if you want the actual years and not the year
SELECT 
MIN(birthdate) AS oldest_birthdate,
DATEDIFF(year, MIN(birthdate), GETDATE()) AS oldest_age,
MAX(birthdate) AS youngest_birthdate,
DATEDIFF(year, MAX(birthdate), GETDATE()) AS youngest_age
FROM gold.dim_customers


-- Measures Exploration (Key Metrics)
/*
Purpose:
    - To calculate aggregated metrics (e.g., totals, averages) for quick insights.
    - To identify overall trends or spot anomalies.

SQL Functions Used:
    - COUNT(), SUM(), AVG()
*/
-- Exploring measures(calculate the key matric of the business(Big Numbers)
-- Highest level of aggregation. Lowest level of Details

-- Find the Total Sales
SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales

-- Find how many items are sold
SELECT SUM(quantity) AS total_quantity FROM gold.fact_sales

-- Find the average selling price
SELECT AVG(sls_price) AS avg_price FROM gold.fact_sales

-- Find the total number of orders
SELECT COUNT(order_number) AS total_orders FROM gold.fact_sales
SELECT COUNT(DISTINCT order_number) AS total_orders FROM gold.fact_sales
SELECT * FROM gold.fact_sales 

-- Find total number of products
SELECT COUNT(product_key) AS total_products FROM gold.dim_products
SELECT COUNT(product_name) AS total_products FROM gold.dim_products

-- Find the total number of customers
SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers

-- Find the total number of customers that has placed an order
SELECT COUNT(DISTINCT customer_key) AS total_customers FROM gold.fact_sales

-- Generate a Report that shows all key metrics of the business
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL 
SELECT 'Total Quantity' AS measure_value, SUM(quantity) AS measure_value FROM gold.fact_sales
UNION ALL 
SELECT 'Average Price', AVG(sls_price) AS avg_price FROM gold.fact_sales
UNION ALL 
SELECT 'Total Nr. Orders', COUNT(DISTINCT order_number) AS total_orders FROM gold.fact_sales
UNION ALL 
SELECT 'Total Nr. Products', COUNT(product_name) AS total_products FROM gold.dim_products
UNION ALL
SELECT 'Total Nr. Customers', COUNT(customer_key) AS total_customers FROM gold.dim_customers


-- Magnitude Analysis--
/*
Purpose:
    - To quantify data and group results by specific dimensions.
    - For understanding data distribution across categories.

SQL Functions Used:
    - Aggregate Functions: SUM(), COUNT(), AVG()
    - GROUP BY, ORDER BY
*/
-- Find total customers by country
SELECT 
country,
COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC

-- Find total customers by gender
SELECT 
gender,
COUNT(customer_key) AS total_cutomers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_cutomers DESC 

-- Find total products by categody
SELECT
category,
COUNT(product_key) AS  total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC

-- Find the average costs in each category?
SELECT
category,
AVG(costs) AS  avg_costs
FROM gold.dim_products
GROUP BY category
ORDER BY avg_costs DESC

-- What is the total revenue generated for eachh category?
SELECT 
p.category,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC 

-- What is the total revenue generated by each customer?
SELECT 
c.customer_key,
c.first_name,
c.last_name,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY 
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_revenue DESC


-- What is the distribution of sold items across countries?
SELECT 
c.country,
SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY 
c.country
ORDER BY total_sold_items DESC


-- Ranking Analysis --
/*
Purpose:
    - To rank items (e.g., products, customers) based on performance or other metrics.
    - To identify top performers or laggards.

SQL Functions Used:
    - Window Ranking Functions: RANK(), DENSE_RANK(), ROW_NUMBER(), TOP
    - Clauses: GROUP BY, ORDER BY
*/
-- Ranking analysis --

-- Which 5 products generates the highest revenue?
SELECT TOP 5
p.subcategory,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.subcategory
ORDER BY total_revenue DESC 

SELECT 
* 
FROM (
SELECT 
p.product_name,
SUM(f.sales_amount) AS total_revenue,
RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.product_name
) t WHERE rank_products <= 5

-- What are the 5 worst perfoming products in terms of sales?
SELECT TOP 5
p.product_name,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC 

SELECT 
* 
FROM (
SELECT 
p.product_name,
SUM(f.sales_amount) AS total_revenue,
RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.product_name
) t WHERE rank_products <= 5

-- Find the top 10 customers who have generated the highest revenue
SELECT TOP 10
c.customer_key,
c.first_name,
c.last_name,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY 
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_revenue DESC

-- Find 3 customers with the feewest orders placed
SELECT TOP 3
c.customer_key,
c.first_name,
c.last_name,
COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY 
c.customer_key,
c.first_name,
c.last_name
ORDER BY total_orders 


-- Change Over Time Analysis --
/*
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

SQL Functions Used:
    - Date Functions: DATEPART(), DATETRUNC(), FORMAT()
    - Aggregate Functions: SUM(), COUNT(), AVG()
*/

-- Change over years (high level overview insights that helps with strategic decision making)
-- Analyse sales performance over time
-- Quick Date Functions
SELECT 
YEAR(order_date) AS order_year,
MONTH(order_date) AS order_month,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

-- Change over the monhts
-- DATETRUNC()
SELECT 
DATETRUNC(month, order_date) AS order_date,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY DATETRUNC(month, order_date)

-- FORMAT()
SELECT 
FORMAT(order_date, 'yyyy-MMM') AS order_date,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM')


-- Cumulative Analysis --
/*
Purpose:
    - To calculate running totals or moving averages for key metrics.
    - To track performance over time cumulatively.
    - Useful for growth analysis or identifying long-term trends.

SQL Functions Used:
    - Window Functions: SUM() OVER(), AVG() OVER()
*/

-- Calculate the total sales per month
-- and the running total of sales over time
SELECT
order_date,
total_sales,
SUM(total_sales) OVER(PARTITION BY order_date ORDER BY order_date) AS running_total_sales, -- window function
AVG(avg_price) OVER(ORDER BY order_date) AS moving
FROM
 (
SELECT 
DATETRUNC(month, order_date) AS order_date,
SUM(sales_amount) AS total_sales,
AVG(price) AS avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
) t

SELECT * FROM gold.fact_sales



-- Performance Analysis (Year-over-Year, Month-over-Month) --
/*
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
*/

/* Analyze the yearly perfomance of products by comparing their sales
    to both average sales perfomance of the product and the previous year's sales */

    WITH yearly_product_sales AS (
    SELECT
    YEAR(f.order_date) AS order_year, -- for month-over-month analysis change year to month
    p.product_name,
    SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(f.order_date), p.product_name
    ) 
    SELECT 
    order_year,
    product_name,
    current_sales,
    -- Average sales of this product across all years
    AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
    -- Difference from average
    current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS diff_avg,
    CASE 
         WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Avg'
         WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Avg'
         ELSE 'Avg'
    END AS avg_change,
    -- Year-over-year Analysis -- 
    -- Previous year’s sales
         LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
    -- Difference from previous year
    current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_previous_year,
    CASE 
         WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
         WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
         ELSE 'No change'
    END  AS previous_year_sales
    FROM yearly_product_sales
    ORDER BY product_name, order_year



-- Part-to-Whole Analysis --
/*
Purpose:
    - To compare performance or metrics across dimensions or time periods.
    - To evaluate differences between categories.
    - Useful for A/B testing or regional comparisons.

SQL Functions Used:
    - SUM(), AVG(): Aggregates values for comparison.
    - Window Functions: SUM() OVER() for total calculations.
*/
-- Which categories contribute the most to overall sales?
WITH category_sales AS (
SELECT 
category,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales f 
LEFT JOIN gold.dim_products p 
ON p.product_key = f.product_key
GROUP BY category
)
 SELECT 
 category,
 total_sales,
 SUM(total_sales) OVER() overall_sales,
 CONCAT(ROUND((CAST (total_sales AS FLOAT) / SUM(total_sales) OVER()) * 100, 2), '%') AS percentage_of_total
 FROM category_sales
 ORDER BY total_sales DESC


-- Data Segmentation Analysis --
/*
Purpose:
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.

SQL Functions Used:
    - CASE: Defines custom segmentation logic.
    - GROUP BY: Groups data into segments.
*/
 -- Date segmentation (group data based on specific range, helps undertand the correlation between two measures)

    WITH product_segments AS (
    SELECT 
    product_key,
    product_name,
    cost,
    CASE WHEN cost < 100 THEN 'Below 100'
         WHEN cost BETWEEN 100 AND 500 THEN '100-500'
         WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
         ELSE 'Above 1000'
    END AS cost_range
    FROM gold.dim_products
    ) 
     SELECT 
     cost_range,
     COUNT(product_key) AS total_products
     FROM product_segments 
     GROUP BY cost_range
     ORDER BY total_products DESC 



/* Group customers into three segments based on their spending behaviour:
   - VIP: Customers with at least 12 months of history and spending more than $5,000.
   - Regular: Customers with at least 12 monhts of history but spending $5,000 or less.
   - New: Customers with a lifespan less than 12 months.
  And find the total number of customers by each group 
*/

WITH customers_spending AS (
SELECT 
c.customer_key,
SUM(f.sales_amount) AS total_spending,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key
)
 SELECT 
 customer_segment,
 COUNT(customer_key) AS total_customers
 FROM (
     SELECT 
         customer_key,
         CASE 
            WHEN lifespan >= 12 AND total_spending > 5000 THEN 'Vip'
            WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
         FROM customers_spending ) t 
        GROUP BY customer_segment
        ORDER BY total_customers DESC 







