



--	Assumptions
--	"not resolved" indicates there is a flag to show a diagnosis is currently active 
	--	identified "regular_and_current_active_flag" in observation
--	Observation_type defines the parent record and values are recorded as children.

--	CREATE INDEX IX_Observation_guid ON observation(emis_observation_guid)

--	Some diagnosis/observations are point in time e.g. a smoker gives up.  In that instance they 
--	would change their elegibility for the research study.


--	"With relevant clinical codes"

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Identify the different diagnosis/observations and then confirm they are applicable to the patient cohort


---------------------------------------------------------------------------------------------------
--	Medication
--	UNION confirms the  snomed/code_id are aligned and don't need deduplicating.
--	Descriptions confirm expectiations 
SELECT		* 
FROM		clinical_codes
WHERE		snomed_concept_id IN ('129490002','108606009','702408004','702801003','704459002')
UNION
SELECT		* 
FROM		clinical_codes
WHERE		code_id IN ('591221000033116','717321000033118','1215621000033114','972021000033115','1223821000033118')

---------------------------------------------------------------------------------------------------
--	Although these are the parent codes, the specification requires child codes are checked.
--	Confirm the relationship between clincial_codes and medication
SELECT		COUNT(1)
FROM		Medication m INNER JOIN clinical_codes cc ON m.emis_code_id = cc.code_id
WHERE		cc.Code_ID IN  ('591221000033116','717321000033118','1215621000033114','972021000033115','1223821000033118')


---------------------------------------------------------------------------------------------------
--	Refine the query to use one filter column and return the parent_code_id 
SELECT		parent_code_id 
FROM		clinical_codes
WHERE		code_id IN (591221000033116,717321000033118,1215621000033114,972021000033115,1223821000033118)

--	TO DO: specs require these have been prescribed in the last 30 years.

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Diagnosis/Observation (asthma,COPD, smoker)  (Chronic obstructive pulmonary disease)
SELECT *  FROM clinical_codes WHERE emis_term LIKE '%smoker%'
UNION 
SELECT * FROM clinical_codes WHERE emis_term LIKE '%asthma%'
UNION
SELECT *  FROM clinical_codes WHERE emis_term LIKE '%COPD%'


---------------------------------------------------------------------------------------------------
--	427 code_id records attached to these three elements
SELECT		code_id 
FROM		clinical_Codes 
WHERE		refset_simple_id in (999012891000230104,999004211000230104,999011571000230107)

SELECT		*
FROM		observation o INNER JOIN clinical_codes cc ON o.emis_code_id = cc.Code_id
WHERE		observation_type = 'Observation'
AND			cc.refset_simple_id IN (999012891000230104,999004211000230104,999011571000230107)



---------------------------------------------------------------------------------------------------
--	Asthma only
SELECT		*
FROM		observation o INNER JOIN clinical_codes cc ON o.emis_code_id = cc.Code_id
WHERE		observation_type = 'Observation'
AND			cc.refset_simple_id IN (999012891000230104)	--	ASthma


---------------------------------------------------------------------------------------------------
--	smoker/COPD only
SELECT		*
FROM		observation o INNER JOIN clinical_codes cc ON o.emis_code_id = cc.Code_id
WHERE		observation_type = 'Observation'
AND			cc.refset_simple_id IN (999004211000230104,999011571000230107)	--	smoker/COPD


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Weight
--	Check for snomed concept code in observations
SELECT	observation_type,
		emis_original_term,
		numericvalue,
		uom,
		UOM_UCUM,
		emis_code_id,
		recorded_date
FROM observation where snomed_concept_id = 27113001



SELECT		DISTINCT emis_code_id		
FROM		observation 
WHERE		snomed_concept_id = 27113001

--	Confirm the code exists in clinical_codes
SELECT * FROM clinical_codes WHERE code_id IN( 253677014,253688015)
SELECT * FROM clinical_codes WHERE snomed_concept_id = 27113001

SELECT		o.observation_type,
			o.emis_original_term,
			o.numericvalue,
			o.uom,
			o.emis_code_id,
			o.recorded_date,
			p.patient_id,
			o.Registration_guid,
			ROW_NUMBER() OVER (PARTITION BY p.patient_id ORDER BY o.recorded_date DESC) as NewestSortOrder
FROM		observation o INNER JOIN patient p ON o.registration_guid = p.registration_guid
WHERE		snomed_concept_id = 27113001





/*
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Asthma - current and active = true
--	Is the observation the latest e.g. the most recent observation for the scenario and still valid.

IF OBJECT_ID(N'tempdb..#Asthma') IS NOT NULL DROP TABLE #Asthma
GO

--	Collect all asthma observations
;WITH tAsthma
AS
(
			SELECT		o.EMIS_Observation_ID, 
						registration_guid, 
						o.snomed_concept_id, 
						o.regular_and_current_active_flag, 
						o.recorded_date, 
						cc.emis_term,
						cc.Refset_simple_id
			FROM		observation o INNER JOIN clinical_codes cc ON o.snomed_concept_id = cc.snomed_concept_id
			WHERE		cc.Refset_simple_id = '999012891000230104'
			AND			o.observation_type = 'Observation'
)
--	
SELECT		registration_GUID, recorded_date , regular_and_current_active_flag, emis_term, ROW_NUMBER() OVER (PARTITION BY Registration_GUID ORDER BY recorded_date DESC) as ORDERED
INTO		#Asthma
FROM		tAsthma
--GROUP BY	registration_GUID,regular_and_current_active_flag

SELECT * from #Asthma

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Smoker - current and active = true
--	Is the observation the latest e.g. the most recent observation for the scenario and still valid.
--	Some conflicts with regular_and_current_active_flag where showing false but emis_term indicates is a smoker

IF OBJECT_ID(N'tempdb..#Smoker') IS NOT NULL DROP TABLE #Smoker
GO
;WITH tAsthma
AS
(
			SELECT		o.EMIS_Observation_ID, 
						registration_guid, 
						o.snomed_concept_id, 
						o.regular_and_current_active_flag, 
						o.recorded_date,
						cc.emis_term, o.observation_type
			FROM		observation o INNER JOIN clinical_codes cc ON o.snomed_concept_id = cc.snomed_concept_id
			WHERE		cc.Refset_simple_id = '999004211000230104'
			--AND regular_and_current_active_flag = 'false'
)
SELECT		registration_GUID, MAX(recorded_date) MaxRecordDate, regular_and_current_active_flag
INTO		#Smoker
FROM		tSmoker
GROUP BY	registration_GUID,regular_and_current_active_flag

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--	Weight
--	Is the observation the latest e.g. the most recent observation for the scenario and still valid.


IF OBJECT_ID(N'tempdb..#Weight') IS NOT NULL DROP TABLE #Weight
GO
;WITH tWeight
AS
(
			SELECT		o.EMIS_Observation_ID, 
						registration_guid, 
						o.snomed_concept_id, 
						o.regular_and_current_active_flag, 
						o.recorded_date,
						cc.emis_term, o.*
			FROM		observation o INNER JOIN clinical_codes cc ON o.snomed_concept_id = cc.snomed_concept_id
			WHERE		cc.Refset_simple_id = '999004211000230104'
			AND regular_and_current_active_flag = 'false'
)
SELECT		registration_GUID, MAX(recorded_date) MaxRecordDate, regular_and_current_active_flag
INTO		#Weight
FROM		tWeight
GROUP BY	registration_GUID,regular_and_current_active_flag

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
*/