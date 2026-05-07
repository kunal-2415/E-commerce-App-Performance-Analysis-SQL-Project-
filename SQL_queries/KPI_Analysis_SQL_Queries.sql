-- Q1. Which KPIs would you use to measure the performance of our app? 
   /*KPI’s to Measure the Application Performance.*/

-- 1. Total Orders - Total orders in 2021 and 2022 

SELECT EXTRACT(YEAR FROM FK_ORDER_DATE) AS ORDER_YEAR,
	   SUM(ORDERED_QUANTITY) AS TOTAL_NUM_OF_ORDERS
FROM
	SALES_ORDERS_ITEMS
    WHERE EXTRACT(YEAR FROM FK_ORDER_DATE) = '2021'
    GROUP BY ORDER_YEAR
UNION
SELECT EXTRACT(YEAR FROM FK_ORDER_DATE) AS ORDER_YEAR,
	   SUM(ORDERED_QUANTITY) AS TOTAL_NUM_OF_ORDERS
FROM
	SALES_ORDERS_ITEMS
    WHERE EXTRACT(YEAR FROM FK_ORDER_DATE) = '2022'
    GROUP BY ORDER_YEAR;


-- 2. Total Revenue - Overall revenue of 2021 and 2022

SELECT 
   	EXTRACT(YEAR FROM O.ORDER_DATE) AS OD_YEAR, 
	SUM(I.ORDER_QUANTITY_ACCEPTED * I.RATE) AS REVENUE
FROM SALES_ORDERS O 
	LEFT JOIN SALES_ORDERS_ITEMS I
ON 
	O.ORDER_ID = I.FK_ORDER_ID
WHERE O.SALES_ORDER_STATUS = 'Shipped'
GROUP BY EXTRACT(YEAR FROM O.ORDER_DATE)
ORDER BY OD_YEAR;


-- 3. Total Users - Number of users

SELECT
	COUNT(DISTINCT USER_ID) AS TOTAL_USERS
FROM
	LOGIN_LOGS;


-- 4. Active Users - Number of Active users(Users who LoggedIn atleast once)

SELECT 
    EXTRACT(YEAR FROM LOGIN_DATE) AS YEAR,
    COUNT(DISTINCT USER_ID) AS ACTIVE_USERS
FROM LOGIN_LOGS
	GROUP BY EXTRACT(YEAR FROM LOGIN_DATE)
	ORDER BY YEAR;


-- 5. Logins - Users who log in to the application

SELECT 
	EXTRACT(YEAR FROM LOGIN_DATE) AS YEAR, COUNT(LOGIN_LOG_ID) AS LOGINS 
FROM LOGIN_LOGS 
	GROUP BY EXTRACT(YEAR FROM LOGIN_DATE)
	ORDER BY YEAR;


-- 6. Order Status - Status of orders(Shipped, rejected,review, pending)

SELECT 
	SALES_ORDER_STATUS, COUNT(ORDER_ID) AS OI_COUNT 
FROM SALES_ORDERS
	GROUP BY SALES_ORDER_STATUS;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Q2. Report regarding the company's growth between the 2 years            

--  Q2-A. Did our business grow??
/* To measure business growth, I will analyse the below key metrics */

-- 1. Total number of orders

SELECT SALES_ORDER_STATUS AS OD_STATUS, 
       COUNT(ORDER_ID) AS TOTAL_ORDERS
FROM SALES_ORDERS
	 GROUP BY SALES_ORDER_STATUS;
	 

-- 2. Number of Successfully Completed Orders 

SELECT COUNT(ORDER_ID) AS SUCCESSFULLY_COMPLETED_ORDERS,
	   SALES_ORDER_STATUS
FROM SALES_ORDERS
WHERE SALES_ORDER_STATUS = 'Shipped'
GROUP BY SALES_ORDER_STATUS;


-- 3. Total revenue generated between 2021 and 2022(revenue always calculated on shipped orders)

SELECT EXTRACT(YEAR FROM O.FK_ORDER_DATE) AS YEAR, 
       SUM(O.ORDER_QUANTITY_ACCEPTED * O.RATE) AS REVENUE
FROM SALES_ORDERS_ITEMS O 
       INNER JOIN SALES_ORDERS L 
       ON O.FK_ORDER_ID = L.ORDER_ID
WHERE EXTRACT(YEAR FROM O.FK_ORDER_DATE) IN (2021,2022) 
AND L.SALES_ORDER_STATUS = 'Shipped'
GROUP BY 1
ORDER BY YEAR;


-- Q2-B. Does our app perform better now?
/* To measure the application performance, I have select Order Success Rate and Conversion Rate as they reflect both operational efficiency and order improvement. */

-- 1. Order Success Rate(Shipped/Total Orders)

