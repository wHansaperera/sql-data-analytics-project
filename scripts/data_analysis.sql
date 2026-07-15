-- ANALYSIS CHANGE OVER TIME

use DataWarehouseAnalytics

--Get sales amount and corresponding date column and ordered by ordered date.
--We get not null values of order date
SELECT  
order_date,
sales_amount
FROM gold.fact_sales
WHERE order_date IS NOT NULL
ORDER BY order_date

--Use aggregation function of sum of sales and then grouped by date
--named column name as sum_of_total
--grouped by year of order date using YEAR() and named as order_year
--now we can how sales are change yearly
SELECT 
YEAR(order_date) AS order_year,
SUM(sales_amount) AS toal_of_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

--we can get same as total customes ordered in each year
-- this help us get overall idea about how sales,customers and quantities are change over year

SELECT 
YEAR(order_date) AS order_year,
SUM(sales_amount) AS total_of_sales,
COUNT( DISTINCT customer_key) AS total_of_customers,
SUM(quantity) AS sum_of_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

--we can get same as for aggregate with MONTH()
-- this help us get overall idea about how sales,customers and quantities are change over months
-- here not specified what year that month belong 

SELECT 
MONTH(order_date) AS order_month,
SUM(sales_amount) AS total_of_sales,
COUNT( DISTINCT customer_key) AS total_of_customers,
SUM(quantity) AS sum_of_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date)

-- here specified what year that month belong 
-- now we can understand that how sales are change start to end in data set

SELECT 
YEAR(order_date) AS order_year,
MONTH(order_date) AS order_month,
SUM(sales_amount) AS total_of_sales,
COUNT( DISTINCT customer_key) AS total_of_customers,
SUM(quantity) AS sum_of_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date),MONTH(order_date)
ORDER BY YEAR(order_date),MONTH(order_date)

--we can do same using DATETRUNC() method
-- we get one column for order date but same result as above

SELECT 
DATETRUNC(month,order_date) AS order_date,
SUM(sales_amount) AS total_of_sales,
COUNT( DISTINCT customer_key) AS total_of_customers,
SUM(quantity) AS sum_of_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
ORDER BY DATETRUNC(month,order_date)

-- if need some format like YYYY-MMM
-- we use FORMAT()

SELECT 
FORMAT(order_date,'yyyy-MMM') AS order_date,
SUM(sales_amount) AS total_of_sales,
COUNT( DISTINCT customer_key) AS total_of_customers,
SUM(quantity) AS sum_of_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date,'yyyy-MMM')
ORDER BY FORMAT(order_date,'yyyy-MMM')


------------------ CUMULATIVE ANALYSIS---------------------

--aggregate the data progressively over time.helps to understand whether our buisness is growing or declining  
--SIGMA[Cumulative Measure] BY [Date Dimention]

-- Use window function
-- SQL Task : calculate the total sales per month and the running total of sales over time.


--get month and sum of sales for each month using non null order dates 
SELECT 
DATETRUNC(month,order_date) AS order_date,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)

--But we need adding sales month by month so we use window function to get running_total_sales
SELECT 
order_date,
total_sales,
SUM(total_sales) OVER ( ORDER BY order_date) AS running_total_sales
FROM
(
SELECT 
DATETRUNC(month,order_date) AS order_date,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
) t --- temporary get monthly data and outer query then calculate running total sales using this data from t

-- In above running total column calculate all previous sales upto current month
-- So we need to make a limit to year by partitioning  

SELECT 
order_date,
total_sales,
SUM(total_sales) OVER ( ORDER BY order_date) AS running_total_sales
FROM
(
SELECT 
DATETRUNC(year,order_date) AS order_date,
SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(year,order_date)
) t

-- now take moving average of prices

SELECT 
order_date,
total_sales,
SUM(total_sales) OVER ( ORDER BY order_date) AS running_total_sales,
AVG(total_price) OVER ( ORDER BY order_date) AS moving_average_price
FROM
(
SELECT 
DATETRUNC(year,order_date) AS order_date,
SUM(sales_amount) AS total_sales,
AVG(price) AS total_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(year,order_date)
) t

----------------------Performance Analysis -------------------------
--comparing the current value to a target value.
-- Current[measure] - Target[measure]
/*SQL Task: analyze the yearly performance of products by comparing each product's sales to both its 
average sales performance and the previous year's sales.*/

SELECT 
YEAR(f.order_date) AS order_year,
p.product_name,
SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY YEAR(f.order_date), p.product_name;

