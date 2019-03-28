SELECT DISTINCT store from hw2.temporaldata 
where hw2.temporaldata.unemploymentrate > 10.0
EXCEPT
SELECT DISTINCT store from hw2.temporaldata
where hw2.temporaldata.fuelprice > 4;




--  store 
-- -------
--     34
--     43
-- (2 rows)