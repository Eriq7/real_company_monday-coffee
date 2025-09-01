--Coffee Consumers Count
--How many people in each city are estimated to consume coffee, given that 25% of the population does?
select c.city_name, population * 0.25 as estimated_coffee_ppl
from city as c

--Total Revenue from Coffee Sales
--What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
select sum(total) from sales as total_revenue_last_quarter
where extract(month from sale_date) >= 10

--Sales Count for Each Product
--How many units of each coffee product have been sold?
select p.product_name,count(s.total) as units_of_sold
from sales as s
join products as p
on s.product_id = p.product_id
group by 1
order by 2 DESC

--Average Sales Amount per City
--What is the average sales amount per customer in each city?
select ci.city_name, sum(s.total) as total_renvenue_per_city, 
count(distinct cu.customer_id) as number_customer_per_city,
round((sum(s.total)::numeric /count(distinct cu.customer_id)::numeric),2) as avg_sales_per_cx_eachcity
from sales as s
join customers as cu
on s.customer_id = cu.customer_id
join city as ci
on cu.city_id = ci.city_id
group by 1
order by 3 DESC

--City Population and Coffee Consumers
--Provide a list of cities along with their populations and estimated coffee consumers.
select city_name, population, population * 0.25 as estimated_coffee_ppl
from city
order by 3 DESC

-- Q6 Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?
select * from(

SELECT ci.city_name, p.product_name,
dense_rank() over(partition by ci.city_name order by count(sale_id) desc) as selling_rank
FROM sales s
JOIN products p 
    ON s.product_id = p.product_id
JOIN customers c 
    ON s.customer_id = c.customer_id
JOIN city ci 
    ON c.city_id = ci.city_id
group by 1,2
)
where selling_rank < 4

--Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?
SELECT * FROM products;
SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1

--Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer
-- Avg sale per customer vs. avg rent per customer (by city)
-- Avg sale per purchasing customer vs city rent
SELECT
  ci.city_name,
  ci.estimated_rent,
  COUNT(DISTINCT s.customer_id)                          AS total_cx,
  ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id), 2)
                                                         AS avg_sale_pr_cx,
  ROUND(ci.estimated_rent::numeric/COUNT(DISTINCT s.customer_id), 2)
                                                         AS avg_rent_per_cx
FROM city ci
JOIN customers c ON c.city_id = ci.city_id
LEFT JOIN sales s ON s.customer_id = c.customer_id   -- buyers-only count comes from DISTINCT on s.customer_id
GROUP BY ci.city_id, ci.city_name, ci.estimated_rent
ORDER BY avg_sale_pr_cx DESC;


--Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
-- Monthly revenue and MoM growth %
with TAble_growth
as(
SELECT 
	extract(month from s.sale_date) as sale_month, 
	extract(year from s.sale_date) as sale_year, 
	ci.city_name,
	sum(s.total) as current_month_sales,
	lag(sum(s.total),1) over(partition by ci.city_name) as last_month_sales
FROM sales s
  JOIN customers cu
  ON s.customer_id = cu.customer_id
  JOIN city ci     
  ON cu.city_id = ci.city_id
group by 1,2,3
order by 3,2
)
select sale_month,sale_year,city_name,current_month_sales,last_month_sales, 
round
((current_month_sales-last_month_sales)::numeric/ last_month_sales::numeric , 2) as growth_ratio
from table_growth


--orde by 2 since we want to stable city_name, but see the changing of sale_montht,month sale by city from 2023-2024


--Market Potential Analysis
--Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC





