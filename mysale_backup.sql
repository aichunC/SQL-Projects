show databases;

create database mysale_schema;

use mysale_schema;


show tables;

-- analyze dataset saldedataasc

select * from saledataasc;


-- use distinct to check some unique values in each column --------------------------------------------------------
delimiter //

create procedure selectall ()
begin
   select * from saledataasc ;
end//

call selectall;

select distinct status from saledataasc; 
select distinct country from saledataasc;


 
select distinct month_ID from saledataasc
order by month_ID;


-- Analysing revenues---------------------------------------------------------------------------------- 
-- revenue of each country by total sale in three years 
select  country,sum(sales) from saledataasc
group by country 
order by country asc;

-- revenue of each country in each of three year 
select  country,year_id,sum(sales) from saledataasc
group by country, year_id
order by country asc;

-- find the best seller , motorcycles is the best seller

select  productline,sum(sales) from saledataasc
group by productline
order by sum(sales) asc;


select  productline,sum(sales) from saledataasc
where status = 'shipped'
group by productline 
having count(sales) > 10
order by sum(sales) asc;


 -- RFM analysis recency-frequency-mnetary ----------------------------------------------------------------
-- determine different kind of cusotmers by saledataasc
-- it is an indexing technique that use past purhcase to determine to segment customers
-- an RFM report is a way of segmenting customer using recency, frequency, and monetary value 
-- recency : last order date, frequncy : coutn of total orders, monetary value: total spend 


-- use with to create a temp table 


 with rfm as (
select 
customername,
sum(sales) MonetaryValue,
avg(sales) Average_MV,
count(ordernumber) Frequency,
 max(str_to_date(orderdate, '%m/%d/%Y')) last_order_date,
(select max(orderdate) from saledataasc) max_order_date,
datediff((select max(str_to_date(orderdate,'%m/%d/%Y')) from saledataasc), max(str_to_date(orderdate,'%m/%d/%Y'))) recency
from saledataasc
group by customername
),
rfm_cal as (
	select * ,
	ntile(4)over( order by recency desc) rfm_recency,
	ntile(4)over( order by frequency) rfm_frequeny,
	ntile(4)over( order by Average_MV) rfm_monetary
	from rfm )

select customername , 
	 rfm_recency + rfm_frequeny + rfm_monetary as rfm_cell,
	 concat(rfm_recency,rfm_frequeny ,rfm_monetary) rfm_string
	 -- cast(rfm_recency as char) + cast(rfm_frequeny as char) + cast(rfm_monetary as char) rfm_string 
from rfm_cal;

select * ,
	case
	when rfm_string in (111,112,121,122,123,132, 211,212,114,141) then "lost customer"
    when rfm_string in (311,411,331, 222,221,233,322) then "new customer"
    when rfm_string in (433,434,443,444,323,333,321,422,332,432) then "loyal"
	else "Deciding"
	end as customer_level
from info ;

-- next question : which products buy together often ? ------------------------------------------------------------

-- method 1: use a series of subquery 
select distinct ordernumber, 
(select 
group_concat('', productcode )
from saledataasc ss
where ordernumber in 
(select distinct ordernumber 
from (
	select ordernumber, 
	count(*) rn
	from saledataasc
	where status='shipped'
	group by ordernumber 
)m 
where rn=2
AND s.ordernumber = ss.ordernumber
) 
) t
from saledataasc s
order by  2 desc


 


-- method 2: use group_concat, this method obtained the same results as the above code. 
-- this method code is shorter, much more efficient. only need 1 subquery


-- select concat( 'a','b')

select ordernumber, rn,pcode from(

	 select ordernumber, 
count(*) rn,
group_concat(productcode) pcode
from saledataasc
group by ordernumber
) fst
where rn = 2
order by 3 asc