SELECT EXTRACT(YEAR FROM ORDER_DATE) AS YEAR, 
       COUNT(ORDER_ID) AS TOTAL_ORDERS, 
	   ROUND(COUNT(CASE WHEN SALES_ORDER_STATUS = 'Shipped' THEN 1 END)* 1.0/COUNT(ORDER_ID),2) AS ORDER_SUCCESS_RATE_
FROM SALES_ORDERS
	   GROUP BY EXTRACT(YEAR FROM ORDER_DATE)
	   ORDER BY YEAR;


-- 2. Conversion Rate -  Total users who order after the login.

WITH LOGINS AS(
SELECT EXTRACT(YEAR FROM LOGIN_DATE) AS YEAR_YY,
		   COUNT(DISTINCT USER_ID) AS LOGIN_USERS
FROM LOGIN_LOGS
	GROUP BY EXTRACT(YEAR FROM LOGIN_DATE)
),
ORDERS AS(
SELECT EXTRACT(YEAR FROM ORDER_DATE) AS YEAR_YY,
	   COUNT(DISTINCT FK_BUYER_ID) AS ORDERING_USERS
FROM SALES_ORDERS
	 GROUP BY EXTRACT(YEAR FROM ORDER_DATE)
)
SELECT
	L.YEAR_YY,
	L.LOGIN_USERS,
	O.ORDERING_USERS,
	CONCAT(ROUND((O.ORDERING_USERS * 1.0 / L.LOGIN_USERS),2) * 100,'%') AS CONVERSION_RATE
FROM LOGINS L
	 LEFT JOIN ORDERS O ON L.YEAR_YY = O.YEAR_YY;


-- Q2-C. Did our user base grow?
/*To measure the user base growth, I will analyze key metrics such as*/

-- 1. Number of active users.

SELECT 
    EXTRACT(YEAR FROM LOGIN_DATE) AS YEAR,
    COUNT(DISTINCT USER_ID) AS ACTIVE_USERS
FROM LOGIN_LOGS
	GROUP BY EXTRACT(YEAR FROM LOGIN_DATE)
	ORDER BY YEAR;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Q3. What are our top-selling products in each of the two years?

WITH TOP_SELLING_PRODUCTS AS(
SELECT EXTRACT(YEAR FROM S.FK_ORDER_DATE) AS YEAR, S.FK_PRODUCT_ID, SUM(S.ORDER_QUANTITY_ACCEPTED) AS PRODUCT_COUNT, 
ROW_NUMBER() OVER(PARTITION BY EXTRACT(YEAR FROM FK_ORDER_DATE) ORDER BY SUM(ORDER_QUANTITY_ACCEPTED) DESC) AS ROW_NUM
FROM SALES_ORDERS_ITEMS S
INNER JOIN SALES_ORDERS O
ON S.FK_ORDER_ID = O.ORDER_ID
WHERE SALES_ORDER_STATUS = 'Shipped' AND ORDER_QUANTITY_ACCEPTED > 0 
GROUP BY EXTRACT(YEAR FROM FK_ORDER_DATE), FK_PRODUCT_ID
)
SELECT * FROM TOP_SELLING_PRODUCTS
WHERE ROW_NUM = 1;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Q4. Looking at July 2021 data, what do you think is our biggest problem, and how would you recommend fixing it?
-- Key metrics
-- Order Status Distribution, Conversion rate, Success rate(shipped/total orders)

/*Answer - Looking at July 2021 data, the biggest problem is the high order rejection rate. Out of total orders, a significantly higher number of orders were 
           rejected (4140) compared to successfully shipped orders (2655). This indicates a major issue in order fulfillment, such as inventory shortages, 
		   supply chain inefficiencies, or operational delays. To address this, I would recommend improving inventory management, ensuring better stock availability,
		   and optimizing the order processing system. Reducing rejection rates would directly improve customer satisfaction, conversion rates, and overall business 
		   performance.*/

Note : I already write queries for Order Status Distribution, Conversion rate, and Success rate. Kindly check previous questions.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Q5. Does the login frequency affect the number of orders made?
-- Key Metric - Login frequency vs Orders relationship

WITH LOGINS AS(
SELECT USER_ID, COUNT(LOGIN_LOG_ID) AS TOTAL_LOGINS
FROM LOGIN_LOGS
GROUP BY USER_ID
),
ORDERS AS(
SELECT FK_BUYER_ID AS USER_ID, COUNT(ORDER_ID) AS TOTAL_ORDERS
FROM SALES_ORDERS
WHERE SALES_ORDER_STATUS = 'Shipped'
GROUP BY FK_BUYER_ID
)
SELECT L.USER_ID, L.TOTAL_LOGINS, COALESCE(O.TOTAL_ORDERS,0) AS TOTAL_ORDERS
FROM LOGINS L
LEFT JOIN ORDERS O
ON
L.USER_ID = O.USER_ID
ORDER BY L.TOTAL_LOGINS DESC;