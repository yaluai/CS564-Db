drop view if exists weekly_sales_with_holiday;

create view weekly_sales_with_holiday as 
select holidays.weekdate, holidays.isholiday, sum (sales.weeklysales) as total_sales 
from hw2.sales
JOIN hw2.holidays
ON sales.weekdate = holidays.weekdate
group by holidays.weekDate, holidays.IsHoliday;

select count(*) 
from weekly_sales_with_holiday
where isholiday = false and total_sales  > ( 
select avg (total_sales ) 
from weekly_sales_with_holiday 
where isholiday = true
);

--  count 
-- -------
--      8
-- (1 row)