-- now need to compare with average sales and previous year sales
WITH yearly_product_sales AS (
SELECT  
YEAR(f.order_date) AS order_year,
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
AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,--compare with avg sales
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above avg'
	 WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below avg'
	 ELSE 'avg'
END avg_change,
-- Year over Year analysis-----------------
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year)  py_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	 WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	 ELSE 'No Change'
END py_change
FROM yearly_product_sales
ORDER BY product_name,order_year
;

-- PART TO WHOLE ANALYSIS--
/*Analyze how an individual part is performing compared to the overall,
allowing us to understand which category has the greatest impact on the buisness.*/
-- ([measure]/Total[measure] * 100 by [dimention] | dimention can be category

-- SQL Task: Which categories contribute the most to overall sales?

--get category column from product table and sales amount from sales table
--window function to get sum of sales 

WITH category_sales AS (
SELECT 
category,
SUM(sales_amount) total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
GROUP BY category
)
SELECT
category,
total_sales,
SUM(total_sales) OVER () overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100,2),' %') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC


-- DATA SEGMENTATION --
/* Group the data based on a specific range. Helps understand the correlation between measures.*/

-- [measure] By [measure]
/* Ex:
	Total products by sales range
	Total customers by age 
*/ 
/* SQL TASK : Segment products into cost ranges and count how many products fall into each segment.*/

WITH product_segments AS (
SELECT 
product_key,
product_name,
cost,
CASE WHEN cost < 100 THEN 'Below 100'
	 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	 ELSE 'Above 1000'
END cost_range
FROM gold.dim_products)
SELECT
cost_range,
COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC

/* SQL task : Group customers into three segments based on their spending behavior:
- VIP - at least 12 months of history and spending more than euro 5000
- Regular - at least 12 months of history but spending euro 5000 or less
- New: lifespan less than 12 customers

and find the total number of customers by each group. */
SELECT 
p.customer_key,
COUNT(s.order_number) AS number_of_orders,
DATEDIFF(month,MIN(order_date),MAX(order_date)) AS life_span,
SUM(s.sales_amount) AS total_expenses,
CASE WHEN DATEDIFF(month,MIN(order_date),MAX(order_date)) >= 12 AND SUM(s.sales_amount) > 5000 THEN 'VIP'
	 WHEN DATEDIFF(month,MIN(order_date),MAX(order_date)) >= 12 OR SUM(s.sales_amount) <= 5000 THEN 'Regular'
	 ELSE 'Newer'
END 'user_segment'
FROM gold.dim_customers p
LEFT JOIN gold.fact_sales s
ON p.customer_key = s.customer_key
GROUP BY p.customer_key;

--- user segments and count table---

WITH customer_segmentation AS (
SELECT 
p.customer_key,
COUNT(s.order_number) AS number_of_orders,
DATEDIFF(month,MIN(order_date),MAX(order_date)) AS life_span,
SUM(s.sales_amount) AS total_expenses,
CASE WHEN DATEDIFF(month,MIN(order_date),MAX(order_date)) >= 12 AND SUM(s.sales_amount) > 5000 THEN 'VIP'
	 WHEN DATEDIFF(month,MIN(order_date),MAX(order_date)) >= 12 AND SUM(s.sales_amount) <= 5000 THEN 'Regular'
	 ELSE 'Newer'
END 'user_segment'
FROM gold.dim_customers p
LEFT JOIN gold.fact_sales s
ON p.customer_key = s.customer_key
GROUP BY p.customer_key
)
SELECT
user_segment,
COUNT(customer_key) AS number_of_users
FROM customer_segmentation
GROUP BY user_segment;

--- customer key and they loyalty table

WITH customer_segmentation AS (
SELECT 
p.customer_key,
COUNT(s.order_number) AS number_of_orders,
DATEDIFF(month,MIN(order_date),MAX(order_date)) AS life_span,
SUM(s.sales_amount) AS total_expenses,
CASE WHEN DATEDIFF(month,MIN(order_date),MAX(order_date)) >= 12 AND SUM(s.sales_amount) > 5000 THEN 'VIP'
	 WHEN DATEDIFF(month,MIN(order_date),MAX(order_date)) >= 12 AND SUM(s.sales_amount) <= 5000 THEN 'Regular'
	 ELSE 'Newer'
END 'user_segment'
FROM gold.dim_customers p
LEFT JOIN gold.fact_sales s
ON p.customer_key = s.customer_key
GROUP BY p.customer_key
)
SELECT
customer_key,
total_expenses,
life_span,
number_of_orders,
user_segment
FROM customer_segmentation;


