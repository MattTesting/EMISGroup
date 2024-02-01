
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Part2.sql
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
--	1996 records in scope

IF OBJECT_ID (N'tempdb..#PatientList',N'U') IS NOT NULL
			DROP TABLE #PatientList

SELECT		p.patient_id, 
			p.registration_guid,
			SUBSTRING(postcode,1,(CHARINDEX(' ',postcode,1)))  OutboundPostCode,
			p.postcode,
			p.patient_givenname,
			p.patient_surname,
			p.Patient_givenname + ' ' + p.patient_surname FullName,
			p.age, --assumes this is calculated each day by source system. 
			p.gender
INTO		#PatientList 
FROM		patient p
WHERE		p.date_of_death IS NULL
AND			SUBSTRING(p.postcode,1,(CHARINDEX(' ',p.postcode,1))) IN ('LS99','S72','LS22','BD12','WF9')

--	registration_guid is going to the most referenced column so I've added an index on it.	
CREATE INDEX IX_registration_guid ON #PatientList (registration_guid)

--	SELECT TOP 100 * FROM #PatientList
	
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	INCLUSIONS

---------------------------------------------------------------------------------------------------
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

SELECT		patient_id,
			registration_guid,
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

--	SELECT COUNT(1) , COUNT(DISTINCT patient_id) FROM #AsthmaShortList

---------------------------------------------------------------------------------------------------
--	Prescriptions
--	Have been prescribed medication from the list below, or any medication containing these ingredients (i.e. child clinical codes), in the last 30 years:
--	Formoterol Fumarate (codeid 591221000033116, SNOMED concept id 129490002)
--	Salmeterol Xinafoate (codeid 717321000033118, SNOMED concept id 108606009)
--	Vilanterol (codeid 1215621000033114, SNOMED concept id 702408004)
--	Indacaterol (codeid 972021000033115, SNOMED concept id 702801003)
--	Olodaterol (codeid 1223821000033118, SNOMED concept id 704459002)


--	Sanity check - Couldnt find any matches for the drug codes so did a quick count of what does match
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
--			Below codes defined in spec
--WHERE		cc.code_Id IN (591221000033116,717321000033118,1215621000033114,972021000033115,1223821000033118)			--************************ REMOVE THESE COMMENTS FOR LIVE ************************


IF OBJECT_ID (N'tempdb..#MedicationShortList',N'U') IS NOT NULL
			DROP TABLE #MedicationShortList

--	zero records in scope as source temp table returns zero
SELECT		patient_id,
			registration_guid,
			recorded_date, 
			emis_mostrecent_issue_date,		-- date of the prescription
			exa_mostrecent_issue_date,
			DerivedPrescriptionDate,
			fhir_medication_status,
			regular_and_current_active_flag,
			NewestSortOrder
INTO		#MedicationShortList
FROM		#Medication
WHERE		DerivedPrescriptionDate >= DATEADD("DAY",-(30*365),GETDATE())		--	last 30 years

CREATE INDEX IX_registration_guid ON #MedicationShortList (registration_guid)

--	Housekeeping
IF OBJECT_ID (N'tempdb..#Medication',N'U') IS NOT NULL
			DROP TABLE #Medication


--	SELECT COUNT(1) , COUNT(DISTINCT patient_id) FROM #MedicationShortList


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	EXCLUSIONS

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Smoker
--	AND should be excluded if:
--		Currently a smoker i.e.  have current observation with relevant clinical codes from smoker 
--		refset (refsetid 999004211000230104)

--	Again looking at the most recent record to allow for someone that has quit smoking.
--	1926 patients in scope

IF OBJECT_ID (N'tempdb..#Smoker',N'U') IS NOT NULL
			DROP TABLE #Smoker

SELECT		p.patient_id,
			o.registration_guid, 
			o.recorded_date,
			o.regular_and_current_active_flag,
			ROW_NUMBER() OVER (PARTITION BY p.patient_id ORDER BY o.recorded_date DESC) as NewestSortOrder
INTO		#Smoker
FROM		observation o 
			INNER JOIN clinical_codes cc ON o.emis_code_id = cc.Code_id
			INNER JOIN patient p on o.registration_guid = p.registration_guid
