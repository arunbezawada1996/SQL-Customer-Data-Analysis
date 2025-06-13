

-- CHANGE OVER TIME TRENDS
-- Selecting sales amount by order date
select 
order_date, sales_amount 
from gold.fact_sales 
order by order_date

-- Printing the sales amount based on order date without null values
select 
order_date, sum(sales_amount) as total_sales 
from gold.fact_sales 
where order_date is not null
group by order_date
order by order_date

-- CHANGE OVER TIME ANALYSIS
-- Selecting sales amount total over entire year with customer key
-- A high level overview that helps with strategic decision making with monthly data
select 
datetrunc(month, order_date) as month_order_date, 
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from gold.fact_sales 
where order_date is not null
group by datetrunc(month, order_date)
order by datetrunc(month, order_date)

-- How many new customers were added each year
select
datetrunc(year, create_date) as create_year,
count(customer_key) as total_customers
from gold.dim_customers
group by datetrunc(year, create_date)
order by datetrunc(year, create_date)

-- CUMULATIVE ANALYSIS
-- Aggregate data progressively over time
-- Calculate the total sales for each month and running total of sales over time
select
order_date,
total_sales,
SUM(total_sales) over (order by order_date) as running_total_sales
from
(
select
Datetrunc(month, order_date) as order_date,
sum(sales_amount) as total_sales
from gold.fact_sales
where order_date is not null
group by datetrunc(month, order_date)
)t

-- PERFORMANCE ANALYSIS
-- Analyze yearly performance of products by comparing their sales to 
-- (both average sales performance of product and previous year sales)
with yearly_product_sales as (
select
year(f.order_date) as order_year,
p.product_name,
sum(f.sales_amount) as current_sales
from gold.fact_sales f
left join gold.dim_products p
on f.product_key = p.product_key
where f.order_date is not null
group by
year(f.order_date),
p.product_name
)

select 
order_year,
product_name,
current_sales,
avg(current_sales) over (partition by product_name) as avg_sales,
current_sales - avg(current_sales) over (partition by product_name) as diff_avg,
case when current_sales - avg(current_sales) over (partition by product_name) > 0 then 'above avg'
     when current_sales - avg(current_sales) over (partition by product_name) < 0 then 'below avg'
     else 'avg'
end avg_change,
-- Year over year Analysis
lag(current_sales) over (partition by product_name order by order_year) py_sales,
current_sales - lag(current_sales) over (partition by product_name order by order_year) as diff_py,
case when current_sales - lag(current_sales) over (partition by product_name order by order_year) > 0 then 'increase'
     when current_sales - lag(current_sales) over (partition by product_name order by order_year) < 0 then 'decrease'
     else 'no change'
end py_change
from yearly_product_sales
order by product_name, order_year

-- PART TO WHOLE ANALYSIS
-- Analyze how an individual part is performing compared to overall, allowing us to understand which category has greatest impact
with category_sales as(
select
category,
SUM(sales_amount) total_sales
from gold.fact_sales f
left join gold.dim_products p
on p.product_key = f.product_key
group by category)

select
category,
total_sales,
sum(total_sales) OVER () overall_sales,
concat(round((cast(total_sales as float)/ sum(total_sales) over ())*100,2), '%') as percentage_of_total
from category_sales
order by total_sales desc

-- DATA SEGEMENTATION
-- Group the data based on specific range, helps understand the correlation between two measures
-- Segmenting products into cost ranges and count the no of products falling into each segment
with product_segments as (
select 
product_key,
product_name,
cost,
case when cost < 100 then 'below 100'
     when cost between 100 and 500 then '100-500'
     when cost between 500 and 1000 then '500-1000'
     else 'above 1000'
end cost_range
from gold.dim_products p)

select
cost_range,
count(product_key) as total_products
from product_segments
group by cost_range
order by total_products desc

-- Group customers into three segments based on their spending behavior
-- VIP: Customers with atleast 12 months of history and spending more than $10000.
-- Regular: Customers with atleast 12 months of history but spending $5000 or less.
-- New: Customers with spending less than 12 months.
-- Finding total number of customers by each group.

WITH customer_spending AS (
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
      WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
      WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
      ELSE 'New'
    END customer_segment
  FROM customer_spending
) t
GROUP BY customer_segment
ORDER BY total_customers DESC

-- Building Customer Report
-- This rpeort consolidates key customer metrics and behaviors
-- Gathers essental fields like names, age and transaction details.
-- Segments customers into cetegories (VIP, Regular, New) and age groups.
-- Aggregating customer level metrics like total orders, sales, qty purchased, products, lifespan (months)
-- Calculates valuable KPIs like recency (months in last order), average order value, average monthly spending
create view gold.report_customers as
WITH base_query AS (
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        DATEDIFF(year, c.birthdate, GETDATE()) AS age
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON c.customer_key = f.customer_key
    WHERE order_date IS NOT NULL
),

customer_aggregation AS (
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MAX(order_date) AS last_order_date,
        DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY 
        customer_key,
        customer_number,
        customer_name,
        age
)

SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    CASE 
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,
    CASE 
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
    last_order_date,
    DATEDIFF(month, last_order_date, GETDATE()) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products
    lifespan,
    -- Compute average order value (AVO)
    case when total_sales = 0 then 0
         else total_sales / total_orders
    end as avg_order_value,
    -- Compute average monthly spend
    case when lifespan = 0 then total_sales
         else total_sales / lifespan
    end as avg_monthly_spend
    FROM customer_aggregation

select * from gold.report_customers

select 
customer_segment,
count(customer_number) as total_customers,
sum(total_sales) total_sales
from gold.report_customers
group by customer_segment

----------------------------------------------------
-- Product Report:
-- Highlights key product metrics and behaviors
-- gathers essential fields such as product name, category, subcategory and cost.
-- Segments products by revenue to identify High, Mid range and Low performers
-- Aggregate product level metrics - total orders, sales, qty sold, customers, lifespan 
-- Calculate valuable KPIs recency, average order revenue, average monthly revenue

create view gold.report_products as
WITH base_query AS (
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost

    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE order_date IS NOT NULL -- cosnider valid sales dates
),

product_aggregations AS (
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        datediff(month, min(order_date), max(order_date)) as lifespan,
        max(order_date) as last_sale_date,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        round(avg(cast(sales_amount as float) / nullif(quantity, 0)),1) as avg_selling_price
    FROM base_query

    GROUP BY 
        product_key,
        product_name,
        category,
        subcategory,
        cost
)

-- Combines all result into one output
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
    CASE 
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,
    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
-- Average Order Revenue (AOR)
CASE 
    WHEN total_orders = 0 THEN 0
    ELSE total_sales / total_orders
END AS avg_order_revenue,

-- Average Monthly Revenue
CASE 
    WHEN lifespan = 0 THEN total_sales
    ELSE total_sales / lifespan
END AS avg_monthly_revenue

FROM product_aggregations
