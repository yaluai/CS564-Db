DROP VIEW
IF
	EXISTS v10;
CREATE VIEW v10 AS SELECT
sales.dept,
sales.store,
SUM ( WeeklySales ) / ( stores.SIZE ) AS norm 
FROM
	hw2.sales
	JOIN hw2.stores ON sales.store = stores.store 
GROUP BY
	sales.dept,
	sales.store,
	stores.SIZE;
SELECT
	dept,
	SUM ( norm ) AS NormSales 
FROM
	v10 
GROUP BY
	dept 
ORDER BY
	NormSales DESC 
	LIMIT 10;
	
	
-- 	 dept |    normsales     
-- ------+------------------
--    92 | 4128.35286278814
--    38 | 4080.21100678578
--    95 | 3879.83506743269
--    90 | 2567.52595662948
--    40 |  2400.3481441157
--     2 | 2232.72932645926
--    72 | 2191.77407134551
--    91 | 1791.72811012717
--    94 | 1747.77822848924
--    13 | 1620.50958560205
-- (10 rows)
