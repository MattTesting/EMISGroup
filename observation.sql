

--	observation.sql
--	Matt Braithwaite
--	29Jan24
--	Initial DDL statement for target table


USE [EMIS]
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[observation]') AND type in (N'U'))
DROP TABLE [dbo].observation
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[observation](
	[abnormal] [bit] NULL,
	[emis_code_id] [bigint] NULL,
	[comparator] [nvarchar](10) NULL,
	[confidential_flag] [nvarchar](50) NULL,
	[confidential_patient_flag] [nvarchar](50) NULL,
	[consultation_source_emis_code_id] [bigint] NULL,
	[consultation_source_emis_original_term] [nvarchar](50) NULL,
	[document_guid] [uniqueidentifier] NULL,
	[dummy_patient_flag] [nvarchar](50) NULL,
	[effective_date] [datetime2](7) NULL,
	[effective_date_precision] [nvarchar](50) NULL,
	[emis_enteredby_userinrole_guid] [uniqueidentifier] NULL,
	[emis_episodicity] [tinyint] NULL,
	[end_date] [datetime2](7) NULL,
	[fhir_episodicity] [nvarchar](50) NULL,
	[emis_observation_guid] [uniqueidentifier] NULL,
	[exa_observation_guid] [uniqueidentifier] NULL,
	[fhir_interpretation_code] [nvarchar](50) NULL,
	[is_parent_flag] [nvarchar](50) NULL,
	[non_regular_and_current_active_flag] [nvarchar](50) NULL,
	[emis_observation_id] [int] NULL,
	[observation_type] [nvarchar](50) NULL,
	[emis_observationtypeid] [tinyint] NULL,
	[opt_out_93c1_flag] [nvarchar](50) NULL,
	[opt_out_9nd19nu09nu4_flag] [nvarchar](50) NULL,
	[opt_out_9nd19nu0_flag] [nvarchar](50) NULL,
	[opt_out_9nu0_flag] [nvarchar](50) NULL,
	[other_code] [nvarchar](50) NULL,
	[other_code_system] [nvarchar](50) NULL,
	[other_display] [nvarchar](150) NULL,
	[range_lower] [float] NULL,
	[range_upper] [nvarchar](50) NULL,			--	Speed of import defaulted to NVARCHAR as included in scope
	[readv2_code] [nvarchar](50) NULL,			--	Should be case sensitive
	[recorded_date] [datetime2](7) NULL,
	[registration_guid] [uniqueidentifier] NULL,
	[regular_and_current_active_flag] [nvarchar](50) NULL,
	[regular_current_active_and_inactive_flag] [nvarchar](50) NULL,
	[regular_patient_flag] [nvarchar](50) NULL,
	[emis_original_term] [nvarchar](250) NULL,
	[sensitive_flag] [bit] NULL,
	[sensitive_patient_flag] [nvarchar](50) NULL,
	[snomed_concept_id] [bigint] NULL,
	[snomed_description_id] [bigint] NULL,
	[emis_parent_observation_guid] [uniqueidentifier] NULL,
	[exa_parent_observation_guid] [uniqueidentifier] NULL,
	[uom] [nvarchar](50) NULL,
	[uom_ucum] [nvarchar](50) NULL,
	[user_selected] [nvarchar](1) NULL,
	[numericvalue] [decimal](18, 10) NULL,
	[value_pq_2] [nvarchar](1) NULL
) ON [PRIMARY]
GO


