

--	medication.sql
--	Matt Braithwaite
--	29Jan24
--	Initial DDL statement for target table


USE [EMIS]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[medication]') AND type in (N'U'))
DROP TABLE [dbo].[medication]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[medication](
	[nhs_prescribing_agency] [nvarchar](50) NULL,
	[emis_drug_guid] [uniqueidentifier] NULL,
	[authorisedissues_authorised_date] [datetime2](7) NULL,
	[authorisedissues_first_issue_date] [datetime2](7) NULL,
	[cancellation_reason] [nvarchar](50) NULL,
	[emis_code_id] [bigint] NULL,
	[confidential_flag] [nvarchar](50) NULL,
	[consultation_source_emis_code_id] [nvarchar](50) NULL,
	[consultation_source_emis_original_term] [nvarchar](50) NULL,
	[dose] [nvarchar](150) NULL,
	[emis_medication_status] [tinyint] NULL,
	[dummy_patient_flag] [nvarchar](50) NULL,
	[duration_in_days] [int] NULL,
	[duration_uom] [nvarchar](50) NULL,
	[effective_date] [datetime2](7) NULL,
	[effective_date_precision] [nvarchar](50) NULL,
	[emis_issue_method] [nvarchar](50) NULL,
	[emis_mostrecent_issue_date] [datetime2](7) NULL,
	[emis_prescription_type] [nvarchar](50) NULL,
	[emis_registration_organisation_guid] [nvarchar](50) NULL,
	[emis_encounter_guid] [uniqueidentifier] NULL,
	[exa_encounter_guid] [uniqueidentifier] NULL,
	[end_date] [datetime2](7) NULL,
	[emis_enteredby_userinrole_guid] [nvarchar](50) NULL,
	[exa_prescription_guid] [uniqueidentifier] NULL,
	[estimated_nhs_cost] [money] NULL,
	[exa_drug_guid] [uniqueidentifier] NULL,
	[medication_guid] [uniqueidentifier] NULL,
	[exa_medication_guid] [uniqueidentifier] NULL,
	[fhir_medication_intent] [nvarchar](50) NULL,
	[exa_mostrecent_issue_date] [datetime2](7) NULL,
	[max_nextissue_days] [int] NULL,
	[min_nextissue_days] [int] NULL,
	[non_regular_and_current_active_flag] [nvarchar](50) NULL,
	[number_authorised] [int] NULL,
	[number_of_issues] [tinyint] NULL,
	[opt_out_93c1_flag] [nvarchar](50) NULL,
	[opt_out_9nd19nu09nu4_flag] [nvarchar](50) NULL,
	[opt_out_9nd19nu0_flag] [nvarchar](50) NULL,
	[opt_out_9nu0_flag] [nvarchar](50) NULL,
	[emis_medication_organisation_guid] [uniqueidentifier] NULL,
	[other_code] [nvarchar](50) NULL,
	[other_code_system] [nvarchar](50) NULL,
	[prescribed_as_contraceptive_flag] [nvarchar](50) NULL,
	[privately_prescribed_flag] [nvarchar](50) NULL,
	[quantity] [float] NULL,
	[recorded_date] [datetime2](7) NULL,
	[registration_guid] [uniqueidentifier] NULL,
	[regular_and_current_active_flag] [nvarchar](50) NULL,
	[regular_current_active_and_inactive_flag] [nvarchar](50) NULL,
	[regular_patient_flag] [nvarchar](50) NULL,
	[reimburse_type] [nvarchar](150) NULL,
	[review_date] [datetime2](7) NULL,
	[emis_original_term] [nvarchar](250) NULL,
	[sensitive_flag] [nvarchar](50) NULL,
	[sensitive_patient_flag] [nvarchar](50) NULL,
	[snomed_concept_id] [bigint] NULL,
	[snomed_description_id] [bigint] NULL,
	[fhir_medication_status] [nvarchar](50) NULL,
	[cancellation_date] [datetime2](7) NULL,
	[nhs_prescription_type] [nvarchar](50) NULL,
	[uom] [nvarchar](50) NULL,
	[uom_dmd] [nvarchar](1) NULL
) ON [PRIMARY]
GO


