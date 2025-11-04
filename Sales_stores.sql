select * from Sales_store
-- Copy data for data cleaning:
select * INTO sales from Sales_store

select * from sales

--- Data Cleaning---
--Step1. Check if there is any Duplicate in data:

WITH CTE AS(
select *,
	ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_id ) as Rn
from sales
)
select * from CTE
where transaction_id in ('TXN240646','TXN342128','TXN855235','TXN981773')

--Step2.. Delete Duplicate data

WITH CTE AS(
select *,
	ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_id ) as Rn
from sales
)
DELETE from CTE
where Rn = 2

-- Step3.. Correction of Header.

EXEC sp_rename 'sales.quantiy','quantity','COLUMN'
EXEC sp_rename 'sales.prce','price','COLUMN'

--Step 4: To check the datatypes.

select column_name, Data_type
from INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales'

-- Step 5: To check NUll VAlues:

-- to check null counts

DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL = STRING_AGG(
	'SELECT ''' + COLUMN_NAME + ''' AS COLUMNNAME,
	 COUNT(*) AS NULLCOUNT
	 FROM ' + QUOTENAME(TABLE_SCHEMA) + '.sales
	 WHERE ' + QUOTENAME(COLUMN_NAME) + 'IS NULL',
	 ' UNION ALL '
)
WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales';

-- EXECUTE THE DYNAMIC SQL

EXEC sp_executesql @SQL;

--Step 6: Treating the null values.

select *
from sales
where transaction_id is null
or
time_of_purchase is  null
or
status is null
or
purchase_date is null
or 
payment_mode is null
or
gender is null
or 
customer_name is null
or 
customer_id is null
or
customer_age is null

DELETE from sales
where transaction_id is null

select * 
from sales
where customer_name = 'Ehsaan Ram'

UPDATE sales
SET customer_id = 'CUST9494'
WHERE transaction_id = 'TXN977900'

select * 
from sales
where customer_name = 'Damini Raju'

UPDATE sales
SET customer_id = 'CUST1401'
WHERE transaction_id = 'TXN985663'


select * 
from sales
where customer_id = 'CUST1003'

UPDATE sales
SET customer_name = 'Mahika Saini'
WHERE transaction_id = 'TXN432798'

UPDATE sales
SET customer_age = 35
WHERE transaction_id = 'TXN432798'

UPDATE sales
SET gender = 'Male'
WHERE transaction_id = 'TXN432798'

select * from sales

--Step 7:- Data Cleaning:

select DISTINCT gender
from sales

UPDATE sales
SET gender = 'F'
where gender = 'Female'

UPDATE sales
SET gender = 'M'
where gender = 'Male'

-- Payment mode:
select DISTINCT payment_mode
from sales

UPDATE sales
SET payment_mode = 'Credit Card'
where payment_mode = 'CC'

-- Data Analysis:

-- What are the top 5 most selling product by quantity?

select top 5
	product_name,
	sum(quantity) Total_quantity_sold
from sales
where status = 'Delivered'
group by product_name
order by Total_quantity_sold desc

-- Business Problem:- We dont know which product are most in demand.
-- Business Impact :- Helps prioritize stock and boost sales through targeted promotions.

-------------------------------------------------------------------------------------------------------------------------
-- Ques2: Which Product are the most frequently canceled?

select top 5
	product_name,
	status,
	count(*) as total_cancelled
from sales
where status = 'cancelled'
group by product_name,status
order by total_cancelled desc

--Business Problem :- Frequent Cancellations affect revenue and customer trust.
--Business Impact :- identify poor-performing products to improve quality or remove from catalog.

---------------------------------------------------------------------------------------------------------------------------
--Ques3. What time of the day has the highest number of purchase?

select 
	count(*) as Total_orders,
CASE
	WHEN DATEPART(HOUR,time_of_purchase)  BETWEEN 0 AND 5 THEN 'NIGHT' 
	WHEN DATEPART(HOUR,time_of_purchase)  BETWEEN 6 AND 11 THEN 'MORNING'
	WHEN DATEPART(HOUR,time_of_purchase)  BETWEEN 12 AND 17 THEN 'AFTERNOON'
	WHEN DATEPART(HOUR,time_of_purchase)  BETWEEN 18 AND 23 THEN 'EVENING'
END TIME_OF_DAY
from sales
GROUP BY 
CASE
	WHEN DATEPART(HOUR,time_of_purchase)  BETWEEN 0 AND 5 THEN 'NIGHT' 
	WHEN DATEPART(HOUR,time_of_purchase)  BETWEEN 6 AND 11 THEN 'MORNING'
	WHEN DATEPART(HOUR,time_of_purchase)  BETWEEN 12 AND 17 THEN 'AFTERNOON'
	WHEN DATEPART(HOUR,time_of_purchase)  BETWEEN 18 AND 23 THEN 'EVENING'
END 
ORDER BY Total_orders DESC

--Business Problem solved :- find the peak sales time 
--Business Impact :- Optimize staffing,promotions,server loads.

--------------------------------------------------------------------------------------------------------------------------
--Ques4. Who are top 5 highest spending customers?

select TOP 5
	customer_name,
	FORMAT(sum(price*quantity),'C0','en-IN') as Total_spendings
from sales
group by customer_name
order by sum(price*quantity) desc

--Business Problem solved :- Identify VIP customers.
--Business Impact :- Personalized offers, Royalty Rewards and retentions

--------------------------------------------------------------------------------------------------------------------
--Ques5. Whcih product category generate the highest revenue?

select
	product_category,
	FORMAT(Sum(price*quantity),'C0','en-IN') as Total_revenue
from sales
group by product_category
order by Sum(price*quantity) desc

--Business Problem:- Identify Top performing product Categories.
--Business Impact:- Refine product strategy, supply chain, promotions.
--allowing the business to invest more in high-margin or high-demand categories.

---------------------------------------------------------------------------------------------------------------------------
--Ques6. What are the Return/cancellation rate per product category?
--Cancelation Rate:
select 
	product_category,
	FORMAT(COUNT(CASE WHEN STATUS = 'cancelled' THEN 1 END)*100.0/COUNT(*),'N2') +' %' AS Cancellation_rate
from sales
group by product_category
order by Cancellation_rate desc

--Return Rate:
select 
	product_category,
	FORMAT(COUNT(CASE WHEN STATUS = 'Returned' THEN 1 END)*100.0/COUNT(*),'N2')+' %' AS Return_rate
from sales
group by product_category
order by Return_rate desc

--Business Problems solved :- Monitor Dissatisfication trends per categories.
--Business Impact :- Reduce Return , improve products descriptions/expectations
--Helps identify and fix product and logistics issues.

---------------------------------------------------------------------------------------------------------------------------
--Ques 7. What is the most preffred payment mode?
select 
	payment_mode,
	count(*) as Total_num_mode_of_pay
from sales
group by payment_mode
order by Total_num_mode_of_pay desc

--Business Problem solved :- know which payment option customer prefer.
--Business Impact :- Streamline payment processing, prioritize popular mode.

--------------------------------------------------------------------------------------------------------------------------------

--Ques 8. How does the age group purchasing behaviour?

select 
	CASE
		WHEN customer_age between 18 AND 25 THEN '18-25'
		WHEN customer_age between 26 AND 33  THEN '26-35'
		WHEN customer_age between 36 AND 50  THEN '36-50'
		ELSE '50+'
	END AS Age,
FORMAT(SUM(Price*quantity),'C0','en-IN') as Total_amount
from sales
group by 
CASE
		WHEN customer_age between 18 AND 25 THEN '18-25'
		WHEN customer_age between 26 AND 33  THEN '26-35'
		WHEN customer_age between 36 AND 50  THEN '36-50'
		ELSE '50+'
	END
order by SUM(Price*quantity) desc

--Business Problem solved:- Understand customers Demographics.
--BUsiness Impact:- Target marketing and product recommendation by age group.

--------------------------------------------------------------------------------------------------------------------------------
--Ques 9. What is the Monthly sales Trend?

select 
	DATEPART(MONTH,purchase_date) as MNTH,
	FORMAT(SUM(price*quantity),'C0','en-IN') as Total_sales
from sales
group by DATEPART(MONTH,purchase_date)
order by SUM(price*quantity) desc

--BUsiness Problem :- Sales fluctutions go unnoticed.
--Business Impact :- Plan inventory and marketing to seasonal trends.

--------------------------------------------------------------------------------------------------------------------------------
--Ques 10. Are certain gender buying more specifics categories?
--Method 1:
select 
	gender,
	product_category,
	count(*) as Total_Pruchase
from sales
group by gender,product_category
order by gender desc

--Method 2:

select *
from(
select 
	gender,
	product_category
from sales) as source_Table
PIVOT(
	COUNT(gender)
	FOR gender IN ([M],[F])
	) as Pivot_table
order by product_category

--BUsiness Problem solved:- Gender-based products prefrences.
--Business Impact :- Personlized ads and gender-focused campaigns.








select * from sales