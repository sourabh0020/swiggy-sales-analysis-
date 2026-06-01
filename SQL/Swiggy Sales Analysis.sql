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

------------------------------------------------------------------------------------------------------------------------------------------
/*Geography Queries                                                                                                                      |    
City, state, and locality-level performance across 28 cities and 28 states */                                                            |                                                                                                                        
------------------------------------------------------------------------------------------------------------------------------------------

/* 
Q10 — State-Level Revenue Ranking
Roll up from city to state — includes revenue rank across all 28 states
*/

select 
     l.state                          as state,
	 count(*)                         as total_orders,
	 round(sum(o.price),0)                     as total_revenue,
	 round(AVG(o.price),2)                     as AOV_State_wise,
	 Row_number() over (order by round(sum(o.price),0) desc) as Revenue_rnk
from fact_orders o 
inner join 
dim_locations l
on o.location_id =l.location_id
group by l.state

/*
OUTPUT :(sample of 10 state real out have 28 state data) 
state	         total_orders	      total_revenue	    AOV_State_wise   	Revenue_rnk
Karnataka       	20077	            5456798	         271.79	                1
Uttar Pradesh	    10192	            3117360	         305.86	                2
Telangana	        10309	            3021712	         293.11	                3
Maharashtra	        10507	            3015573	         287.01	                4
Delhi	            10191	            2829181	         277.62	                5
Gujarat          	10185	            2817836	         276.67	                6
Punjab	            10065	            2809441	         279.13             	7
West Bengal	        10046	            2662802	         265.06	                8
Tamil Nadu	        10042	            2642595	         263.15	                9
Rajasthan	        10286	            2502933	         243.33	                10
*/

/*
Q11 — Top 10 Cities by Revenue + AOV
Revenue leaders vs AOV leaders — often different cities
*/
SELECT TOP 10
    l.city,
    l.state,
    COUNT(o.order_id)          AS total_orders,
    ROUND(SUM(o.price), 0)    AS total_revenue,
    ROUND(AVG(o.price), 2)    AS avg_order_value,
    ROUND(AVG(o.rating), 2)   AS avg_rating
FROM fact_orders o
JOIN dim_locations l ON o.location_id = l.location_id
GROUP BY l.city, l.state
ORDER BY total_revenue DESC;

/*
OUTPUT:
city	        state	     total_orders	total_revenue	avg_order_value	  avg_rating
Bengaluru	    Karnataka	    20077	      5456798	      271.79	       4.31
Lucknow      	Uttar Pradesh	10192	      3117360	      305.86	       4.37
Hyderabad	    Telangana	    10309	      3021712	      293.11	       4.27
Mumbai       	Maharashtra   	10507	      3015573	      287.01       	   4.34
New Delhi     	Delhi	        10191	      2829181	      277.62	       4.34
Ahmedabad	    Gujarat	        10185	      2817836	      276.67	       4.39
Chandigarh	    Punjab	        10065	      2809441	      279.13	       4.34
Kolkata	        West Bengal	    10046	      2662802	      265.06	       4.41
Chennai	        Tamil Nadu	    10042	      2642595	      263.15	       4.37
Jaipur	        Rajasthan	    10286	      2502933	      243.33	       4.34
*/

/*
Q12 — Top Restaurant per City (Window Function)
Finds the #1 revenue restaurant in every city — a recruiter favourite
*/

WITH CityRestaurantRevenue AS (
    SELECT
        l.city,
        r.restaurant_name,
        ROUND(SUM(o.price), 0)  AS total_revenue,
        COUNT(o.order_id)        AS total_orders,
        RANK() OVER (
            PARTITION BY l.city
            ORDER BY SUM(o.price) DESC
        )                        AS city_rank
    FROM fact_orders o
    JOIN dim_locations l    ON o.location_id   = l.location_id
    JOIN dim_restaurants r  ON o.restaurant_id = r.restaurant_id
    GROUP BY l.city, r.restaurant_name
)
SELECT city, restaurant_name, total_revenue, total_orders
FROM   CityRestaurantRevenue
WHERE  city_rank = 1
ORDER BY total_revenue DESC;

/*
OUTPUT: (sample of 10 city wise restaurant, real out have 28 state data)
city	      restaurant_name	    total_revenue	  total_orders
Bengaluru	   McDonald's	         516114          	2032
Ahmedabad	    KFC	                 451872	            1277
Chandigarh	    KFC	                 374991	            1066
Mumbai	        McDonald's	         352902	            1426
Chennai	        McDonald's	         323675	            1227
Kolkata	        KFC	                 292348	            971
Lucknow	        KFC	                 280658	            932
Indore	        McDonald's	         280008	            1101
Hyderabad	    Labonel Fine Baking	 272780	            154
New Delhi	    McDonald's	         262082	            1205
*/

