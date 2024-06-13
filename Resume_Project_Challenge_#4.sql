USE GDB023;

#-----------------------------------------------------SOLUTION NUMBER 01-----------------------------------------------------------#

# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT DISTINCT(MARKET) FROM  DIM_CUSTOMER
WHERE CUSTOMER = "Atliq Exclusive" AND REGION = "APAC"
ORDER BY MARKET;


#-----------------------------------------------------SOLUTION NUMBER 02-----------------------------------------------------------#

/*		2.What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
		unique_products_2020
		unique_products_2021
		percentage_chg																												*/

WITH UNIQUE_PRODUCTS_2021 AS 
(SELECT COUNT(DISTINCT(PRODUCT_CODE)) AS X FROM FACT_SALES_MONTHLY WHERE FISCAL_YEAR = 2021),
	 UNIQUE_PRODUCTS_2020 AS
(SELECT COUNT(DISTINCT(PRODUCT_CODE)) AS Y FROM FACT_SALES_MONTHLY WHERE FISCAL_YEAR = 2020)

SELECT X AS UNIQUE_PRODUCTS_2021, Y AS UNIQUE_PRODUCTS_2020, 
ROUND((X - Y)/Y *100,2) AS PERCENTAGE_CHG 
FROM UNIQUE_PRODUCTS_2021, UNIQUE_PRODUCTS_2020;


#-----------------------------------------------------SOLUTION NUMBER 03-----------------------------------------------------------#

/*		3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
        The final output contains 2 fields,
		segment
		product_count																												*/

SELECT SEGMENT, COUNT(DISTINCT(PRODUCT_CODE)) AS PRODUCT_COUNT 
FROM DIM_PRODUCT
GROUP BY SEGMENT ORDER BY PRODUCT_COUNT DESC;


#-----------------------------------------------------SOLUTION NUMBER 04-----------------------------------------------------------#

/*		4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
		segment
		product_count_2020
		product_count_2021
		difference 																													*/

WITH X AS
(SELECT COUNT(DISTINCT(S.PRODUCT_CODE)) AS PRODUCT_COUNT_2021,SEGMENT,FISCAL_YEAR FROM FACT_SALES_MONTHLY S 
JOIN DIM_PRODUCT P ON S.PRODUCT_CODE=P.PRODUCT_CODE
WHERE FISCAL_YEAR = 2021 GROUP BY SEGMENT ORDER BY SEGMENT),
     Y AS
(SELECT COUNT(DISTINCT(S.PRODUCT_CODE)) AS PRODUCT_COUNT_2020,SEGMENT,FISCAL_YEAR FROM FACT_SALES_MONTHLY S 
JOIN DIM_PRODUCT P ON S.PRODUCT_CODE=P.PRODUCT_CODE
WHERE FISCAL_YEAR = 2020 GROUP BY SEGMENT ORDER BY SEGMENT)

SELECT X.SEGMENT, Y.PRODUCT_COUNT_2020, X.PRODUCT_COUNT_2021 , X.PRODUCT_COUNT_2021 - Y.PRODUCT_COUNT_2020 AS DIFFERENCE 
FROM X JOIN Y ON X.SEGMENT=Y.SEGMENT ;


#-----------------------------------------------------SOLUTION NUMBER 05-----------------------------------------------------------#

/* 		5. Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
		product_code
		product
		manufacturing_cost																											*/

WITH PRODUCT_MANUFACTURING_COST AS
(SELECT P.PRODUCT_CODE,P.PRODUCT, M.MANUFACTURING_COST , RANK() OVER(ORDER BY MANUFACTURING_COST DESC) AS RNK
FROM DIM_PRODUCT P JOIN FACT_MANUFACTURING_COST M ON P.PRODUCT_CODE = M.PRODUCT_CODE
ORDER BY MANUFACTURING_COST DESC ),
	 MX AS  (SELECT MAX(RNK) AS MAXRNK FROM PRODUCT_MANUFACTURING_COST)

SELECT PRODUCT_MANUFACTURING_COST.* FROM PRODUCT_MANUFACTURING_COST, MX
WHERE PRODUCT_MANUFACTURING_COST.RNK IN ( MX.MAXRNK ,  1)
ORDER BY RNK;


#-----------------------------------------------------SOLUTION NUMBER 06-----------------------------------------------------------#

/* 		6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
		for the fiscal year 2021 and in the Indian market. The final output contains these fields,
		customer_code
		customer
		average_discount_percentage 																								*/
        
SELECT D.CUSTOMER_CODE,CUSTOMER, 
	   ROUND(AVG(PRE_INVOICE_DISCOUNT_PCT*100),2) AS AVERAGE_DISCOUNT_PERCENTAGE
