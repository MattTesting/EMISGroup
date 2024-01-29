




--	Part1_build.sql
--	Matt Braithwaite
--	29Jan24
--	Initial patient profile checks

USE EMIS
GO

SELECT TOP 100 * FROM patient


---------------------------------------------------------------------------------------------------
--	NULL CHECKS
--	105 missing postcodes identified
SELECT		COUNT(1), 
			SUM(CASE WHEN postcode IS NULL THEN 1 ELSE 0 END) NULL_Count
FROM		patient


-------------------
--	No missing Gender values
SELECT		COUNT(1),
			SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) NULL_Count
FROM		patient


-------------------
--	Available gender values
/*
Gender			Volume
Indeterminate	442
Unknown			434
Male			1842
Female			1825
*/
SELECT		Gender, COUNT(1) Volume
FROM		patient
GROUP BY	Gender


-------------------
--	Deceased patients are unlikely to participate in a research study.
--	3 deceased patients found
SELECT		COUNT(1), 
			SUM(CASE WHEN date_of_death IS NOT NULL THEN 1 ELSE 0 END) Death_Count
FROM		patient


SELECT * FROM patient where date_of_death is NOT NULL

SELECT Age, COUNT(1) volume
FROM patient 
GROUP BY age
ORDER BY Volume DESC

---------------------------------------------------------------------------------------------------

--	Check postcode area outward codes (first half)
SELECT		TOP 1000 SUBSTRING(postcode,1,(CHARINDEX(' ',postcode,1))), postcode
FROM		patient
WHERE		postcode IS NULL

--	Check full postcode

SELECT		postcode,
			COUNT(1) Volume
FROM		patient
GROUP BY	postcode
ORDER BY	volume DESC



---------------------------------------------------------------------------------------------------
SELECT		postcode,
			gender,
			COUNT(1) Volume
FROM		patient
--WHERE		date_of_death is NULL
GROUP BY	postcode,
			gender
ORDER BY	volume DESC