WHERE		observation_type = 'Observation'
AND			cc.refset_simple_id IN (999004211000230104)		--	Smoker


--	registration_guid is going to the most referenced column so I've added an index on it.	
CREATE INDEX IX_registration_guid ON #Smoker (registration_guid)


--	Filter the most recent record and check current status
--	805 unique registration_guids where most recent record is active/current
IF OBJECT_ID (N'tempdb..#SmokerShortList',N'U') IS NOT NULL
			DROP TABLE #SmokerShortList

SELECT		patient_id,
			registration_guid,
			recorded_date,
			regular_and_current_active_flag,
			NewestSortOrder
INTO		#SmokerShortList
FROM		#Smoker
WHERE		NewestSortOrder = 1
AND			regular_and_current_active_flag = 'true'

CREATE INDEX IX_registration_guid ON #SmokerShortlist (registration_guid)

--	Housekeeping
IF OBJECT_ID (N'tempdb..#Smoker',N'U') IS NOT NULL
			DROP TABLE #Smoker


--	SELECT COUNT(1) , COUNT(DISTINCT patient_id) FROM #SmokerShortlist

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	COPD
--	Current diagnosis of COPD, i.e. have current observation in their medical record with relevant clinical 
--	codes from COPD refset (refsetid 999011571000230107), and not resolved

--	Pull all COPD records recardless of currently active status.  I want to use the most recent 
--	record to check its active.  Less of an issue for asthma but curable conditions may need the logic.
--	290 patients in scope

IF OBJECT_ID (N'tempdb..#COPD',N'U') IS NOT NULL
			DROP TABLE #COPD

SELECT		p.patient_id,
			o.registration_guid, 
			o.recorded_date,
			o.regular_and_current_active_flag,
			ROW_NUMBER() OVER (PARTITION BY p.patient_id ORDER BY o.recorded_date DESC) as NewestSortOrder
INTO		#COPD
FROM		observation o 
			INNER JOIN clinical_codes cc ON o.emis_code_id = cc.Code_id
			INNER JOIN patient p on o.registration_guid = p.registration_guid
WHERE		observation_type = 'Observation'
AND			cc.refset_simple_id IN (999011571000230107)		--	COPD


--	registration_guid is going to the most referenced column so I've added an index on it.	
CREATE INDEX IX_registration_guid ON #COPD (registration_guid)


--	Filter the most recent record and check current status
--	59 unique registration_guids where most recent record is active/current
IF OBJECT_ID (N'tempdb..#COPDShortList',N'U') IS NOT NULL
			DROP TABLE #COPDShortList

SELECT		patient_id,
			registration_guid,
			recorded_date,
			regular_and_current_active_flag,
			NewestSortOrder
INTO		#COPDShortList
FROM		#COPD
WHERE		NewestSortOrder = 1
AND			regular_and_current_active_flag = 'true'

CREATE INDEX IX_registration_guid ON #COPDShortlist (registration_guid)

--	Housekeeping
IF OBJECT_ID (N'tempdb..#COPD',N'U') IS NOT NULL
			DROP TABLE #COPD


--	SELECT COUNT(1) , COUNT(DISTINCT patient_id) FROM #COPDShortlist

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Weight
--	Currently weight less than 40kg (SNOMED concept id 27113001)


--	2976 records
IF OBJECT_ID(N'tempdb..#Weight') IS NOT NULL 
			DROP TABLE #Weight
GO

SELECT		o.observation_type,
			o.emis_original_term,
			o.numericvalue,
			o.uom,		--	This is populated for all rows as kg
			o.emis_code_id,
			o.recorded_date,
			p.patient_id,
			o.Registration_guid,
			ROW_NUMBER() OVER (PARTITION BY p.patient_id ORDER BY o.recorded_date DESC) as NewestSortOrder
INTO		#Weight
FROM		observation o INNER JOIN patient p ON o.registration_guid = p.registration_guid
WHERE		snomed_concept_id = 27113001

--	validate the latest recorded weight is correctly marked as NewestSortOrder = 1
--	SELECT * FROM #Weight WHERE patient_id = 9599 ORDER BY recorded_date


--	Filter the most recent record and check current status
--	163 records
IF OBJECT_ID (N'tempdb..#WeightShortList',N'U') IS NOT NULL
			DROP TABLE #WeightShortList