------------------------------------------------------------------------------------------------------------------------------------------
/*Dish & Category Queries                                                                                                                |
Menu performance, category revenue, top dishes — 82,891 unique dishes */                                                                 |                                                                                                                        
------------------------------------------------------------------------------------------------------------------------------------------

/* Q13 — Revenue by Food Category
Which categories (Biryani, Pizza, Combos, etc.) drive the most revenue */

select d.category,
      count(o.order_id)                                     as total_orders,
	  ROUND(sum(o.price),0)                                 as total_revenue,
	  ROUND(avg(o.price),2)                                 as AOV,
	  ROUND(avg(o.rating),2)                                as avg_rating,
	  round(sum(o.price)*100.0/sum(sum(o.price)) over (),2) as prt_of_total
from fact_orders o
left join dim_dish d
on o.food_id = d.dish_id
group by d.category
order by total_revenue desc

/*
OUTPUT :(sample output real output have 4690 rows )
category                              	total_orders	total_revenue	AOV	   avg_rating	prt_of_total
Recommended	                             24100	         7188937	    298.3	4.32	      13.56
Main Course	                             2983	         767175	        257.18	4.31	       1.45
BURGERS	                                 2539	         695149      	273.79	4.32	       1.31
Burger Combos 3 Pc Meals 	             1331	         507774	        381.5	4.38	       0.96
Desserts	                             3583	         500728	        139.75	4.37	       0.94
Sweets	                                 1954	         475068	        243.13	4.46	       0.9
McSaver Combos 2 Pc Meals	             1885	         431697	        229.02	4.41	       0.81
ROLLS	                                 1652	         410716	        248.62	4.25	       0.77
Starters	                             1692	         407731     	240.98	4.3	           0.77
Korean Spicy FestLimited Time Only	     1180	         405191	        343.38	4.36	       0.76
*/

/* Q14 — Top 10 Dishes by Revenue
Individual dish performance with revenue share */

SELECT TOP 10
    dd.dish_name,
    dd.category,
    COUNT(o.order_id)              AS total_orders,
    ROUND(SUM(o.price), 0)        AS total_revenue,
    ROUND(AVG(o.price), 2)        AS avg_price
FROM fact_orders o
JOIN dim_dish dd ON o.food_id = dd.dish_id
GROUP BY dd.dish_name, dd.category
ORDER BY total_revenue DESC;

/*
OUTPUT:
dish_name	                                                 category	                 total_orders	total_revenue	avg_price
Full House Popcorn Chicken Bucket	                         Boneless Chicken Popcorn	   66	         79200          	1200
Big 12 Chicken Bucket	                      EPIC SAVINGS BUCKET FOR 34 UP TO 32 OFF	   85	         69738	            820.45
Hot Crispy Chicken 8 pcs	                  Hot & Crispy Chicken & Wings	               84	         67360	            801.9
Ultimate Savings Chicken Bucket               EPIC SAVINGS BUCKET FOR 34 UP TO 32 OFF	   84	         64612	            769.19
Chicken Supreme Thin n Crispy	              Thin n Crispy Pizzas	                       67	         63583	            949
Big 8 Chicken Bucket	                      Epic Savings Bucket For 34 up To 32 Off	   80	         61528	            769.09
Big Big 6in1 Pizza Non Veg	                  Big Big Pizza                                27	         59373	            2199
Chicken Pepperoni Thin n Crispy	              Thin n Crispy Pizzas                         67	         56883           	849
Kids Birthday Pizza Party with Chocolate 	  Kids Special  Pizza Party	                   15	         52485	            3499
Bold BBQ Veggie Thin n Crispy	              Thin n Crispy Pizzas	                       70	         52430	            749
*/

/*
Q15 — Category Performance by City
What food categories dominate in each city — useful for geo-menu insights
*/
WITH CityCategoryRev AS (
    SELECT
        l.city,
        dd.category,
        ROUND(SUM(o.price), 0)  AS total_revenue,
        RANK() OVER (
            PARTITION BY l.city
            ORDER BY SUM(o.price) DESC
        )                        AS cat_rank
    FROM fact_orders o
    JOIN dim_dish dd      ON o.food_id     = dd.dish_id
    JOIN dim_locations l  ON o.location_id  = l.location_id
    GROUP BY l.city, dd.category
)
SELECT city, category AS top_category, total_revenue
FROM   CityCategoryRev
WHERE  cat_rank = 1
ORDER BY total_revenue DESC;

/*
OUTPUT: Sample (Note : Only shimla shows Sweets as top_category rest are recommended user prefrence is food recommend by swiggy)
city	    top_category	total_revenue
Bengaluru	Recommended	    960832
Hyderabad	Recommended	    555363
Lucknow   	Recommended	    526622
New Delhi	Recommended	    498087
Chandigarh	Recommended	    450606
Kolkata	    Recommended	    450325
*/