FROM FACT_PRE_INVOICE_DEDUCTIONS D 
JOIN DIM_CUSTOMER C ON D.CUSTOMER_CODE = C.CUSTOMER_CODE
WHERE FISCAL_YEAR = 2021 AND MARKET = "INDIA" 
GROUP BY D.CUSTOMER_CODE, C.CUSTOMER 
ORDER BY AVERAGE_DISCOUNT_PERCENTAGE DESC
LIMIT 5 ;

        
#-----------------------------------------------------SOLUTION NUMBER 07-----------------------------------------------------------#

/* 		7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.
		This analysis helps to get an idea of low and high-performing months and take strategic decisions.
		The final report contains these columns:
		Month
		Year
		Gross sales Amount 																											*/
# HINT : Gross sales Amount = gross_price * sold_quantity

SELECT MONTHNAME(DATE) AS "MONTH" ,YEAR(DATE) AS "YEAR",
		ROUND(SUM(GROSS_PRICE*SOLD_QUANTITY),2) AS GROSS_SALES_AMOUNT
FROM FACT_GROSS_PRICE G JOIN FACT_SALES_MONTHLY S 
ON G.PRODUCT_CODE = S.PRODUCT_CODE AND G.FISCAL_YEAR = S.FISCAL_YEAR
JOIN DIM_CUSTOMER C ON C.CUSTOMER_CODE = S.CUSTOMER_CODE
WHERE C.CUSTOMER = "ATLIQ EXCLUSIVE"
GROUP BY MONTH, YEAR  
ORDER BY YEAR;


#-----------------------------------------------------SOLUTION NUMBER 08-----------------------------------------------------------#

/*		8. In which quarter of 2020, got the maximum total_sold_quantity? 
		The final output contains these fields sorted by the total_sold_quantity,
		Quarter
		total_sold_quantity                    																						*/
# FISCAL QUARTER DERIVED IN SOLUTION WHERE FISCAL YEAR STARTS FROM SEPTEMBER
        
SELECT CONCAT("Q",QUARTER(DATE_ADD(DATE, INTERVAL 4 MONTH))) AS "QUARTER", 
		SUM(SOLD_QUANTITY) AS TOTAL_SOLD_QUANTITY 
FROM FACT_SALES_MONTHLY WHERE FISCAL_YEAR = 2020 
GROUP BY QUARTER 
ORDER BY TOTAL_SOLD_QUANTITY DESC;
        
        
#-----------------------------------------------------SOLUTION NUMBER 09-----------------------------------------------------------#
/*		9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
		The final output contains these fields,
		channel
		gross_sales_mln
		percentage    																												*/

WITH SALES_BY_CHANNEL AS 
(SELECT CHANNEL,ROUND(SUM(GROSS_PRICE*SOLD_QUANTITY)/1000000,2) AS GROSS_SALES_MLN
FROM FACT_SALES_MONTHLY S 
JOIN DIM_CUSTOMER C ON S.CUSTOMER_CODE = C.CUSTOMER_CODE 
JOIN FACT_GROSS_PRICE G ON S.PRODUCT_CODE = G.PRODUCT_CODE AND S.FISCAL_YEAR = G.FISCAL_YEAR
WHERE S.FISCAL_YEAR = 2021
GROUP BY CHANNEL)

SELECT *, ROUND(GROSS_SALES_MLN/(SUM(GROSS_SALES_MLN) OVER())*100,2) AS PERCENTAGE 
FROM SALES_BY_CHANNEL
ORDER BY PERCENTAGE DESC;


#-----------------------------------------------------SOLUTION NUMBER 10-----------------------------------------------------------#
/*		10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
The final output contains these fields,
division
product_code
product
total_sold_quantity
rank_order																															*/

WITH PRODUCT_SOLD AS
(SELECT DIVISION, P.PRODUCT_CODE, PRODUCT, SUM(SOLD_QUANTITY) AS TOTAL_SOLD_QUANTITY,
 RANK() OVER( PARTITION BY DIVISION ORDER BY SUM(SOLD_QUANTITY) DESC ) AS RANK_ORDER
 FROM FACT_SALES_MONTHLY S 
 JOIN DIM_PRODUCT P ON S.PRODUCT_CODE = P.PRODUCT_CODE 
 WHERE FISCAL_YEAR = 2021
 GROUP BY P.PRODUCT, DIVISION, P.PRODUCT_CODE ORDER BY TOTAL_SOLD_QUANTITY DESC)
 
 SELECT * FROM PRODUCT_SOLD WHERE RANK_ORDER < 4 ;
 
 
 #------------------------------------------------------------END------------------------------------------------------------------#