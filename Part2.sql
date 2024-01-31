
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
--	Current diagnosis of asthma, i.e. have current observation in their medical record with relevant clinical 
--	codes from asthma refset (refsetid 999012891000230104), and not resolved

--	Pull all asthma records recardless of currently active status.  I want to use the most recent 
--	record to check its active.  Less of an issue for asthma but curable conditions may need the logic.
--	773 patients in scope

IF OBJECT_ID (N'tempdb..#Asthma',N'U') IS NOT NULL
			DROP TABLE #Asthma

SELECT		p.patient_id,
			o.registration_guid, 
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

SELECT		registration_guid,
			recorded_date,
			regular_and_current_active_flag,
			NewestSortOrder
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
--	Have been prescribed medication from the list below, or any medication containing these ingredients (i.e. child clinical codes), in the last 30 years:
--	Formoterol Fumarate (codeid 591221000033116, SNOMED concept id 129490002)
--	Salmeterol Xinafoate (codeid 717321000033118, SNOMED concept id 108606009)
--	Vilanterol (codeid 1215621000033114, SNOMED concept id 702408004)
--	Indacaterol (codeid 972021000033115, SNOMED concept id 702801003)
--	Olodaterol (codeid 1223821000033118, SNOMED concept id 704459002)


--	Sanity check - do the medication records map to the clinical codes?  
/*
SELECT		COUNT(1)
FROM		medication m INNER JOIN clinical_codes cc ON m.emis_code_id = cc.code_id
*/

IF OBJECT_ID (N'tempdb..#Medication',N'U') IS NOT NULL
			DROP TABLE #Medication

--			Create a dataset for prescriptions of the targeted drugs
--	0 rows
SELECT		p.patient_id,
			m.registration_guid,
			m.recorded_date, 
			emis_mostrecent_issue_date,		-- date of the prescription
			exa_mostrecent_issue_date,
			COALESCE(emis_mostrecent_issue_date,m.recorded_date) as DerivedPrescriptionDate,	--	Unable to confirm the prescription date based on names 
			fhir_medication_status,
			regular_and_current_active_flag,
			ROW_NUMBER() OVER (PARTITION BY p.patient_id ORDER BY m.recorded_date DESC) as NewestSortOrder
INTO		#Medication
FROM		medication m INNER JOIN clinical_codes cc on m.emis_code_id = cc.code_id
			INNER JOIN patient p on m.registration_guid = p.registration_guid
--WHERE		cc.code_Id IN (591221000033116,717321000033118,1215621000033114,972021000033115,1223821000033118)			--************************ REMOVE THESE COMMENTS ************************


IF OBJECT_ID (N'tempdb..#MedicationShortList',N'U') IS NOT NULL
			DROP TABLE #MedicationShortList

SELECT		patient_id,
			recorded_date, 
			emis_mostrecent_issue_date,		-- date of the prescription
			exa_mostrecent_issue_date,
			DerivedPrescriptionDate,
			registration_guid,
			fhir_medication_status,
			regular_and_current_active_flag,
			NewestSortOrder
INTO		#MedicationShortList
FROM		#Medication
WHERE		DerivedPrescriptionDate >= DATEADD("DAY",-(30*365),GETDATE())		--	

CREATE INDEX IX_registration_guid ON #MedicationShortList (registration_guid)

--	Housekeeping
IF OBJECT_ID (N'tempdb..#Medication',N'U') IS NOT NULL
			DROP TABLE #Medication

--	SELECT TOP 100 * FROM #MedicationShortList

---------------------------------------------------------------------------------------------------
--	


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------