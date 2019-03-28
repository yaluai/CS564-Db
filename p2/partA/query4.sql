join hw2.stores on stores.store = sales.store
group by month, stores.type;

create view type_sum_sales as 
select type, sum (sumByMonthAndType) as sumByType
from month_type 
group by type;

select month_type.month, month_type.type, month_type.sumByMonthAndType as sum, (month_type.sumByMonthAndType / type_sum_sales.sumByType * 100) as Contribution
from month_type
JOIN type_sum_sales on
month_type.type = type_sum_sales.TYPE
ORDER BY TYPE, MONTH;


drop view if exists type_sum_sales;
drop view if exists month_type;


create view month_type as 
select substr( cast (sales.WeekDate as text), 6, 2) as month, stores.type, sum (sales.WeeklySales) as sumByMonthAndType
from hw2.sales
join hw2.stores on stores.store = sales.store
group by month, stores.type;

create view type_sum_sales as 
select type, sum (sumByMonthAndType) as sumByType
from month_type 
group by type;

select month_type.month, month_type.type, month_type.sumByMonthAndType as sum, (month_type.sumByMonthAndType / type_sum_sales.sumByType * 100) as Contribution
from month_type
JOIN type_sum_sales on
month_type.type = type_sum_sales.TYPE
ORDER BY TYPE, MONTH;


-- month	type	sum	contribution
-- 01	A	2.14176e+08	4.94517721235752
-- 02	A	3.66508e+08	8.46241042017937
-- 03	A	3.80774e+08	8.79180356860161
-- 04	A	4.16179e+08	9.60927531123161
-- 05	A	3.59087e+08	8.2910567522049
-- 06	A	3.99447e+08	9.22295972704887
-- 07	A	4.17242e+08	9.6338264644146
-- 08	A	3.94863e+08	9.11711677908897
-- 09	A	3.73118e+08	8.61503332853317
-- 10	A	3.77132e+08	8.70771259069443
-- 11	A	2.64721e+08	6.11223019659519
-- 12	A	3.67763e+08	8.49139764904976
-- 01	B	9.54463e+07	4.7706451267004
-- 02	B	1.67672e+08	8.38064849376678
-- 03	B	1.75136e+08	8.75373631715775
-- 04	B	1.9088e+08	9.54067260026932
-- 05	B	1.63456e+08	8.16992372274399
-- 06	B	1.86362e+08	9.31485965847969
-- 07	B	1.93743e+08	9.68375876545906
-- 08	B	1.81505e+08	9.07208025455475
-- 09	B	1.68954e+08	8.444744348526
-- 10	B	1.70604e+08	8.52722898125648
-- 11	B	1.25546e+08	6.27508908510208
-- 12	B	1.81396e+08	9.06661227345467
-- 01	C	2.29758e+07	5.66599629819393
-- 02	C	3.45485e+07	8.51989611983299
-- 03	C	3.68754e+07	9.09372046589851
-- 04	C	3.97991e+07	9.81473028659821
-- 05	C	3.45834e+07	8.52850303053856
-- 06	C	3.68194e+07	9.07992050051689
-- 07	C	3.90145e+07	9.62125509977341
-- 08	C	3.67216e+07	9.05579254031181
-- 09	C	3.66886e+07	9.04766693711281
-- 10	C	3.70491e+07	9.13656800985336
-- 11	C	2.27486e+07	5.60997352004051
-- 12	C	2.76796e+07	6.82599395513535
-- (36 rows)