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
-- Connect to ucs-bisqldb
/*

Tables of interest

	[ucs-bisqldev].PHIIT.dbo.tmpIB__PHIT_IP__aamethod
	
		Pre-calculated.  Contains, for each measure, a set of records 
		relevant to that measure, and for each record identifies the 
		principal alcohol related diagnosis code and attributable fraction.

		USE PHIIT;
		GO
		CREATE TABLE [dbo].tmpIB__PHIT_IP__aamethod(
			[aa method] [varchar](48) NULL,		-- string to describe method
			[GRID] [bigint] NULL,				-- Generated_Record_Identifier in IP
			[icd10] [varchar](4) NULL,			-- the 'principal alcohol diagnosis code'
			[pos] [smallint] NULL,				-- position in all diagnosis codes (1 to 20)
			[uid] [smallint] NULL,				-- internal unique identifier for the alcohol condition (PHE vocabulary)
			[af] [decimal](10,2) NULL,			-- the (age, gender) specific alcohol fraction for the condition (uid).
		)
	
	[ucs-bisqldev].PHIIT.dbo.tmpIB__aac
	
		Lookup.  From condition code to various descriptive categories.
		
		USE PHIIT;
		GO
		CREATE TABLE [dbo].[tmpIB__aac](
			[condition uid] [bigint] NULL,				-- internal unique identifier for the alcohol condition (PHE vocabulary)
			[condition cat1] [varchar](54) NULL,		-- partial/whole (PHE vocabulary)
			[condition cat2] [varchar](33) NULL,		-- whole/if partial then broad disease category (PHE vocabulary, like ICD chapter but perhaps not)
			[condition desc] [varchar](67) NULL,		-- description of condition (PHE vocabulary)
			[condition attribution] [varchar](7) NULL,	-- partial/whole (IB abbreviated from PHE)
			[cause basis] [varchar](10) NULL,			-- individual/external (IB vocabulary - perhaps PHE 'chronic' and 'acute' vocabulary consistent - 'individual'/'external' maps to 'chronic'/'acute' respectively.)
			[icd codes] [varchar](27) NULL				-- PHE list of codes
		)

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

set @fystart = '2015' /* -- '2012' '2013' -- '2014' -- '2015' */
set @fyend   = '2016' /* -- '2013' '2014' -- '2013' -- '2016' */

set @datestart = @fystart + '/03/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16
--set @datestart = @fystart + '/03/31'	;	set @dateend = @fystart + '/07/01' ; -- FY 2015/16 Q1
--set @datestart = @fystart + '/06/30'	;	set @dateend = @fystart + '/10/01' ; -- FY 2015/16 Q2
--set @datestart = @fystart + '/09/30'	;	set @dateend = @fyend   + '/01/01' ; -- FY 2015/16 Q3
--set @datestart = @fystart + '/12/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16 Q4

/*

Analysis type

NOT RELEVANT FOR THIS ADMISSION ANALYSIS

Note: tmpIB__PHIT_IP__aamethod created using the 'morbidity' version of the 
PHE AAF lookup table.

*/


