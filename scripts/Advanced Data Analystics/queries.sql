-- Change over time Analysis --

SELECT
	YEAR(s.order_date) AS order_year,
	Month(s.order_date) AS order_month,
	SUM(s.sales_amount) AS total_sales,
	COUNT(s.customer_key) AS total_customers,
	SUM(s.quantity) AS total_quantity
	From gold.fact_sales s
	Where order_date is not null
Group by YEAR(s.order_date), Month(s.order_date)
order by YEAR(s.order_date), Month(s.order_date);

-- Performance Analysis --

With yearly_sales AS
(
SELECT
	YEAR(f.order_date) AS order_year,
	p.product_name AS product_name,
	SUM(f.sales_amount) AS current_sales
	from gold.dim_products p
	Left Join
	gold.fact_sales f
ON p.product_key = f.product_key
WHERE f.order_date IS NOT NULL
GROUP BY YEAR(f.order_date),p.product_name
)
SELECT
	order_year,
	product_name,
	current_sales,
	AVG(current_sales) OVER(PARTITION BY product_name) AS  avg_sales,
	current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS  diff_avg,
	Case
 		WHEN current_sales - avg(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Avg'
 		WHEN current_sales - avg(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Avg'
 	ELSE 'Avg'
	END AS avg_change,
		LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS Py_sales,
		current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_py,
		CASE
			WHEN current_sales - current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
			WHEN current_sales - current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
			Else 'No Change'
		END AS py_change
FROM yearly_sales
ORDER BY product_name,order_year;

-- Part to whole Analysis --

WITH category_sales AS(	
	SELECT 
		p.category AS category,
		SUM(f.sales_amount) AS total_sales
	FROM
	gold.dim_products p 
	LEFT JOIN
	gold.fact_sales f
	ON p.product_key = f.product_key
	GROUP BY p.category
)
SELECT 
	category,
	total_sales,
	Sum(total_sales) OVER() AS overall_sales,
	CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales)OVER())*100,2),'%') AS percentage_contribution
	FROM category_sales
	WHERE total_sales IS NOT NULL
	ORDER BY total_sales DESC;

-- Product segmentation --

WITH cte AS (
SELECT
	product_name,
	product_key,
	cost,
	CASE
 		WHEN cost < 100 THEN 'Below 100'
    	WHEN cost BETWEEN 100 AND 500 THEN '100-500'
    	WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
    ELSE 'Above 1000'
    END AS cost_range
FROM gold.dim_products
)
SELECT
cost_range,
COUNT(DISTINCT product_key) AS product_count
FROM cte
GROUP BY cost_range
ORDER By COUNT(DISTINCT product_key) DESC;

-- Query Group customers into three segments based on their spending behaviour --
-- VIP - at least he has a history of 12 months and spend more than 5000 --
-- Regular - at least he has a history of 12 months nut spend less or equal to 5000 --

WITH cte AS
(
SELECT 
c.customer_key AS customer_key,
SUM(f.sales_amount) As total_spend_by_customer,
MIN(f.order_date) AS first_order,
MAX(f.order_date) AS last_order,
DATEDIFF(MONTH,MIN(f.order_date),MAX(f.order_date)) AS lifespan
FROM 
gold.dim_customers c 
LEFT JOIN
gold.fact_sales f
ON 
c.customer_key = f.customer_key
GROUP BY c.customer_key
), cte2 AS (
SELECT
customer_key,
total_spend_by_customer,
lifespan,
CASE
	WHEN lifespan >= 12 AND total_spend_by_customer > 5000 THEN 'VIP'
	WHEN lifespan >= 12 AND total_spend_by_customer <= 5000 THEN 'REGULAR'
	ELSE 'NEW'
END AS customer_group
from cte
)
SELECT
	customer_group,
	COUNT(customer_key) AS customer_count
	from cte2
GROUP BY customer_group
ORDER BY COUNT(customer_key) DESC;


