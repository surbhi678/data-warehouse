/*Q1 - Determine the top 3 countries in terms of total sales*/
SELECT * 
FROM
    (SELECT country_iso_code, country_name, SUM(amount_sold) SALES$
    FROM SH.customers a, SH.countries b, SH.sales c 
    WHERE a.country_id = b.country_id
    AND a.cust_id = c.cust_id
    GROUP BY country_iso_code, country_name
    ORDER BY SUM(amount_sold) DESC)
WHERE ROWNUM <=3;/*to display the top 3 countries only*/

/*Q2 - Determine which product was the highest sold, in terms of numbers, in the US in each year*/
SELECT calendar_year, prod_name, TOTAL_QUANTITY 
FROM
    (SELECT calendar_year, prod_name, SUM(quantity_sold) TOTAL_QUANTITY,
    RANK()OVER (PARTITION BY calendar_year ORDER BY SUM(quantity_sold)DESC) AS rank
    FROM SH.times t,SH.products p,SH.sales s,SH.countries a,SH.customers b
    WHERE t.time_id= s.time_id 
    AND p.prod_id = s.prod_id 
    AND b.cust_id = s.cust_id
    AND country_iso_code = 'US'
    GROUP BY Calendar_year, prod_name, country_iso_code
    ORDER BY calendar_year, SUM(quantity_sold) DESC)
WHERE rank =1;


/*Q3 How many sales transactions were there for the product that generated maximum sales revenue in 2001?
Also identify the: a) product quantity sold and b) channel id and description*/

SELECT prod_id, channel_id, channel_desc, num_trans, total_quantity
FROM
    (SELECT s.prod_id, s.channel_id, c.channel_desc, COUNT(s.amount_sold) AS NUM_TRANS, 
    SUM(amount_sold), SUM(quantity_sold) AS TOTAL_QUANTITY
    FROM SH.sales s, SH.channels c
    WHERE time_id> '31/12/00' and time_id <= '31/12/01' 
    AND s.channel_id = c.channel_id
    GROUP BY ROLLUP(s.prod_id, s.channel_id,c.channel_desc)
    ORDER BY SUM(amount_sold) DESC)
WHERE prod_id IS NOT NULL AND channel_id IS NULL
AND ROWNUM = 1; /*product 18 generated the maximun revenue in 2001 and the sales transaction were 2358*/

/*Q4 - Which 3 countries had the poorest performance in terms of sales in 1998?*/
SELECT * 
FROM
    (SELECT country_iso_code, country_name, SUM(amount_sold) AS SALES$
    FROM SH.customers a, SH.countries b, SH.sales c 
    WHERE a.country_id = b.country_id 
    AND a.cust_id = c.cust_id 
    AND time_id <= '31/12/98' AND time_id > '31/12/97'
    GROUP BY country_iso_code, country_name
    ORDER BY SUM(amount_sold))
WHERE ROWNUM <=3;

/*Q5 - Create an aggregated materialised view named ¡°Promotion_Analysis_mv¡± that presents the product-wise sales analysis for each promotion.*/

DROP MATERIALIZED VIEW Promotion_Analysis_mv;

CREATE MATERIALIZED VIEW Promotion_Analysis_mv 
(promo_id, prod_id, TOTAL_SALES)
AS
SELECT s.promo_id, s.prod_id, SUM(amount_sold) AS TOTAL_SALES
FROM SH.sales s, SH.promotions p
WHERE s.promo_id = p.promo_id
GROUP BY s.promo_id, s.prod_id
ORDER BY s.prod_id;

SELECT * FROM Promotion_Analysis_mv;

/*Q6 - Use the materialised view created in Q5, and using ROLLUP or CUBE concepts. 
provide some useful information of your choice for management using this materialised view. 
Note: Do not create the materialised view again, just use the one you created in Q6.*/


/*It¡®s easier to check the product name and promotion name from the products 
and promotion tables respectively rather than adding products in the aggregated views*/
SELECT promo_id, prod_id, SUM(total_sales) AS SALES$
FROM Promotion_Analysis_mv 
GROUP BY CUBE(promo_id, prod_id)
ORDER BY SUM(total_sales) DESC;

/*showing total sales of each promotions with rank*/

SELECT promo_id, prod_id, SUM(total_sales) AS SALES$,
RANK()OVER(ORDER BY SUM(total_sales) DESC) AS RANK
FROM Promotion_Analysis_mv 
GROUP BY ROLLUP(promo_id, prod_id)
HAVING promo_id IS NOT NULL and prod_id IS NULL;


/*showing which products have made the most and least sales*/
SELECT * 
FROM
    (SELECT promo_id, prod_id, SUM(total_sales) AS SALES$
    FROM Promotion_Analysis_mv
    GROUP BY CUBE(promo_id, prod_id)
    HAVING promo_id IS NULL AND prod_id IS NOT NULL
    ORDER BY SUM(total_sales) DESC)
WHERE ROWNUM = 1
UNION ALL
SELECT * 
FROM
    (SELECT promo_id, prod_id, SUM(total_sales) AS SALES$
    FROM Promotion_Analysis_mv
    GROUP BY CUBE(promo_id, prod_id)
    HAVING promo_id IS NULL AND prod_id IS NOT NULL
    ORDER BY SUM(total_sales))
WHERE ROWNUM = 1;

/*showing maximum sales and least sales for one product with its promotion code*/
SELECT * 
FROM
    (SELECT promo_id, prod_id, SUM(total_sales) AS SALES$
    FROM Promotion_Analysis_mv
    GROUP BY CUBE(promo_id, prod_id)
    HAVING promo_id IS NOT NULL AND prod_id IS NOT NULL
    ORDER BY SUM(total_sales))
