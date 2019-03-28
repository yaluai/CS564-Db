DROP VIEW
IF
	EXISTS sales_store_dept;
CREATE VIEW sales_store_dept AS SELECT
store,
dept,
SUM ( WeeklySales ) AS SalesStoreDept 
FROM
	hw2.sales 
GROUP BY
	store,
	dept;
DROP VIEW
IF
	EXISTS sales_store;
CREATE VIEW sales_store AS SELECT
store,
SUM ( WeeklySales ) AS SalesStore 
FROM
	hw2.sales 
GROUP BY
	store;
DROP VIEW
IF
	EXISTS contributions;
CREATE VIEW contributions AS SELECT
sales_store_dept.dept,
sales_store_dept.store,
(( SalesStoreDept / SalesStore ) * 100 ) AS percentContribution 
FROM
	sales_store_dept
	JOIN sales_store ON sales_store_dept.store = sales_store.store;
DROP VIEW
IF
	EXISTS significant_contributions;
CREATE VIEW significant_contributions AS SELECT
dept,
store,
percentContribution 
FROM
	contributions 
WHERE
	percentContribution >= 5;
DROP VIEW
IF
	EXISTS sig_contribution_count;
CREATE VIEW sig_contribution_count AS SELECT
dept,
COUNT ( * ) AS NumStores 
FROM
	significant_contributions 
GROUP BY
	dept;
DROP VIEW
IF
	EXISTS depts_significant_contributions;
CREATE VIEW depts_significant_contributions AS SELECT
dept 
FROM
	sig_contribution_count 
WHERE
	NumStores >= 3;
SELECT
	contributions.dept,
	AVG ( contributions.percentContribution / 100 ) AS AVG 
FROM
	contributions
	JOIN depts_significant_contributions ON contributions.dept = depts_significant_contributions.dept 
GROUP BY
	contributions.dept;


-- 	 dept |        avg         
-- ------+--------------------
--     2 | 0.0410644333395693
--    38 | 0.0727544868985812
--    40 | 0.0441973276022408
--    72 | 0.0420093366708089
--    90 |  0.044952085107151
--    91 | 0.0313700059687512
--    92 | 0.0730967512147294
--    93 | 0.0254024091054592
--    94 | 0.0304081375555446
--    95 | 0.0695251010358334
-- (10 rows)