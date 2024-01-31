
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
--	Patients by postcode - data validated in Part1 SQL. 
--	Maximum number of patients in scope is 1996

IF OBJECT_ID (N'tempdb..#PatientList',N'U') IS NOT NULL
			DROP TABLE #PatientList

SELECT		p.patient_id, 
			p.registration_guid,
			SUBSTRING(postcode,1,(CHARINDEX(' ',postcode,1)))  OutboundPostCode
INTO		#PatientList 
FROM		patient p
WHERE		p.date_of_death IS NULL
AND			SUBSTRING(p.postcode,1,(CHARINDEX(' ',p.postcode,1))) IN ('LS99','S72','LS22','BD12','WF9')

--	registration_guid is going to the most referenced column so I've added an index on it.	
CREATE INDEX IX_registration_guid ON #PatientList (registration_guid)
	
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	INCLUSIONS

---------------------------------------------------------------------------------------------------
--	Asthma
--	Pull all asthma records recardless of currently active status.  I want to use the most recent 
--	record to check its active.  Less of an issue for asthma but curable conditions may need the logic.
--	773 patients in scope

IF OBJECT_ID (N'tempdb..#Asthma',N'U') IS NOT NULL
			DROP TABLE #Asthma

SELECT		o.registration_guid, 
			o.recorded_date,
			o.regular_and_current_active_flag,
			ROW_NUMBER() OVER (PARTITION BY p.patient_id ORDER BY o.recorded_date DESC) as NewestSortOrder
INTO		#Asthma
FROM		observation o 
			INNER JOIN clinical_codes cc ON o.emis_code_id = cc.Code_id
			INNER JOIN patient p on o.registration_guid = p.registration_guid
WHERE		observation_type = 'Observation'
AND			cc.refset_simple_id IN (999012891000230104)		--	Asthma


--	registration_guid is going to the most referenced column so I've added an index on it.	
CREATE INDEX IX_registration_guid ON #Asthma (registration_guid)


--	Filter the most recent record and check current status
--	404 unique registration_guids where most recent record is active/current
IF OBJECT_ID (N'tempdb..#AsthmaShortList',N'U') IS NOT NULL
			DROP TABLE #AsthmaShortList

SELECT		* 
INTO		#AsthmaShortList
FROM		#Asthma
WHERE		NewestSortOrder = 1
AND			regular_and_current_active_flag = 'true'

CREATE INDEX IX_registration_guid ON #AsthmaShortlist (registration_guid)

--	Housekeeping
IF OBJECT_ID (N'tempdb..#Asthma',N'U') IS NOT NULL
			DROP TABLE #Asthma

---------------------------------------------------------------------------------------------------
--	Prescriptions
--	Five specific medication/ingredeants in spec




SELECT 




---------------------------------------------------------------------------------------------------
--	


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------