SELECT		patient_id,
			registration_guid,
			numericvalue
INTO		#WeightShortList
FROM		#Weight
WHERE		NewestSortOrder = 1
AND			numericvalue < 40	--	weight less than 40kg


--	Housekeeping
IF OBJECT_ID (N'tempdb..#Weight',N'U') IS NOT NULL
			DROP TABLE #Weight


--	SELECT COUNT(1) , COUNT(DISTINCT patient_id) FROM #WeightShortList
--	SELECT * FROM #Weight WHERE patient_id = 9599 ORDER BY recorded_date

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Optouts
--	Only patients that have not opted out of taking part in research or sharing their medical record 
--	should be invited to participate (type 1 opt out, connected care opt out)

--	Only opt out fields available are medication and observation.
--	93c1 identified as type 1 opt out via Google. 
--	(https://www.mysurgerywebsite.co.uk/website/L81078/files/Gloucester_Road_Medical_Centre_Data_sharing_opt_out_form.pdf)
--	(https://kintburyandwooltonhillsurgeries.co.uk/wp-content/uploads/2020/05/5.-Patient-Data-Sharing-Opt-Out-KBWH-v20.1.pdf)
--	93c1 appears to cover type 1 opt out and connected care opt out

--	Date constraint has been dropped from this code as it's not clear if the opt out is persistant or required for every observation.

--	658 rows - 9 unique
IF OBJECT_ID(N'tempdb..#Optout') IS NOT NULL 
			DROP TABLE #Optout

SELECT		p.Patient_id,
			p.registration_guid
INTO		#Optout
FROM		observation o 
			INNER JOIN patient p ON o.registration_guid = p.registration_guid
WHERE		o.opt_out_93c1_flag = 'true'

--	SELECT COUNT(1), COUNT(DISTINCT patient_id) FROM #optout

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
/*
Current have inclusion datasets for:
	Patient		-1996 rows
	Asthma		-404 rows
	Medication	-0 rows (tested without this criteria created 2994 rows /134 unique patients)

Currently have exclusion datasets for:
	Smoker		-805 rows
	COPD		-59 rows
	Weight		-163 rows
	Optout		-658 - 9 unique patients
*/



/* Correction needed - Inclusions need to be BOTH, not either  */


IF OBJECT_ID (N'tempdb..#Inclusions',N'U') IS NOT NULL
			DROP TABLE #Inclusions

--	Blended inclusions
SELECT		a.Patient_id, 'asthma' AS Source
INTO		#Inclusions
FROM		#AsthmaShortList a
UNION
SELECT		m.Patient_id, 'medication' AS Source
FROM		#MedicationShortList m


IF OBJECT_ID (N'tempdb..#Exclusions',N'U') IS NOT NULL
			DROP TABLE #Exclusions

--	Blended Exclusions
SELECT		s.Patient_id, 'smoker' AS Source
INTO		#Exclusions
FROM		#SmokerShortList s
UNION
SELECT		c.Patient_id, 'COPD' AS Source
FROM		#COPDShortList c
UNION
SELECT		w.Patient_id, 'weight' AS Source
FROM		#WeightShortList w
UNION
SELECT		o.Patient_id, 'optout' AS Source
FROM		#Optout o



---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Build output

--	output 

SELECT		DISTINCT
			p.registration_guid,
			p.patient_id, 
			p.FullName, 
			p.postcode,
			p.age,
			p.gender
FROM		#PatientList p
			INNER JOIN #Inclusions i ON p.patient_id = i.patient_id		--	reduction to 58 unique clients
WHERE		p.patient_id NOT IN (
				SELECT e.patient_id from #Exclusions e )-- Reduction to 36 records




SELECT		DISTINCT
			p.registration_guid,
			p.patient_id, 
			p.FullName, 
			p.postcode,
			p.age,
			p.gender
FROM		#PatientList p
			INNER JOIN #AsthmaShortList a ON p.patient_id = a.patient_id		
			INNER JOIN #MedicationShortList m ON p.Patient_id = m.patient_id
WHERE		p.patient_id NOT IN (
				SELECT e.patient_id from #Exclusions e )-- Reduction to 36 records

				SELECT * FROM #MedicationShortList