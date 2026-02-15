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