/*

Main

*/
;WITH
/*
Pre-adjust some fields from IP to align with how tmpIB__PHIT_IP__aamethod lookup table was generated

 * Age_at_Start_of_Episode_D__adj
 
	IP.Age_at_Start_of_Episode_D ELSE Age_On_Admission BOTH > 7000 -> 0

*/
cte_adjustage_ip
AS (
	SELECT
		*
		, CASE
			WHEN (NOT IP.Age_at_Start_of_Episode_D IS NULL) THEN
				CASE WHEN (IP.Age_at_Start_of_Episode_D > 7000) THEN 0 ELSE IP.Age_at_Start_of_Episode_D	END
			ELSE
				CASE WHEN (IP.Age_On_Admission > 7000)			THEN 0 ELSE IP.Age_On_Admission				END
			END
																AS [Age_at_Start_of_Episode_D__adjusted]
																
		FROM [Public_Health].[dbo].[HES_IP]						AS IP
) -- /cte_adjustage_ip
, cte_filter --(data_source, [aa method], GenderC, [Age_SYOA], [AgeBand_ESP], af, [condition uid], LADCD)
AS (
	SELECT
		-- what
		'HES IP with local AF calculation'	AS [data_source]
		, PHIT_IP.[aa method]				AS [AA method]
		-- when
		, 'FY2015/16'						AS [period]	-- span of tmpIB__PHIT_IP__aamethod
		
		-- uid
		, IP.Generated_Record_Identifier	AS [GRID]	-- unique per record
		, LAPH_IP.HES_Identifier_Encrypted	AS [HESIDE]	-- unique per individual

		-- demographics
		, LEFT(ACGENDER.Description, 1)		AS [GenderC] -- MF
	--	, IP.Age_at_Start_of_Episode_D		AS [Age_SYOA]
		, IP.[Age_at_Start_of_Episode_D__adjusted]	AS [Age_SYOA]
		, ABPH.AgeBand_ESP					AS [AgeBand_ESP] -- x[x]-y[y] | 90+ (from 0-4 to 90+)
		, ABPH.Alcohol_Fraction_Ageband		AS [AgeBand_AAF] -- axxyy | a75+ (from a00-15 to a75+)

		-- clinical
		, PHIT_IP.af						AS [af]
		, PHIT_IP.icd10						AS [principal_aa_icd10]
		
		, DATEDIFF(
			DAY
			, IP.Consultant_Episode_Start_Date
			, IP.Consultant_Episode_End_Date
		)									AS [Episode LOS]
		
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
		, IP.Consultant_Episode_Start_Date
		, IP.Consultant_Episode_End_Date
		-- to consider for readmissions possibly
		/*
		, IP.Admission_Date_Hospital_Provider_Spell
		, IP.Discharge_Date_Hospital_Spell_Provider
		, IP.Discharge_Date_Hospital_Spell_Provider__adjusted
		, IP.[SUS_Generated_Spell_Id]
		*/
		
		-- where
		, IP.Local_Authority_District		AS [LADCD]
		, CASE
			WHEN IP.Local_Authority_District = 'E06000018'
				THEN 'City'
			WHEN IP.Local_Authority_District IN ('E07000170', 'E07000171', 'E07000172', 'E07000173', 'E07000174', 'E07000175', 'E07000176')
				THEN 'County'
			ELSE 'Other UTLA'
		END									AS [UTLA]
		
		FROM 
			--[Public_Health].[dbo].[HES_IP]											AS IP
			cte_adjustage_ip															AS IP
			
				INNER JOIN [ucs-bisqldev].PHIIT.dbo.tmpIB__PHIT_IP__aamethod		AS PHIT_IP
					ON (
						(PHIT_IP.[aa method] = @analysismethod) AND
						(PHIT_IP.[GRID] = IP.Generated_Record_Identifier)
					)

				LEFT JOIN [Public_Health].[dbo].[LAPH_IP]							AS LAPH_IP
					ON (LAPH_IP.[Generated_Record_Identifier] = IP.[Generated_Record_Identifier])
			
				LEFT JOIN [ucs-bisqldev].PHIIT.dbo.tmpIB__aac						AS AAC
					ON (AAC.[condition uid] = PHIT_IP.[uid])
					
				LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes]					AS CC_AA
					ON (CC_AA.Code = PHIT_IP.icd10 AND CC_AA.Field_Name = 'Diagnosis_ICD')

				LEFT JOIN [Shared_Reference].[dbo].[Age_Bands_Public_Health]		AS ABPH
					ON (
						(ABPH.[ESP_Year] = '2013') AND
						(IP.Age_at_Start_of_Episode_D__adjusted = ABPH.Age_Years)
					)
					
				LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]			AS ACGENDER
					ON (ACGENDER.Field_Name = 'gender' AND ACGENDER.Code = IP.Gender)
					
		WHERE
			(
				-- When - Events between dates specified - subset of tmpIB__PHIT_IP__aamethod span (FY2015/16)
				(IP.Consultant_Episode_End_Date > @datestart) AND
				(IP.Consultant_Episode_End_Date < @dateend)
			)
			AND
			(
				-- where
				(IP.Local_Authority_District in (
					'E06000018'
					, 'E07000170', 'E07000171', 'E07000172', 'E07000173'
					, 'E07000174', 'E07000175', 'E07000176'
				))
				-- OR (1 = 1)
				-- OR (IP.CCG_of_Residence in ('04K', '02Q', '04E', '04H', '04L', '04M', '04N'))
			)
) -- /cte_filter

SELECT * FROM cte_filter
	-- chronological view
	ORDER BY Consultant_Episode_End_Date ASC, GRID ASC

	-- multiple admission view
	--ORDER BY HESIDE, Consultant_Episode_End_Date ASC, GRID ASC
;
