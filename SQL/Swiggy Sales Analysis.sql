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

------------------------------------------------------------------------------------------------------------------------------------------
/* Restaurant Analysis                                                                                                                   |
Revenue leaders, AOV comparisons, rating performance */                                                                                  |                                                                                                                        
------------------------------------------------------------------------------------------------------------------------------------------

/* Q4 — Top 10 Restaurants by Revenue
Revenue, order count, AOV and avg rating per restaurant */

select top 10 r.restaurant_name,
       count(o.order_id)     as total_orders,
	   round(sum(price),2)          as Total_Revenue,
	   round(avg(price),2)   as avg_order_value,
	   round(avg(rating),2)           as avg_rating
from fact_orders o
join 
     dim_restaurants r
  on o.restaurant_id = r.restaurant_id
  group by r.restaurant_name
  order by Total_Revenue desc;

/* Output(Example) : (real output having 10 rows)
restaurant_name	                 total_orders	Total_Revenue	avg_order_value	   avg_rating
KFC	                              12961	         4246951.7	      327.67	        4.3
McDonald's	                      13530	         3343094.58       247.09	        4.4
Pizza Hut	                      6529	         2133265.69	      326.74	        4.2
Burger King	                      7116	         1900817.09	      267.12	        4.34
Domino's Pizza	                  5492           1834022.32	      333.94	        4.37
Olio - The Wood Fired Pizzeria	  3241	         1236369	      381.48	        4.29
*/


/* Q5 — High Rating, Low Volume
Restaurants with avg rating ≥ 4.5 but fewer than 500 orders — underutilised quality */

select r.restaurant_name,
       count(o.order_id)       as total_orders,
	   round(avg(o.price),2)   as avg_order_value,
	   round(avg(o.rating),2)  as avg_rating
from fact_orders o
join 
     dim_restaurants r
  on o.restaurant_id = r.restaurant_id
  group by r.restaurant_name
  having avg(o.rating) >= 4.5 and count(o.order_id) < 500
order by avg_rating desc;

/* Output(Example) : (real output having 101 rows)
restaurant_name	                         total_orders	    avg_order_value	     avg_rating
Sakana	                                 95	                484.32	             4.82
Vijay Dairy	                             52	                165.87	             4.75
Jagannath Mandir Arna Prasad	         8	                58.75	             4.75
I Deli Cafe	                             47	                148.68	             4.74
Radhey Lal's Parampara Sweets	         84	                225	                 4.74
Yadav Doodh Dairy	                     70              	449.16               4.73
*/

/* Q6 — Revenue vs Order Volume Quadrant Prep
Classifies each restaurant into 4 quadrants: Star / Volume Leader / Premium / Laggard */

WITH RestaurantStats AS (
    SELECT
        r.restaurant_name,
        COUNT(o.order_id)              AS total_orders,
        ROUND(SUM(o.price), 0)        AS total_revenue,
        ROUND(AVG(o.price), 2)        AS avg_order_value
    FROM fact_orders o
    JOIN dim_restaurants r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.restaurant_name
),
Medians AS (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_revenue)  OVER() AS med_revenue,   
		-- Median is preferred over average because the dataset
        -- contains extreme outliers that can skew mean values.
        -- Using median creates a more reliable benchmark for
        -- restaurant performance segmentation.
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_orders)  OVER() AS med_orders    
    FROM RestaurantStats                                                                   
)
SELECT
    rs.restaurant_name,
    rs.total_revenue,
    rs.total_orders,
    rs.avg_order_value,
    CASE
        WHEN rs.total_revenue >= m.med_revenue AND rs.total_orders >= m.med_orders THEN 'Star'
        WHEN rs.total_revenue <  m.med_revenue AND rs.total_orders >= m.med_orders THEN 'Volume Leader'
        WHEN rs.total_revenue >= m.med_revenue AND rs.total_orders <  m.med_orders THEN 'Premium'
        ELSE 'Laggard'
    END AS quadrant
FROM RestaurantStats rs
CROSS JOIN (
    SELECT DISTINCT med_revenue, med_orders FROM Medians    
	-- DISTINCT ensures only one median row is returned.
    -- CROSS JOIN attaches these benchmark values to each restaurant record.
) m
ORDER BY rs.total_revenue DESC;


