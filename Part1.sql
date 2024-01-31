
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Part1.sql
--	Matt Braithwaite
--	29Jan24
--	Avaliable optimisations - Indexes on postcode, gender
--	Assumptions	- postcodes will always be correctly formatted in the source system e.g. have a space in the correct place.
--	Deceased atients are excluded.


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Select environment
USE EMIS
GO


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	First query to check postcode volumes regardless of other conditions.
SELECT		postcode,
			COUNT(1) Volume
FROM		patient
WHERE		date_of_death is NULL
GROUP BY	postcode
ORDER BY	volume DESC

/*
postcode	Volume
LS99 9ZZ	1787
NULL		102
LS1 2AF		7
LS1 7WX		7
*/
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Output from above shows one postcode dominating the volumes (LS99 9ZZ).  This is an invalid postcode but 
--	for the purposes of this exercise I've included it so the subsequent parts of the test have appropriate volumes.

--	Second place is NULL which can be excluded from the output.
--	This second query looks at the outbound part of the postcode to see if volumes can be better aligned
--	for part 2 of the test.

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	This query only considers the outbound part of the postcode and associated volumes

SELECT		SUBSTRING(postcode,1,(CHARINDEX(' ',postcode,1))) OutboundPart,
			COUNT(1) Volume
FROM		patient
WHERE		date_of_death is NULL
AND			postcode IS NOT NULL
GROUP BY	SUBSTRING(postcode,1,(CHARINDEX(' ',postcode,1)))
ORDER BY	volume DESC

/*
OutboundPart	Volume
LS99 			1787
S72 			55
LS22 			53
BD12 			51
WF9 			50
*/
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	The above results indicate LS99 and S72 are the top two postcodes by volume.  
--	For a better overview I will consider the top 5 in subsequent queries as the gender distribution 
--	may not be suitable in the top two.

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Validate gender distribution for the top 5 (outbound) postcodes

SELECT		SUBSTRING(postcode,1,(CHARINDEX(' ',postcode,1))) OutboundPart,
			gender,
			COUNT(1) Volume
FROM		patient
WHERE		date_of_death is NULL
AND			SUBSTRING(postcode,1,(CHARINDEX(' ',postcode,1))) IN ('LS99','S72','LS22','BD12','WF9')
GROUP BY	SUBSTRING(postcode,1,(CHARINDEX(' ',postcode,1))),
			gender
ORDER BY	OutboundPart, gender

/*
OutboundPart	gender			Volume
BD12 			Female			26
BD12 			Male			25
LS22 			Female			27
LS22 			Male			26
LS99 			Female			465
LS99 			Indeterminate	435		*
LS99 			Male			457
LS99 			Unknown			430		*
S72 			Female			25
S72 			Male			30
WF9 			Female			28
WF9 			Male			22
*/

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	LS99 includes two additional gender classifactions along with male and female.
--	All postcode regions under review have a relateively even split of genders (inc LS99)




