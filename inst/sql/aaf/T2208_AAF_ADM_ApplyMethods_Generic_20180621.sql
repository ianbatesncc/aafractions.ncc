-- connect to ucs-bisqldb
USE Public_Health
;
GO

/*
Apply methods Generic

 - alcohol-related (narrow)
 - alcohol-related (broad)
 - alcohol-specific
*/

/*
Variables in this script.  See sections (below) for more detail.

	Analysis method: @analysismethod	Determine broad, narrow or specific analysis
	Date range: @datestart, @dateend	Default for full year.  Sorry limited to between 2015/04/01 and 2016/03/31.
*/

/*
Analysis method

Can only choose one at a time.  Filters the  tmpIB__PHIT_IP__aamethod lookup
table for that measure.

'Method' returned in the dataset - so can UNION/concatenate all results into one
table in e.g. EXCEL.

Can choose one of related (broad), related (narrow) or specific.
*/
declare @analysismethod as nvarchar(48)

--set @analysismethod = 'alcohol-related (broad)'
set @analysismethod = 'alcohol-related (narrow) phe'
--set @analysismethod = 'alcohol-specific'

/*
Set date range

- just to limit size of query
- must be subset of the range used to create tmpIB__PHIT_IP__aamethod (Sorry
limited to FY 2015/16 - i.e. between 2015/04/01 and 2016/03/31.)

- default set to FY2015/16 - no need to change
*/

declare @datestart as datetime
declare @dateend as datetime

declare @fystart as varchar(4) ;
declare @fyend as varchar(4) ;

set @fystart = '2015'
set @fyend   = '2016'

set @datestart = @fystart + '/03/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16
--set @datestart = @fystart + '/03/31'	;	set @dateend = @fystart + '/07/01' ; -- FY 2015/16 Q1
--set @datestart = @fystart + '/06/30'	;	set @dateend = @fystart + '/10/01' ; -- FY 2015/16 Q2
--set @datestart = @fystart + '/09/30'	;	set @dateend = @fyend   + '/01/01' ; -- FY 2015/16 Q3
--set @datestart = @fystart + '/12/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16 Q4

/*
Analysis type

Note: tmpIB__PHIT_IP__aamethod created using the 'morbidity' version of the
PHE AAF lookup table.
*/

