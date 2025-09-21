/*
 ===============
 Customer Report
 ===============
 
 
 -- This report consolidate customer metrics and behaviour
 */
CREATE VIEW gold.report_customers AS
WITH base_query AS (
SELECT 
fs.order_number,
fs.product_key,
fs.order_date,
fs.sales_amount,
fs.quantity,
dc.customer_key,
dc.customer_number,
CONCAT(dc.first_name, ' ', dc.last_name) as customer_name,
DATEDIFF(year,dc.birth_date, GETDATE()) as age
from gold.fact_sales fs 
LEFT JOIN gold.dim_customers dc 
ON fs.customer_key = dc.customer_key 
WHERE fs.order_date  is not NULL)

, customer_aggregation as (
select 
customer_key,
customer_number,
customer_name,
age,
COUNT(DISTINCT order_number) as total_orders,
SUM(sales_amount) as total_sales,
SUM(quantity) as total_quantity,
COUNT(DISTINCT product_key) as total_products,
MAX(order_date) as last_order_date,
DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) as lifespan
from base_query
GROUP BY 
customer_key,
customer_number,
customer_name,
age)


SELECT 
customer_key,
customer_number,
customer_name,
age,
CASE WHEN age < 20 THEN 'Under 20'
	WHEN age BETWEEN 20 and 29 THEN '20-29'
	WHEN age BETWEEN 30 and 39 THEN '30-39'
	WHEN age BETWEEN 40 and 49 THEN '40-49'
	ELSE '50 and Above'
END age_group,
CASE WHEN lifespan > = 12 and total_sales > 5000 THEN 'VIP'
	WHEN lifespan > = 12 and total_sales <= 5000 THEN 'Regular'
	ELSE 'New'
END customer_segment,
last_order_date,
DATEDIFF(month, last_order_date, GETDATE()) as recency,
total_orders,
total_sales,
total_quantity,
total_products,
lifespan,
CASE when total_orders = 0 THEN 0
	else total_sales / total_orders 
END AS avg_order_value,
CASE WHEN lifespan = 0 THEN total_sales
	else total_sales / lifespan
	END avg_monthly_spend
FROM customer_aggregation
