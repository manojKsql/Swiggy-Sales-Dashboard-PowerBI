select * from swiggydata;

-- Data Validation
--null check
select
sum(case when State is null then 1 else 0 end) as null_state,
sum(case when City is null then 1 else 0 end) as null_City,
sum(case when Order_Date is null then 1 else 0 end) as null_Order_Date,
sum(case when Restaurant_Name is null then 1 else 0 end) as null_Restaurant_Name,
sum(case when Location is null then 1 else 0 end) as null_Location,
sum(case when Category is null then 1 else 0 end) as null_Category,
sum(case when Dish_Name is null then 1 else 0 end) as null_Dish_Name,
sum(case when Price_INR is null then 1 else 0 end) as null_Price_INR,
sum(case when Rating is null then 1 else 0 end) as null_Rating,
sum(case when Rating_Count is null then 1 else 0 end) as null_Rating_Count
from swiggydata;

-- find blank data/empty data
select * from swiggydata
where State='' or City='' or Order_Date='' or Restaurant_Name='' or Location='';

-- duplicate data
select State,City,Order_Date,Restaurant_Name,Location,Category,Dish_Name,
Price_INR,Rating,Rating_Count,count(*) as cnt  from swiggydata
group by State,City,Order_Date,Restaurant_Name,Location,Category,Dish_Name,
Price_INR,Rating,Rating_Count
having count(*)>1;

--Delete duplicate data

with cte as (select *,ROW_NUMBER() over (partition by State,City,Order_Date,Restaurant_Name,Location,Category,Dish_Name,
Price_INR,Rating,Rating_Count order by (select Null)) as rn
from swiggydata)
delete from cte where rn>1;


select * from swiggydata;

--creating scheme
-- Dimension Table
-- Data table

create table dim_date(
date_id int identity(1,1) primary key,
full_date Date,
Year INT,
Month int,
Month_Name varchar(20),
quarter int,
day int,
week int);

--location Tbale
create table dim_location(
location_id int identity(1,1) primary key,
state varchar(100),
city varchar(100),
location varchar(200)
);

--dim Restaurant Table
create table dim_restaurant(
Restaurant_id int identity(1,1) primary key,
Restaurant_Name varchar(200)
);
-- dim category table
create table dim_category(
category_id int identity(1,1) primary key,
category varchar(200)
);

-- dim dish table
create table dim_dish(
dish_id int identity(1,1) primary key,
Dish_Name varchar(200)
);

--create fact table
create table fact_swiggy_orders(
order_id int identity(1,1) primary key,
date_id int,
Price_INR decimal(10,2),
Rating Decimal(4,2),
Rating_Count int,
location_id int,
Restaurant_id int,
category_id int,
dish_id int,
Foreign key (date_id) references dim_date(date_id),
Foreign key (location_id) references dim_location(location_id),
Foreign key (Restaurant_id) references dim_restaurant(Restaurant_id),
Foreign key (category_id) references dim_category(category_id),
Foreign key (dish_id) references dim_dish(dish_id)
);

--insert data in tables
--dim_date

insert into dim_date(full_date,Year,Month,Month_Name,quarter,day,week)
select distinct
Order_Date,
YEAR(Order_Date),
Month(Order_Date),
DATENAME(Month,Order_Date),
DATEPART(QUARTER,Order_Date),
DAY(Order_Date),
DATEPART(week,Order_Date)
from swiggydata
where Order_Date is not null;
select * from dim_date;

--insert data in dim_location
insert into dim_location(state,city,location)
select distinct State,City,Location 
from swiggydata;
select * from dim_location;

--dim_restaurant
insert into dim_restaurant(Restaurant_Name)
select distinct Restaurant_Name from swiggydata;
select * from dim_restaurant;

--dim_category
insert into dim_category(category)
select distinct Category from swiggydata;

--dim_dish
insert into dim_dish(Dish_Name)
select distinct Dish_Name from swiggydata
select * from dim_dish;

--fact_tables
INSERT INTO fact_swiggy_orders(date_id,Price_INR,Rating,Rating_Count,location_id,Restaurant_id,
category_id,dish_id)
select 
dd.date_id,s.Price_INR,s.Rating,s.Rating_Count,dl.location_id,dr.Restaurant_id,
dc.category_id,dds.dish_id
from 
swiggydata s 
join 
dim_date dd 
on
dd.full_date=s.Order_Date 
join 
dim_location dl 
on 
dl.state=s.State and dl.city=s.City and dl.location=s.Location
join 
dim_restaurant dr 
on 
dr.Restaurant_Name=s.Restaurant_Name 
join 
dim_category dc 
on 
dc.category=s.Category 
join
dim_dish dds 
on 
dds.Dish_Name=s.Dish_Name;

