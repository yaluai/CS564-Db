drop table if exists months;
create table months (
month varchar(2)
);
insert into months values ('01');
insert into months values ('02');
insert into months values ('03');
insert into months values ('04');
insert into months values ('05');
insert into months values ('06');
insert into months values ('07');
insert into months values ('08');
insert into months values ('09');
insert into months values ('10');
insert into months values ('11');
insert into months values ('12');

drop table if exists store_dept_yearandmonth;
create table store_dept_yearandmonth as 
select distinct store, substr( cast (WeekDate as text), 0, 5) as year, substr(cast (WeekDate as text), 6, 2) as month, dept 
from hw2.sales;

drop view if exists loser_stores;
drop view if exists sales2010;
drop view if exists sales2011;
drop view if exists sales2012;

create view sales2010 as 
select distinct s1.store, s1.dept, months.month 
from store_dept_yearandmonth s1, months 
where s1.year = cast ('2010' as text)
except 
select distinct s2.store, s2.dept, s2.month 
from store_dept_yearandmonth s2 
where s2.year = cast ('2010' as text);

create view sales2011 as 
select distinct s1.store, s1.dept, months.month 
from store_dept_yearandmonth s1, months 
where s1.year = cast ('2011' as text)
except 
select distinct s2.store, s2.dept, s2.month 
from store_dept_yearandmonth s2 
where s2.year = cast ('2011' as text);

create view sales2012 as 
select distinct s1.store, s1.dept, months.month 
from store_dept_yearandmonth s1, months 
where s1.year = cast ('2012' as text)
except 
select distinct s2.store, s2.dept, s2.month 
from store_dept_yearandmonth s2 
where s2.year = cast ('2012' as text);

create view loser_stores as 
select distinct store from sales2010 
intersect 
select distinct store from sales2011
intersect 
select distinct store from sales2012;

select distinct store from store_dept_yearandmonth 
except 
select store from loser_stores;

-- 
--（0 rows）