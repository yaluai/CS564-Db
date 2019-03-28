DROP VIEW IF EXISTS holidays_sales_view;


CREATE VIEW holidays_sales_view AS 
SELECT store, SUM ( sales.weeklysales ) AS holiday_sales FROM sales
	JOIN holidays ON sales.weekdate = holidays.weekdate 
	AND holidays.isholiday 
	GROUP BY sales.store;

SELECT store,holiday_sales  FROM holidays_sales_view 
WHERE holiday_sales = ( SELECT MAX ( holiday_sales ) FROM holidays_sales_view ) 
	OR holiday_sales = ( SELECT MIN ( holiday_sales ) FROM holidays_sales_view );
	

--- output    
--- store |  holiday_sales  
--- -------+-------------
---    33 | 2.62594e+06
---    20 | 2.24903e+07
--- (2 rows)