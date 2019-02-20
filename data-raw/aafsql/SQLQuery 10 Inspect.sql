
/* inspect */

with
cte_tag
AS (
SELECT
	*, case 
		when IP.Age_at_Start_of_Episode_D between 0 and 120 then '0-120'
		else convert(nvarchar(8), IP.Age_at_Start_of_Episode_D)
	end as [Age_extremes]
	FROM
		[Public_Health].[dbo].[HES_IP]											AS IP
) -- /cte_tag
, cte_age_extremes
AS (
SELECT 'age extremes' as [extremes type]
	, count(*) as n
	, [Age_extremes] as [extremes]
	FROM cte_tag
	GROUP BY [Age_extremes]
)
,
cte_gender_extremes
AS (
SELECT 'gender extremes' as [extremes type]
	, count(*) as n
	, IP.Gender as [extremes]
	FROM [Public_Health].[dbo].[HES_IP]											AS IP
	GROUP BY IP.Gender
)
,
cte_lad_ccg_extremes
AS (
SELECT 'lad ccg extremes' as [extremes type]
	, count(*) as n
	, IP.Local_Authority_District + ';' + IP.CCG_of_Residence as [extremes]
	FROM [Public_Health].[dbo].[HES_IP]											AS IP
	WHERE (
		(IP.Local_Authority_District in (
			'E06000018'
	        , 'E07000170', 'E07000171', 'E07000172', 'E07000173'
	        , 'E07000174', 'E07000175', 'E07000176')) OR
		(IP.CCG_of_Residence in ('04K', '02Q', '04E', '04H', '04L', '04M', '04N')) OR
		(IP.Local_Authority_District IS NULL) OR
		(IP.CCG_of_Residence is NULL)
	)
	GROUP BY IP.Local_Authority_District, IP.CCG_of_Residence
)
SELECT * from cte_age_extremes
UNION ALL
SELECT * from cte_gender_extremes
UNION ALL
SELECT * from cte_lad_ccg_extremes

	ORDER BY [extremes type]
	, [extremes]


GO

select
	COUNT(*) as nRecords
	, GIS_Local_Authority_District_D + ';' + Local_Authority_District as LADGIS_LADCD
	FROM Public_Health.dbo.HES_IP
	WHERE
		GIS_Local_Authority_District_D <> Local_Authority_District
		AND
		(
			(GIS_Local_Authority_District_D in ('00FY', '37UB', '37UG', '37UF', '37UC', '37UE', '37UD', '37UJ')) OR
			(Local_Authority_District in ('E06000018', 'E07000170', 'E07000171', 'E07000172', 'E07000173', 'E07000174', 'E07000175', 'E07000176'))
		)
	GROUP BY
		GIS_Local_Authority_District_D
		, Local_Authority_District
	ORDER BY nRecords DESC
;

/**

Inspect record selection and tagging attributes e.g. gender, ageband

tagging AFs

*/


declare @datestart as datetime
declare @dateend as datetime

declare @fystart as varchar(4) ;
declare @fyend as varchar(4) ;

set @fystart = '2015' -- '2013' -- '2014' -- '2015'
set @fyend   = '2016' -- '2014' -- '2013' -- '2016'

--set @datestart = @fystart + '/03/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16
--set @datestart = @fystart + '/03/31'	;	set @dateend = @fystart + '/07/01' ; -- FY 2015/16 Q1
--set @datestart = @fystart + '/06/30'	;	set @dateend = @fystart + '/10/01' ; -- FY 2015/16 Q2
--set @datestart = @fystart + '/09/30'	;	set @dateend = @fyend   + '/01/01' ; -- FY 2015/16 Q3
set @datestart = @fystart + '/12/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16 Q4

/*

Main

 - cte_filter
 - cte_expand
 - cte_melt
 - cte_tag_af

*/

;
WITH
/*
Select fields of relevance from HES IP and filter on record status re: 
patient classification and episode status
*/
cte_ageadjust
AS (
	SELECT
		IP.Generated_Record_Identifier
		, IP.Age_at_Start_of_Episode_D
		, case
			when IP.Age_at_Start_of_Episode_D between 7001 and 7007 then 0
			else IP.Age_at_Start_of_Episode_D
		end as Age_at_Start_of_Episode_D__adjusted
		
		, IP.Gender
		, IP.Diagnosis_ICD_Concatenated_D
		
		, IP.Consultant_Episode_Number
		, IP.Episode_Status
		, IP.Patient_Classification
		
		, IP.Finished_Consultant_Episode
		
		FROM
			[Public_Health].[dbo].[HES_IP]	AS IP
			
		WHERE (IP.Finished_Consultant_Episode = 1) AND (IP.Consultant_Episode_Number = 1)
			AND (Age_at_Start_of_Episode_D > 7000)
			AND (Diagnosis_ICD_Concatenated_D like '%;P0[57]%')
) -- cte_ageadjust
,
cte_filter(GRID, GenderC, AgeBand_AA_Alt, Age_SYOA, xmlDiagPos)
AS
(
SELECT
	-- uid
	IP.Generated_Record_Identifier		AS [GRID]
	-- demographics
	, LEFT(ACGENDER.Description, 1)		AS [GenderC] -- MF
	, ABPH.Alcohol_Fraction_AgeBand		AS [AgeBand_AA_alt] -- axxyy | a75+
	, IP.Age_at_Start_of_Episode_D__adjusted	AS [Age_SYOA]
	-- clinical
	, CONVERT(xml
		, '<d><p>' + -- <diag><pos> etc
			replace(IP.Diagnosis_ICD_Concatenated_D, ';', '</p><p>') +
			'</p></d>'
	)									AS [xmlDiagPos]
	
	FROM 
		cte_ageadjust															AS IP
		
			LEFT JOIN [Shared_Reference].[dbo].[Age_Bands_Public_Health]		AS ABPH
				ON (
					(ABPH.[ESP_Year] = '2013') AND
					(IP.Age_at_Start_of_Episode_D__adjusted = ABPH.Age_Years)
				)
				
			LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]			AS ACGENDER
				ON (ACGENDER.Field_Name = 'gender' AND ACGENDER.Code = IP.Gender)
				
	WHERE
		(
			-- What - first (admission) episode and includes only finished episodes
			(IP.Consultant_Episode_Number = 1) AND
			(IP.Episode_Status = 3) AND
			-- Who - includes ordinary admissions (1), day cases (2) and mothers and babies (5)
			(IP.Patient_Classification IN ('1', '2', '5'))
		)
		AND (
			-- When - Events between dates specified
			(IP.Consultant_Episode_End_Date > @datestart) AND
			(IP.Consultant_Episode_End_Date < @dateend)
		)
		AND (
			-- who - aged between 0 and 120.  __adjusted has mapped [7001, 7007] to 0
			(IP.Age_at_Start_of_Episode_D__adjusted between 0 and 120)
		)
) -- cte_filter
SELECT TOP 100 * FROM cte_filter
;
GO

select *
	from
		--[Public_Health].[dbo].[HES_IP]	AS IP
		[ucs-bisqldev].[PHIIT].[dbo].tmpIB__PHIT_IP__201516__20180302
	where
		--IP.Generated_Record_Identifier = '504049179459'
		GRID = '504049179459'
;

select *
	from
		[Public_Health].[dbo].[HES_IP]	AS IP
	where
		NOT (IP.Diagnosis_ICD_1 is null) and
		NOT (IP.Diagnosis_ICD_Concatenated_D is null)