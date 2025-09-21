
/*
 TEST THE ARCHITECTURE BY MAKE REPORTS
 */

-- Report sales by country
SELECT DISTINCT
    dc.country,
    SUM(fs.sales_amount) OVER (PARTITION BY dc.country) AS country_sales
FROM gold.fact_sales fs
LEFT JOIN gold.dim_customers dc 
    ON fs.customer_key = dc.customer_key
    ORDER BY country_sales;

-- Report sales by % of total

SELECT
  x.country,
  x.country_sales,
  CAST(x.country_sales AS DECIMAL)
  / NULLIF(SUM(x.country_sales) OVER (), 0) * 100 AS percentage
FROM (
  SELECT DISTINCT
    dc.country,
    SUM(fs.sales_amount) OVER (PARTITION BY dc.country) AS country_sales
  FROM gold.fact_sales fs
  LEFT JOIN gold.dim_customers dc
    ON fs.customer_key = dc.customer_key
) AS x
ORDER BY percentage DESC;

-- Dynamic sales by time (year,month)

SELECT 
    YEAR(order_date) AS year, 
    MONTH(order_date) AS month_num,
    DATENAME(MONTH, order_date) AS month_name,
    SUM(sales_amount) AS total_sales
FROM gold.fact_sales fs
GROUP BY YEAR(order_date), MONTH(order_date), DATENAME(MONTH, order_date)
ORDER BY year, month_num;

-- TOP 10 Clients by sales
WITH totals AS (select customer_key,sum(sales_amount) as total_sales from gold.fact_sales fs GROUP BY customer_key)

SELECT TOP 10 
dc.customer_id, 
dc.customer_number,
dc.first_name,
dc.last_name,
dc.country,
dc.marital_status,
dc.gender,
dc.birth_date,
dc.create_date,
t.total_sales
from totals t
JOIN gold.dim_customers dc 
ON t.customer_key = dc.customer_key 
ORDER BY total_sales DESC

-- Top 10 products for sales

WITH sales_quantity AS (select
product_key, count(product_key) as sales_quantity from gold.fact_sales fs 
GROUP BY product_key)

select TOP 10
dp.product_id,
dp.product_number,
dp.product_name,
dp.category_id,
dp.category,
dp.subcategory,
dp.maintenance,
dp.cost,
dp.product_line,
sq.sales_quantity
from sales_quantity sq
LEFT JOIN gold.dim_products dp 
ON sq.product_key = dp.product_key 
ORDER BY sales_quantity DESC

-- AVG price per client

WITH total_sales AS (select count(*) as count, order_number, sum(fs.sales_amount) as sum_sales, fs.customer_key  from gold.fact_sales fs 
GROUP BY order_number,customer_key)

select customer_key, avg(sum_sales) from total_sales
GROUP BY customer_key

-- Analys Marginality by order


select 
	fs.order_number,
	fs.sales_amount,
	dp.cost,
	dp.cost * fs.quantity as net_price,
	dc.customer_number,
	fs.sales_amount - (dp.cost * fs.quantity) as marginality
from gold.fact_sales fs 
LEFT JOIN gold.dim_products dp 
ON fs.product_key = dp.product_key
LEFT JOIN gold.dim_customers dc 
ON fs.customer_key = dc.customer_key


-- Top 10 marginality by client 

WITH total_marginality_by_client AS (select 
fs.customer_key,
sum(fs.sales_amount - (dp.cost * fs.quantity)) as marginality,
sum(fs.sales_amount) as revenue
from gold.fact_sales fs 
left join gold.dim_products dp 
on fs.product_key = dp.product_key 
GROUP BY fs.customer_key)

select TOP 10
dc.customer_id,
dc.customer_number,
dc.first_name,
dc.last_name,
dc.country,
tmbs.marginality,
100.0 * marginality / NULLIF(revenue, 0) AS percent_marginality
from total_marginality_by_client tmbs
LEFT JOIN gold.dim_customers dc 
ON tmbs.customer_key = dc.customer_key 
ORDER BY marginality DESC


-- Average delievery time 

select AVG(CAST(DATEDIFF(DAY, fs.order_date, fs.shipping_date) AS DECIMAL(10,2))) from gold.fact_sales fs 



-- Group customers by country + show marginality (can change for gender, or age)