WHERE ROWNUM = 1
UNION ALL
SELECT * FROM
    (SELECT promo_id, prod_id, SUM(total_sales) AS SALES$
    FROM Promotion_Analysis_mv
    GROUP BY CUBE(promo_id, prod_id)
    HAVING promo_id IS NOT NULL AND PROD_ID IS NOT NULL
    ORDER BY SUM(total_sales) DESC)
WHERE ROWNUM = 1;

SELECT * 
FROM SH.promotions 
WHERE promo_id IN (33, 999) /*to see the promotion names*/

SELECT * 
FROM SH.products 
WHERE prod_id IN (16,18) /*to see the product names*/


/*Q7 - There exists an aggregated table called sh.fweek_pscat_sales_mv in the SH schema. 
Use this table and other table(s) to provide some useful information of your choice for management.*/

SELECT * FROM sh.fweek_pscat_sales_mv;

/*Using the sh.fweek_pscat_sales_mv table along with the channels table to review 
the total sales from different channels*/

SELECT *
FROM 
    (SELECT m.prod_subcategory, m.channel_id, c.channel_desc, SUM(dollars) AS Channel_SALES
    FROM sh.fweek_pscat_sales_mv m, sh.channels c
    WHERE m.channel_id = c.channel_id
    GROUP BY CUBE (m.channel_id, m.prod_subcategory, c.channel_desc)
    HAVING channel_desc IS NOT NULL AND prod_subcategory IS NULL
    ORDER BY Channel_SALES DESC)
WHERE channel_id IS NOT NULL;

/*Using the sh.fweek_pscat_sales_mv table along with the channels table to review 
the total sales from different subcategories*/

SELECT *
FROM 
    (SELECT m.prod_subcategory, m.channel_id, c.channel_desc, SUM(dollars) AS CATE_SALES
    FROM sh.fweek_pscat_sales_mv m, sh.channels c
    WHERE m.channel_id = c.channel_id
    GROUP BY CUBE (m.channel_id, m.prod_subcategory, c.channel_desc)
    HAVING channel_desc IS NULL AND prod_subcategory IS NOT NULL
    ORDER BY CATE_SALES DESC)
WHERE channel_id IS NULL AND ROWNUM <=3
UNION ALL
SELECT *
FROM 
    (SELECT m.prod_subcategory, m.channel_id, c.channel_desc, SUM(dollars) AS CATE_SALES
    FROM sh.fweek_pscat_sales_mv m, sh.channels c
    WHERE m.channel_id = c.channel_id
    GROUP BY CUBE (m.channel_id, m.prod_subcategory, c.channel_desc)
    HAVING channel_desc IS NULL AND prod_subcategory IS NOT NULL
    ORDER BY CATE_SALES)
WHERE channel_id IS NULL AND ROWNUM =1;

/*Using the sh.fweek_pscat_sales_mv table along with the channels table to review 
the top 2 total sales of particular categories through top 2 channels 
and the least sales and its channel*/

SELECT * 
FROM 
    (SELECT m.prod_subcategory, m.channel_id, c.channel_desc, SUM(dollars) AS TOTAL_SALES
    FROM sh.fweek_pscat_sales_mv m, sh.channels c
    WHERE m.channel_id = c.channel_id AND channel_desc = 'Direct Sales'
    GROUP BY CUBE (m.channel_id, m.prod_subcategory, c.channel_desc)
    HAVING channel_desc IS NOT NULL AND prod_subcategory IS NOT NULL
    ORDER BY TOTAL_SALES DESC)
WHERE channel_id IS NOT NULL AND ROWNUM <= 2
UNION ALL
SELECT * 
FROM 
    (SELECT m.prod_subcategory, m.channel_id, c.channel_desc, SUM(dollars) AS TOTAL_SALES
    FROM sh.fweek_pscat_sales_mv m, sh.channels c
    WHERE m.channel_id = c.channel_id AND channel_desc = 'Partners'
    GROUP BY CUBE (m.channel_id, m.prod_subcategory, c.channel_desc)
    HAVING channel_desc IS NOT NULL AND prod_subcategory IS NOT NULL
    ORDER BY TOTAL_SALES DESC)
WHERE channel_id IS NOT NULL AND ROWNUM <= 2
UNION ALL
SELECT *
FROM 
    (SELECT m.prod_subcategory, m.channel_id, c.channel_desc, SUM(dollars) AS TOTAL_SALES
    FROM sh.fweek_pscat_sales_mv m, sh.channels c
    WHERE m.channel_id = c.channel_id 
    GROUP BY CUBE (m.channel_id, m.prod_subcategory, c.channel_desc)
    HAVING channel_desc IS NOT NULL AND prod_subcategory IS NOT NULL
    ORDER BY TOTAL_SALES)
WHERE channel_id IS NOT NULL AND ROWNUM =1;

/*we can also review total channely sales by week in a year*/
SELECT DISTINCT week_ending_day, channel_id,Channel_desc,weekly_sales
FROM
    (SELECT m.week_ending_day, c.channel_id, c.channel_desc, 
    SUM(dollars)
    OVER(PARTITION BY c.channel_id ORDER BY m.week_ending_day RANGE UNBOUNDED PRECEDING)as WEEKLY_SALES
    FROM sh.fweek_pscat_sales_mv m, sh.channels c
    WHERE m.channel_id = c.channel_id 
    GROUP BY m.WEEK_ENDING_DAY, c.channel_id, c.channel_desc, dollars)
WHERE channel_id = 3 AND week_ending_day >= '01/01/98' AND week_ending_day <= '31/12/98' 
ORDER BY week_ending_day;

