/* We have 5 Cleaned table in which one fact table and four dimension table named as :
fact_table  - fact_orders
dim table   - dim_restaurants
dim_table   - dim_dish
dim_table   - dim_locations
dim_table   - dim_date
*/

------------------------------------------------------------------------------------------------------------------------------------------
--> Basic Business Queries                                                                                                                |
--> KPIs, order volumes, price stats — essential executive metrics                                                                        |
------------------------------------------------------------------------------------------------------------------------------------------
/* Q1 — Business KPI Summary */
/* Total orders, total revenue, AOV, avg rating, min, max price — the headline numbers */

select  
    count(*)    as Total_orders,
	round(sum(price),0)  as Total_revenue,
	round(AVG(price),2)  as Average_order_value,
	round(AVG(rating),2) as Average_rating,
	min(price)  as min_order_price,
	max(price)  as max_order_price
from fact_orders

/*
OUTPUT:
Total_orders	Total_revenue	Average_order_value	  Average_rating	min_order_price 	max_order_price
197430	         53012506	    268.51	              4.34          	0.95	            8000
*/ 

/* Q2 — Price Distribution Bands */
/* Bucket orders into price segments to understand customer spend behaviour */

select 
    case 
        when price < 100 then 'Under 100'
        when price >= 100 and price < 250 then '100-249'
        when price >= 250 and price < 500 then '250-499'
        when price >= 500 and price < 1000 then '500-999'
        else '1000+' 
    end as Price_band,
    count(*) as order_counts,
    cast(sum(price) as decimal(10,2)) as Band_revenue,
    cast(100.0*(count(*))/(sum(count(*)) over()) as decimal(10,2)) as pct_orders
from fact_orders
group by 
    case 
        when price < 100 then 'Under 100'
        when price >= 100 and price < 250 then '100-249'
        when price >= 250 and price < 500 then '250-499'
        when price >= 500 and price < 1000 then '500-999'
        else '1000+'
	end
order by Band_revenue desc;

/* OUTPUT :
Price_band	order_counts	Band_revenue	pct_orders
250-499	    70733	        23901885.54	    35.83
100-249	    84194	        14813662.53	    42.64
500-999	    13387	        8924220.13	    6.78
1000+	    2313	        3570585.39	    1.17
Under 100	26803	        1802152.18	    13.58
*/

/*  Q3 — Rating Distribution
How orders spread across rating bands (1.5 to 5.0) */

select 
     floor(rating*2)/2 as rating_band,
	 count(*) as order_counts,
	 cast(avg(price) as decimal(10,2)) as avg_price_at_ratings,
	 cast(100.0*(count(*))/(sum(count(*)) over ()) as decimal(10,2)) as order_pct
from fact_orders
group by floor(rating*2)/2 
order by rating_band desc;

/*
OUTPUT:
rating_band	order_counts	avg_price_at_ratings	order_pct
5	        9403	        296.67	                4.76
4.5	        44403	        248.88	                22.49
4	        120536	        276.95	                61.05
3.5	        14594	        247.89	                7.39
3	        5056	        252.77	                2.56
2.5	        2136	        253.71	                1.08
2	        1078	        267.75	                0.55
1.5	         224	        282.78	                0.11
*/
