/*

Main.sql

*/

/*

These scripts do these things and should be called in the suggested order

T2208 AAF ADM 11 TagAFInspect 20180303

 * Create lookup table of relevant records (af NOT populated at this stage)

	CREATE TABLE [dbo].tmpIB__PHIT_IP__melt(
		[GRID] [bigint] NULL
		, [icd10] [varchar](4) NULL
		, [pos] [smallint] NULL
		, [uid] [smallint] NULL
		, af [decimal](10,2) NULL
	)

 - IP FILTERED by

	date/Consultant_Episode_End_Date
	, patclass/Patient_Classification
	, epistatus/Episode_Status
	, epiorder/Consultant_Episode_Number

 - UNPIVOT on IP.Diagnosis_ICD_1 + ';' + Diagnosis_ICD_Concatenated_D

 - INNER JOINED on [ucs-bisqldev].[PHIIT].[dbo].[tmpIB__lu__uid_icd]


T2208 AAF ADM 12 TagAF 20180305

 * tag on AF to the lookup table

 - AGE using Age_at_Start_of_Episode_D or Age_On_Admission (> 7000 -> 0)

 -- AGEBAND from 
	[ucs-bisqldb].[Shared_Reference].[dbo].[Age_Bands_Public_Health].[Alcohol_Fraction_AgeBand]

 - GENDER using adminCode lookup from IP.Gender


T2208 AAF ADM 20 ConstructMethods 20180301

 * Create record level results table

	CREATE TABLE [dbo].tmpIB__PHIT_IP__aamethod(
		[aa method] [varchar](32) NULL,
		[GRID] [bigint] NULL,
		[icd10] [varchar](4) NULL,
		[pos] [smallint] NULL,
		[uid] [smallint] NULL,
		[af] [decimal](10,2) NULL,
	)

 - Populate with records satisfying 

	'alcohol-related (broad)'
	'alcohol-related (narrow) pos1override'
	'alcohol-related (narrow) phe'
	'alcohol-specific'


T2208 AAF ADM 30 ApplyMethods 20180301

T2208 AAF ADM 31 ApplyMethods LSOA 20180305


T2208 AAF ADM AR NARROW records

T2208 AAF ADM AS records 20180227

T2208 AAF ADM AS records



*/

/*

Not used

T2208 AAF ADM 10 TagAF 20180228



*/