/*
Main
*/
;WITH
cte_filter --(data_source, [aa method], GenderC, [Age_SYOA], [AgeBand_ESP], af, [condition uid], LADCD)
AS (
	SELECT
		-- what
		'HES IP with local AF calculation'	AS [data_source]
		, PHIT_IP__AA.[aa_method]			AS [AA method]
		-- when
		, 'FY2015/16'						AS [period]	-- span of tmpIB__PHIT_IP__aamethod
		, datepart(yyyy, IP.Consultant_Episode_End_Date)	as calyear
		, datepart(q, IP.Consultant_Episode_End_Date)		as calquarter
		, IP.Financial_Year_D

		-- uid
		, IP.Generated_Record_Identifier	AS [GRID]	-- unique per record
		, LAPH_IP.HES_Identifier_Encrypted	AS [HESIDE]	-- unique per individual

		-- demographics
		, LEFT(AC_GENDER.Description, 1)	AS [GenderC] -- MF
		, PHIT_IP__AA.aa_agesyoa			AS [Age_SYOA]
		, ABPH.AgeBand_ESP					AS [AgeBand_ESP] -- x[x]-y[y] | 90+ (from 0-4 to 90+)
		, PHIT_IP__AA.aa_ageband			AS [AgeBand_AAF] -- axxyy | a75+ (from a00-15 to a75+)
		, IP.Ethnic_Category				AS [Ethnicity_Code]
		, AC_ETHNIC.Description				AS [Ethnicity]

		-- clinical
		, PHIT_IP__AA.af					AS [af]
		, PHIT_IP__AA.icd10					AS [principal_aa_icd10]

		, DATEDIFF(
			DAY
			, IP.Consultant_Episode_Start_Date
			, IP.Consultant_Episode_End_Date
		)									AS [Episode LOS]
		, IP.Episode_Duration_from_Grouper	AS [Episode LOS Grouper]

		, AAC.[condition cat1]				AS [principal_aa_phe_cat1]
		, AAC.[condition cat2]				AS [principal_aa_phe_cat2]
		, AAC.[condition desc]				AS [principal_aa_phe_desc]
		, AAC.[cause basis]					AS [principal_aa_phit_basis]
		, AAC.[condition uid]				AS [phit_aa_condition_uid]

		, IP.Diagnosis_ICD_1
		, IP.Diagnosis_ICD_Concatenated_D

		, CC_AA.Chapter						AS [principal_aa_icd10_chapter]
		, CC_AA.[Group]						AS [principal_aa_icd10_group]
		, CC_AA.[Description]				AS [principal_aa_icd10_desc]

		-- more when
		, IP.Consultant_Episode_Start_Date				AS [date_episode_consultant_start]
		, IP.Consultant_Episode_End_Date				AS [date_episode_consultant_end]
		-- to consider for readmissions possibly
		, IP.Admission_Date_Hospital_Provider_Spell		AS [date_spell_hospital_provider_admission]
		, IP.Discharge_Date_Hospital_Spell_Provider		AS [date_spell_hospital_provider_discharge]

		, IP.[SUS_Generated_Spell_Id]

		-- where
		, IP.Local_Authority_District		AS [LADCD]
		, CASE
			WHEN IP.Local_Authority_District = 'E06000018'
				THEN 'City'
			WHEN IP.Local_Authority_District IN
				('E07000170', 'E07000171', 'E07000172', 'E07000173', 'E07000174', 'E07000175', 'E07000176')
				THEN 'County'
			ELSE 'Other UTLA'
		END									AS [UTLA]
		, case
			when IP.Local_Authority_District in
				(
				    'E06000018'
				    , 'E07000170', 'E07000171', 'E07000172', 'E07000173'
				    , 'E07000174', 'E07000175', 'E07000176'
				)
				THEN IP.Local_Authority_District
			when GIS_LSOA_2011_D = 'NULL'
				then 'Residence Unknown'
			else 'Not Resident N2'
		END									AS [LADCD_LOCAL]
		,

		FROM
			[ucs-bisqldev].PHIIT.dbo.tmpIB__AA__PHIT_IP__aamethod					AS PHIT_IP__AA

				LEFT JOIN [Public_Health].[dbo].[HES_IP]							AS IP
					ON (PHIT_IP__AA.[GRID] = IP.Generated_Record_Identifier)

				LEFT JOIN [Public_Health].[dbo].[LAPH_IP]							AS LAPH_IP
					ON (LAPH_IP.[Generated_Record_Identifier] = IP.[Generated_Record_Identifier])

				LEFT JOIN [ucs-bisqldev].PHIIT.dbo.tmpIB__AA__aac					AS AAC
					ON (AAC.[condition uid] = PHIT_IP__AA.[aa_uid])

				LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes]					AS CC_AA
					ON (CC_AA.Code = PHIT_IP__AA.icd10 AND CC_AA.Field_Name = 'Diagnosis_ICD')

				LEFT JOIN [Shared_Reference].[dbo].[Age_Bands_Public_Health]		AS ABPH
					ON (
						(ABPH.[ESP_Year] = '2013') AND
						(PHIT_IP__AA.aa_agesyoa = ABPH.Age_Years)
					)

				LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]			AS AC_GENDER
					ON (AC_GENDER.Field_Name = 'gender' AND AC_GENDER.Code = IP.Gender)

				LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]			AS AC_ETHNIC
					ON (AC_ETHNIC.Field_Name = 'Ethnic_Category' AND AC_ETHNIC.Code = IP.Ethnic_Category)

		WHERE
			(
				-- When - Events between dates specified - subset of tmpIB__PHIT_IP__aamethod span (FY2015/16)
				(IP.Consultant_Episode_End_Date > @datestart) AND
				(IP.Consultant_Episode_End_Date < @dateend)
			)
			AND
			(
			    1 = 1
				--(PHIT_IP__AA.[aa_method] NOT LIKE '%pos1override') AND
				--(PHIT_IP__AA.[aa_method] LIKE '%broad%') AND (IP.Local_Authority_District in ('E06000018'))
				--(PHIT_IP__AA.[aa_method] LIKE '%broad%') AND (IP.Local_Authority_District not in ('E06000018'))
				--(PHIT_IP__AA.[aa_method] LIKE '%narrow%')
				--(PHIT_IP__AA.[aa_method] LIKE '%specific%')
			)
)
SELECT * FROM cte_filter
	-- chronological view
	ORDER BY
		[date_spell_hospital_provider_admission] ASC
		, [date_spell_hospital_provider_discharge] ASC
		, [date_episode_consultant_start]
		, [date_episode_consultant_end]
		, GRID ASC

	-- multiple admission view
	--ORDER BY HESIDE, Consultant_Episode_End_Date ASC, GRID ASC
;