select * from fact_swiggy_orders
order by order_id asc;
select * from swiggydata;

select * from fact_swiggy_orders f 
join dim_date dd on dd.date_id=f.date_id 
join dim_location dl on f.location_id=dl.location_id 
join dim_restaurant dr on f.Restaurant_id=dr.Restaurant_id 
join dim_category dc on f.category_id=dc.category_id 
join dim_dish dds on f.dish_id=dds.dish_id;


--KPI's
-- TotalOrders-197401

select count(*) as Total_Oredrs from fact_swiggy_orders;

--Total_Revenue (INR_Million)-53.00 Million

select format(sum(convert(float,Price_INR))/1000000,'N2') + 'Million' as Total_Revenue_INR 
from fact_swiggy_orders;

--Avg Dish Price-268.50
select format(avg(convert(float,Price_INR)),'N2') as Avg_dish_Price from fact_swiggy_orders;

--Avg Rating- 4.341577
select avg(Rating) as Avg_Rating from fact_swiggy_orders;

-- Granular Requirements
-- Date based Analysis
-- Monthly order Trends

select
d.Year,
d.Month,
d.Month_Name,count(*) as Total_Orders
from fact_swiggy_orders f join dim_date d on
d.date_id=f.date_id
group by d.Year,
d.Month,
d.Month_Name;

-- Quarterly Order Trends

select d.Year,d.quarter,count(*) as Quarterly_Trends
from fact_swiggy_orders f join dim_date d
on f.date_id=d.date_id
group by d.Year,d.quarter
order by Quarterly_Trends desc;

-- Year wise Trends

select d.Year,count(*) as Year_Trends
from fact_swiggy_orders f join dim_date d ON f.date_id=d.date_id
group by d.Year
order by Year_Trends;

-- Day of week Trends

select DATENAME(WEEKDAY,d.full_date) as Day_of_week,
count(*) as Week_Trends from fact_swiggy_orders f
join dim_date d on f.date_id=d.date_id
group by DATENAME(WEEKDAY,d.full_date),DATEPART(WEEKDAY,d.full_date)
order by DATEPART(WEEKDAY,d.full_date);

-- Top 10 city by order volume

select top 10 l.city,count(*) as Total_Orders
from fact_swiggy_orders f join dim_location l on
f.location_id=l.location_id
group by l.city
order by count(*) desc;

-- Revenue Contribution by states
select top 10 l.state,sum(price_INR) as Total_Revenue from fact_swiggy_orders
f join dim_location l on f.location_id=l.location_id
group by l.state
order by Total_Revenue desc;

--  top 10 restaurant by Orders
select top 10 r.restaurant_name,count(*) as Total_orders from fact_swiggy_orders f
join dim_restaurant r on f.Restaurant_id=r.Restaurant_id
group by r.Restaurant_Name
order by Total_orders desc;

-- top category inidia,chinese..
select top 10 c.category,count(*) as Total_Orders from fact_swiggy_orders f join dim_category c
on f.category_id=c.category_id
group by c.category
order by Total_Orders desc;

-- Most Orders dish

select top 10 d.dish_name,count(*) as Total_Orders from fact_swiggy_orders f join dim_dish d
on f.dish_id=d.dish_id
group by d.Dish_Name
order by Total_Orders desc;

--cusine analysis orders + avg_rating
select c.category,AVG(Rating) as Avg_rating,count(*) as Total_Orders from fact_swiggy_orders f join dim_category c
on f.category_id=c.category_id
group by c.category
order by Total_Orders desc;

-- Buckets of customer spend:

select case
			when CONVERT(float,Price_INR) <100 then 'Under 100'
			when convert(float,Price_INR) between 100 and 199 then  '100-199'
			when convert(float,Price_INR) between 200 and 299 then  '200-299'
			when convert(float,Price_INR) between 300 and 499 then  '300-499'

			else '500+'
		end as Price_Range,COUNT(*) as Total_Orders
		from fact_swiggy_orders
		group by   
		case
			when CONVERT(float,Price_INR) <100 then 'Under 100'
			when convert(float,Price_INR) between 100 and 199 then  '100-199'
			when convert(float,Price_INR) between 200 and 299 then  '200-299'
			when convert(float,Price_INR) between 300 and 499 then  '300-499'
			else '500+'
		end
		order by Total_Orders desc;

-- Rating count	distribution
select Rating,count(*) as Total_Rating from fact_swiggy_orders
group by Rating
order by Rating desc;

select * from swiggydata;