WITH total_marginality_by_client AS (select 
fs.customer_key,
sum(fs.sales_amount - (dp.cost * fs.quantity)) as marginality,
sum(fs.sales_amount) as revenue
from gold.fact_sales fs 
left join gold.dim_products dp 
on fs.product_key = dp.product_key 
GROUP BY fs.customer_key)
select dc.country ,sum(revenue) as total_revenue,sum(marginality) as total_marginality from total_marginality_by_client tmbs
LEFT JOIN gold.dim_customers dc 
ON tmbs.customer_key = dc.customer_key 
GROUP BY dc.country 
ORDER BY total_marginality DESC


-- Calculate total sales per month 
-- and the running total of sales over time 
-- count Moving average

SELECT 
t1.order_date,
t1.total_sales,
SUM(t1.total_sales) OVER (PARTITION BY order_date ORDER BY order_date) AS running_total_sales,
AVG(t1.avg_price) OVER (ORDER BY order_date) AS moving_average_price
FROM
(SELECT
DATETRUNC(YEAR,order_date) as order_date,
SUM(sales_amount) as total_sales,
AVG(price) as avg_price
from gold.fact_sales fs
WHERE order_date is not NULL
GROUP BY DATETRUNC(YEAR,order_date))t1

-- Analyze the yearly perfomance of products
-- by comparing each product sales to both its
-- average sales perfomance and the previous year sales

WITH yearly_product_sales AS(
SELECT 
YEAR(fs.order_date) AS order_year,
dp.product_name,
sum(fs.sales_amount) as current_sales
from gold.fact_sales fs 
LEFT JOIN gold.dim_products dp 
ON fs.product_key = dp.product_key 
WHERE order_date is not NULL
GROUP by 
YEAR(fs.order_date),
dp.product_name)
select 
order_year,
product_name,
current_sales,
AVG(current_sales ) OVER (PARTITION BY product_name) avg_sales,
current_sales - AVG(current_sales ) OVER (PARTITION BY product_name) as diff_avg,
CASE WHEN current_sales - AVG(current_sales ) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
	WHEN current_sales - AVG(current_sales ) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
	ELSE 'AVG'
	END avg_change,
LAG(current_sales ) OVER (PARTITION BY product_name ORDER BY order_year) as py_sales,
current_sales - LAG(current_sales ) OVER (PARTITION BY product_name ORDER BY order_year) as diff_py,
CASE WHEN current_sales - LAG(current_sales ) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	WHEN current_sales - LAG(current_sales ) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	ELSE 'No change'
	END py_change
from yearly_product_sales
ORDER BY product_name ,order_year


-- Which categories make most sales?
WITH category_sales as (select
dp.category as category,
SUM(fs.sales_amount) as total_sales
from gold.fact_sales fs
LEFT JOIN gold.dim_products dp 
ON fs.product_key  = dp.product_key 
GROUP BY dp.category)
select
category,
total_sales,
SUM (total_sales) OVER() as overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM (total_sales) OVER()) * 100,2),'%') as percentage_of_total
from
category_sales
ORDER BY total_sales DESC

-- Segment products into cost ranges 
-- Count how many products fail

with product_segment AS (select 
dp.product_key,
dp.product_name ,
cost,
CASE WHEN cost < 100 THEN 'Below 100'
	WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	WHEN cost BETWEEN 500 and 1000 then '500-1000'
	ELSE 'Above 1000'
	END costs_range
from gold.dim_products dp)
SELECT
costs_range,
COUNT(product_key) as total_products
FROM product_segment
GROUP BY costs_range
ORDER BY total_products DESC


-- Group customers into 3 segments: -VIP,REGULAR,NEW according to sales

with customer_spending AS (SELECT
dc.customer_key,
SUM(fs.sales_amount) as total_spending,
MIN(fs.order_date) as first_order,
MAX(fs.order_date) as last_order,
DATEDIFF(MONTH,MIN(fs.order_date),MAX(fs.order_date)) as lifespan
FROM gold.fact_sales fs 
LEFT JOIN gold.dim_customers dc 
ON fs.customer_key  = dc.customer_key 
GROUP BY dc.customer_key)


SELECT
customer_segment,
count(customer_key) as total_customers
from (
SELECT
customer_key,
CASE WHEN lifespan > = 12 and total_spending > 5000 THEN 'VIP'
	WHEN lifespan > = 12 and total_spending <= 5000 THEN 'Regular'
	ELSE 'New'
END customer_segment
FROM customer_spending)t1
GROUP BY customer_segment
ORDER BY total_customers DESC




