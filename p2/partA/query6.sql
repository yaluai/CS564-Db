DROP TABLE
IF
	EXISTS AvgSales;
CREATE TABLE averages AS SELECT AVG
( WeeklySales ) 
FROM
	hw2.sales;
DROP TABLE
IF
	EXISTS averages;
CREATE TABLE averages AS SELECT AVG
( sales.WeeklySales ) AS AvgSales,
AVG ( temporalData.Temperature ) AS AvgTemp,
AVG ( temporalData.FuelPrice ) AS AvgFuel,
AVG ( temporalData.CPI ) AS AvgCPI,
AVG ( temporalData.UnemploymentRate ) AS AvgUnemp 
FROM
	hw2.sales,
	hw2.temporalData 
WHERE
	sales.store = temporalData.store 
	AND sales.WeekDate = temporalData.WeekDate;
DROP TABLE
IF
	EXISTS output6;
CREATE TABLE output6 ( ATTRIBUTE VARCHAR ( 20 ), corr_sign VARCHAR ( 1 ), correlation REAL );
INSERT INTO output6
VALUES
	( 'Temperature', '', 0 ),
	( 'FuelPrice', '', 0 ),
	( 'CPI', '', 0 ),
	( 'UnemploymentRate', '', 0 );
UPDATE output6 
SET correlation = (
	SELECT CORR
		( temporalData.CPI, sales.WeeklySales ) 
	FROM
		hw2.sales,
		hw2.temporalData 
	WHERE
		sales.store = temporalData.store 
		AND sales.WeekDate = temporalData.WeekDate 
	) 
WHERE
	ATTRIBUTE = 'CPI';
UPDATE output6 
SET correlation = (
	SELECT CORR
		( temporalData.Temperature, sales.WeeklySales ) 
	FROM
		hw2.sales,
		hw2.temporalData 
	WHERE
		sales.store = temporalData.store 
		AND sales.WeekDate = temporalData.WeekDate 
	) 
WHERE
	ATTRIBUTE = 'Temperature';
UPDATE output6 
SET correlation = (
	SELECT CORR
		( temporalData.UnemploymentRate, sales.WeeklySales ) 
	FROM
		hw2.sales,
		hw2.temporalData 
	WHERE
		sales.store = temporalData.store 
		AND sales.WeekDate = temporalData.WeekDate 
	) 
WHERE
	ATTRIBUTE = 'UnemploymentRate';
UPDATE output6 
SET correlation = (
	SELECT CORR
		( temporalData.FuelPrice, sales.WeeklySales ) 
	FROM
		hw2.sales,
		hw2.temporalData 
	WHERE
		sales.store = temporalData.store 
		AND sales.WeekDate = temporalData.WeekDate 
	) 
WHERE
	ATTRIBUTE = 'FuelPrice';
UPDATE output6 
SET corr_sign =
CASE
		
		WHEN correlation < 0 THEN
		'-' 
		WHEN correlation > 0 THEN
		'+' ELSE'' 
	END;
SELECT
	* 
FROM
	output6;
	
-- 	    attribute     | corr_sign | correlation  
-- ------------------+-----------+--------------
--  Temperature      | -         |  -0.00231245
--  FuelPrice        | -         | -0.000120296
--  CPI              | -         |   -0.0209213
--  UnemploymentRate | -         |   -0.0258637
-- (4 rows)