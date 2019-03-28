
drop view if exists z1;
drop view if exists y1;
drop view if exists c_sales; 
drop view if exists b_sales; 
drop view if exists a_sales; 
drop view if exists store_ymq;

create view store_ymq as 
select sales.store, 
extract(year from WeekDate) as year, 
extract(month from WeekDate) as mo, 
case when extract(month from WeekDate) >= 1 and extract(month from WeekDate) <= 3 then 'Q1' 
when extract(month from WeekDate) >= 4 and extract(month from WeekDate) <= 6 then 'Q2'
when extract(month from WeekDate) >= 7 and extract(month from WeekDate) <= 9 then 'Q3' 
when extract(month from WeekDate) >= 10 and extract(month from WeekDate) <= 12 then 'Q4'
else '' end as quarters, 
stores.type, 
sales.WeeklySales 
from hw2.sales 
join hw2.stores on sales.store = stores.store 
where stores.type = 'A' or stores.type = 'B'  or stores.type = 'C'
order by sales.store; 


create view a_sales as 
select store_ymq.year, 
store_ymq.quarters, 
sum (store_ymq.weeklySales) as store_a_sales 
from store_ymq 
where store_ymq.type = 'A' 
group by store_ymq.year, 
store_ymq.quarters
order by store_ymq.year, 
store_ymq.quarters;

drop view if exists b_sales; 
create view b_sales as 
select store_ymq.year, 
store_ymq.quarters, 
sum (store_ymq.weeklySales) as store_b_sales 
from store_ymq 
where store_ymq.type = 'B' 
group by store_ymq.year, 
store_ymq.quarters
order by store_ymq.year, 
store_ymq.quarters;

drop view if exists c_sales; 
create view c_sales as 
select store_ymq.year, 
store_ymq.quarters, 
sum (store_ymq.weeklySales) as store_c_sales 
from store_ymq 
where store_ymq.type = 'C' 
group by store_ymq.year, 
store_ymq.quarters
order by store_ymq.year, 
store_ymq.quarters;


create view y1 as
select a_sales.year as year, a_sales.quarters as quarters, a_sales.store_a_sales as a_sales, b_sales.store_b_sales as b_sales,c_sales.store_c_sales as c_sales
from a_sales 
join b_sales on a_sales.year = b_sales.year and a_sales.quarters = b_sales.quarters
join c_sales on a_sales.YEAR = c_sales.year and a_sales.quarters = c_sales.quarters;
  

create view z1 as
select year, sum(a_sales) as a_sales, sum(b_sales) as b_sales, sum(c_sales) as c_sales
from y1
group by year;

select * from (select year, quarters, a_sales, b_sales,  c_sales from y1 UNION ALL select year, NULL AS quarters, a_sales, b_sales, c_sales from z1) as foo ORDER BY "year", quarters;



-- year	quarters	a_sales	b_sales	c_sales
-- 2010	Q1	2.38155e+08	1.11852e+08	2.22457e+07
-- 2010	Q2	3.90789e+08	1.8321e+08	3.63698e+07
-- 2010	Q3	3.82694e+08	1.78504e+08	3.62904e+07
-- 2010	Q4	4.53791e+08	2.16412e+08	3.85719e+07
-- 2010		1.46543e+09	6.89978e+08	1.33478e+08
-- 2011	Q1	3.4185e+08	1.53903e+08	3.36366e+07
-- 2011	Q2	3.85807e+08	1.75557e+08	3.65836e+07
-- 2011	Q3	4.13363e+08	1.87497e+08	3.84974e+07
-- 2011	Q4	4.37185e+08	2.07162e+08	3.71553e+07
-- 2011		1.5782e+09	7.24118e+08	1.45873e+08
-- 2012	Q1	3.8145e+08	1.72499e+08	3.85173e+07
-- 2012	Q2	3.98117e+08	1.81932e+08	3.82482e+07
-- 2012	Q3	3.89167e+08	1.78201e+08	3.76368e+07
-- 2012	Q4	1.1864e+08	5.39714e+07	1.17501e+07
-- 2012		1.28737e+09	5.86604e+08	1.26152e+08
-- (15 rows)