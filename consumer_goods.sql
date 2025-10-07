-- Q1. Provide the list of markets in which customer 
-- "Atliq Exclusive" operates its business in the APAC region.

select distinct(market) 
from dim_customer 
where customer like "atliq exclusive" and region="apac"
order by market



-- Q2 What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields
-- unique_products_2020 ,unique_products_2021 ,percentage_chg

WITH a AS (
  SELECT COUNT(DISTINCT product_code) AS c
  FROM fact_sales_monthly
  WHERE fiscal_year = 2020
),
b AS (
  SELECT COUNT(DISTINCT product_code) AS d
  FROM fact_sales_monthly
  WHERE fiscal_year = 2021
)
SELECT 
  a.c AS unique_products_2020,
  b.d AS unique_products_2021,
  ((b.d / a.c) - 1) * 100 AS change_percent
FROM a
 JOIN b;


-- Q3 Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
-- The final output contains 2 fields segment, product_count

select 
segment,count(distinct(product_code)) as product_count
 from dim_product
 group by segment
 order by product_count desc
 
 
 
 
 
 
 
 -- Q4 Which segment had the most increase in unique products in 2021 vs 2020? 
 -- The final output contains these fields segment, product_count_2020, product_count_2021, difference
 
 with a as 
 (select 
p.segment,s.fiscal_year,count(distinct(s.product_code)) as pr
 from dim_product p
 join fact_sales_monthly s
 on p.product_code=s.product_code
 where s.fiscal_year=2020
 group by segment),
b as 
(
select 
p.segment,s.fiscal_year,count(distinct(s.product_code)) as pro
 from dim_product p 
 join fact_sales_monthly s
 on p.product_code=s.product_code
 where s.fiscal_year=2021
  group by segment)
 select a.segment,a.pr as product_count_2020, 
 b.pro as product_count_2021,b.pro-a.pr as difference
 from a
cross join b
 on a.segment=b.segment 
 
 
 
 -- Q5. Get the products that have the highest and lowest manufacturing costs.
 -- The final output should contain these fields, product_code, product, manufacturing_cost
 
 select m.product_code,p.product,m.manufacturing_cost
 from fact_manufacturing_cost m
 join dim_product p
 on m.product_code=p.product_code
 where m.manufacturing_cost in 
 ((select max(manufacturing_cost)
 from fact_manufacturing_cost),
 (select min(manufacturing_cost) 
 from fact_manufacturing_cost))
 
 
 -- Q6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
 -- The final output contains these fields, customer_code customer average_discount_percentage
 select p.customer_code,c.customer,
 round(avg(pre_invoice_discount_pct),4) as average_discount_percentage 
 from fact_pre_invoice_deductions p
 join dim_customer c
 on p.customer_code=c.customer_code
 where fiscal_year=2021 and c.market like "india"
 group by customer_code
 order by average_discount_percentage desc limit 5
 
 -- Q7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
 -- This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
 -- The final report contains these columns: Month, Year, Gross sales Amount

 select monthname(s.date) as month,
 s.fiscal_year as fiscal_year,
 ROUND(SUM(G.gross_price*S.sold_quantity), 2) 
 as gross_sales_amount
 from fact_sales_monthly s
 join fact_gross_price g 
 on g.product_code=s.product_code 
 join dim_customer c
 on s.customer_code=c.customer_code
 where c.customer = "atliq exclusive" 
group by month,s.fiscal_year 
ORDER BY S.fiscal_year 



 
-- Q8. In which quarter of 2020, got the maximum total_sold_quantity?
-- The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity

 select get_Quarter(date) as Quarter,
 sum(sold_quantity) as total_sold_quantity
 from fact_sales_monthly 
 where fiscal_year=2020
 group by get_Quarter(date)




-- Q9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
-- The final output contains these fields, channel, gross_sales_mln, percentage

with a as
(
select s.product_code,s.fiscal_year,c.channel,
sum(s.sold_quantity*g.gross_price)/1000000 
as gross_sales_mln
from dim_customer c
join fact_sales_monthly s
on c.customer_code=s.customer_code
join fact_gross_price g
on g.product_code=s.product_code 
where s.fiscal_year=2021 
group by c.channel
),
b as
(
select s.product_code,s.fiscal_year,
sum(sold_quantity*gross_price)/1000000
as total_gross_price
from fact_sales_monthly s
join fact_gross_price g
on g.product_code=s.product_code
where s.fiscal_year=2021
)
select a.channel,round(a.gross_sales_mln,2) as gross_sales_mln,
round((gross_sales_mln/total_gross_price) *100,2) as market_share
from a
cross join b
on a.product_code=b.product_code 



-- Q10 Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
-- The final output contains these fields, division, product_code

with a as
(
select p.division,
s.product_code,p.product,
sum(s.sold_quantity) as total_sold_quantity
from fact_sales_monthly s
join dim_product p
on p.product_code=s.product_code
where fiscal_year=2021
group by p.product_code
order by total_sold_quantity desc
),
b as
(
 select product_code,RANK() OVER(PARTITION BY division 
ORDER BY total_sold_quantity DESC) AS 'Rank_Order' 
from a 
)
select a.division,
a.product_code,a.product,
 a.total_sold_quantity,b.Rank_Order
 from a 
join b 
on a.product_code=b.product_code
where rank_order in (1,2,3)