/* OUTPUT(Example) : (real output has 984 rows of all restaurant data)
restaurant_name	              total_revenue	    total_orders	avg_order_value	   quadrant
KFC	                          4246952	         12961	         327.67	            Star
McDonald's	                  3343095	         13530	         247.09	            Star
Pizza Hut	                  2133266	         6529	         326.74	            Star
Burger King	                  1900817	         7116	         267.12	            Star
Domino's Pizza	              1834022	         5492	         333.94          	Star
Olio-The Wood Fired Pizzeria  1236369	         3241	         381.48	            Star
*/

------------------------------------------------------------------------------------------------------------------------------------------
/* Time & Trend Queries                                                                                                                  |
Monthly trends, weekday patterns, MoM growth */                                                                                          |                                                                                                                        
------------------------------------------------------------------------------------------------------------------------------------------

/* 
Q7 — Monthly Revenue & Orders Trend
Jan–Aug 2025 trend with MoM revenue growth %
*/

with Current_amount_data as
(
 select
    d.year                           as year,
	d.month                          as month,
	d.month_name                     as month_name,
	count(o.order_id)                as Total_orders,
	sum(o.price)                     as Total_Revenue,
	round(AVG(o.price),2)            as AOV
 from fact_orders o
 inner join dim_date d
 on o.date_id = d.date_id
 group by d.year,d.month,d.month_name  
), Previous_amount as 
(
 select * , 
     LAG(Total_Revenue) over (order by year,month) as pre_month_revenue
 from Current_amount_data
 )
select year,
       month,
	   month_name,
	   Total_orders,
	   AOV,Total_Revenue,
	   pre_month_revenue,
       round(100.0*(Total_Revenue-pre_month_revenue)/nullif((pre_month_revenue),0),2) as MoM_percentage
from Previous_amount

/*
Output:
year	month	month_name	Total_orders	AOV	     Total_Revenue	pre_month_revenue	MoM_percentage
2025	1	    Jan	        25398	        268.73	   6825186.03	NULL	            NULL
2025	2	    Feb	        23296	        269.11	   6269105.67	6825186.03	       -8.15
2025	3	    Mar	        24402	        269.38	   6573530.07	6269105.67	        4.86
2025	4	    Apr	        24588	        268.2	   6594515	    6573530.07	        0.32
2025	5	    May	        25190	        269.69	   6793558.4	6594515	            3.02
2025	6	    Jun	        24385	        267.14	   6514183.19	6793558.4	       -4.11
2025	7	    Jul	        24940	        266.68	   6650965.51	6514183.19	        2.1
2025	8	    Aug	        25231	        269.17	   6791461.9	6650965.51	        2.11
*/

/*
Q8 — Day of Week Performance
Which days drive the most orders and the highest AOV
*/

select 
     d.day_of_week,
	 d.is_weekend,
	 count(o.order_id)           as Total_orders,
	 round(sum(o.price),0)       as total_revenue,
	 round(avg(o.price),2)       as AOV
from fact_orders o
inner join dim_date d
on o.date_id =  d.date_id
group by d.day_of_week,d.is_weekend

/*
Output:
day_of_week	is_weekend	Total_orders	total_revenue	AOV
Friday	    0	        28288	         7579993	     267.96
Monday	    0	        27571	         7445437	     270.05
Thursday	0	        28457	         7664619	     269.34
Tuesday	    0	        27415	         7359414	     268.44
Wednesday	0	        28287	         7542103	     266.63
Saturday	1	        28938	         7782935	     268.95
Sunday	    1	        28474	         7638004	     268.24
*/

/*
Q9 — Weekend vs Weekday Full Comparison
Revenue, orders, AOV and revenue share split by weekday/weekend
*/

select 
     case when d.is_weekend = 1 then 'weekend' else 'weekday' end as day_type,
	 count(o.order_id)                                                     as Total_orders,
	 round(sum(o.price),0)                                                 as total_revenue,
	 round(avg(o.price),2)                                                 as AOV,
	 sum(count(o.order_id)) over ()                                        as Overall_orders,
	 round((count(o.order_id)*100.0)/sum(count(o.order_id)) over (),2)     as Percentage_of_orders
from fact_orders o
inner join dim_date d
on o.date_id =  d.date_id
group by case when d.is_weekend = 1 then 'weekend' else 'weekday' end

/* 
OUTPUT:
day_type	Total_orders	total_revenue	 AOV   	Overall_orders	Percentage_of_orders
weekday	     140018	         37591566	    268.48	     197430       	70.920000000000
weekend	     57412	         15420939	    268.6	     197430      	29.080000000000
*/










