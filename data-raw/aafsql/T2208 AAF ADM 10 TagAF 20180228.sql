/*

ALCOHOL ADMISSIONS QUERY (record level)

 - Tag each Record with condition and ag relevant arf

*/

use Public_Health
;
GO

IF OBJECT_ID('tempdb..#cte_expand') IS NOT NULL
BEGIN
DROP TABLE #cte_expand
END


/*

1Q - 3m28s - 63912 rows

... aagh NOW 7000 rows - 12 mins ... what's happened ..

*/

/*

Set date range

- just to limit size of query

*/

declare @datestart as datetime
declare @dateend as datetime

declare @fystart as varchar(4) ;
declare @fyend as varchar(4) ;

set @fystart = '2015' -- '2013' -- '2014' -- '2015'
set @fyend   = '2016' -- '2014' -- '2013' -- '2016'

set @datestart = @fystart + '/03/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16
--set @datestart = @fystart + '/03/31'	;	set @dateend = @fystart + '/07/01' ; -- FY 2015/16 Q1
--set @datestart = @fystart + '/06/30'	;	set @dateend = @fystart + '/10/01' ; -- FY 2015/16 Q2
--set @datestart = @fystart + '/09/30'	;	set @dateend = @fyend   + '/01/01' ; -- FY 2015/16 Q3
--set @datestart = @fystart + '/12/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16 Q4

/*

Main
 
 - cte_ageadjust
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
cte_adjust_age_diagconcat__filter_date_record(GRID, Age_SYOA_adj, Gender, Diag_Concat_adj)
AS (
	SELECT
		IP.Generated_Record_Identifier			AS GRID
		--, IP.Age_at_Start_of_Episode_D			AS Age_SYOA
		, case
			when IP.Age_at_Start_of_Episode_D between 7001 and 7007 then 0
			else IP.Age_at_Start_of_Episode_D
		end										AS Age_at_Start_of_Episode_D__adjusted
		, IP.Gender
		, case
			when IP.Diagnosis_ICD_Concatenated_D IS null then IP.Diagnosis_ICD_1 -- + ';'
			else replace(Diagnosis_ICD_Concatenated_D + ';', ';;', '')
		end										AS Diagnosis_ICD_Concatenated_D__adjusted
		
		FROM
			[Public_Health].[dbo].[HES_IP]	AS IP
			
		WHERE
		(
			-- When - Events between dates specified
			(IP.Consultant_Episode_End_Date > @datestart) AND
			(IP.Consultant_Episode_End_Date < @dateend)
		)
		AND
		(
			-- What - first (admission) episode and includes only finished episodes
			(IP.Consultant_Episode_Number = 1) AND
			(IP.Episode_Status = 3) AND
			-- Who - includes ordinary admissions (1), day cases (2) and mothers and babies (5)
			(IP.Patient_Classification IN ('1', '2', '5'))
		)

			
) -- /cte_adjust_age_diagconcat__filter_date_record
--select top 100 * from cte_adjust_age_diagconcat__filter_date_record
--select COUNT(*) as nRecords FROM cte_adjust_age_diagconcat__filter_date_record
,
cte_tag__age_gender__expand_diag(GRID, GenderC, AgeBand_AA_Alt, xmlDiagPos)
AS (
SELECT /* Top 4000 */
	-- uid
	previous_cte.GRID
	-- demographics
	, LEFT(ACGENDER.Description, 1)					AS [GenderC] -- MF
	, ABPH.Alcohol_Fraction_AgeBand					AS [AgeBand_AA_alt] -- axxyy | a75+
	--, previous_cte.Age_at_Start_of_Episode_D__adjusted	AS [Age_SYOA]
	-- clinical
	, CONVERT(xml
		, '<d><p>' + -- <diag><pos> etc
			replace(previous_cte.Diag_Concat_adj, ';', '</p><p>') +
			'</p></d>'
	)												AS [xmlDiagPos]
	
	FROM 
		cte_adjust_age_diagconcat__filter_date_record							AS previous_cte
		
			LEFT JOIN [Shared_Reference].[dbo].[Age_Bands_Public_Health]		AS ABPH
--			LEFT JOIN [ucs-bisqldev].[PHIIT].[dbo].[Age_Bands_Public_Health]		AS ABPH
				ON (
					(ABPH.[ESP_Year] = '2013') AND
					(ABPH.Age_Years = previous_cte.Age_SYOA_adj)
				)
				
			LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]			AS ACGENDER
--			LEFT JOIN [ucs-bisqldev].[PHIIT].[dbo].[Administrative_Codes]			AS ACGENDER
				ON (
					(ACGENDER.Field_Name = 'gender') AND
					(ACGENDER.Code = previous_cte.Gender)
				)
				
) -- /cte_tag__age_gender__expand_diag
--select top 100 * from cte_tag__age_gender__expand_diag
--select COUNT(*) as nRecords FROM cte_tag__age_gender__expand_diag
,
/*
split diagnosis concatenated field into multiple fields
*/
cte_expand(GRID, GenderC, AgeBand_AA_Alt
--	, Diag01, Diag02, Diag03, Diag04, Diag05, Diag06, Diag07, Diag08, Diag09, Diag10
--	, Diag11, Diag12, Diag13, Diag14, Diag15, Diag16, Diag17, Diag18, Diag19, Diag20
	, [01], [02], [03], [04], [05], [06], [07], [08], [09], [10]
	, [11], [12], [13], [14], [15], [16], [17], [18], [19], [20]
)
AS (
	SELECT
		previous_cte.GRID
		, previous_cte.[GenderC]
		, previous_cte.[AgeBand_AA_Alt]
		-- implicit trim to four characters
		, xmlDiagPos.value('/d[1]/p[1]',  'varchar(4)') AS [01] -- [Diag01]
		, xmlDiagPos.value('/d[1]/p[2]',  'varchar(4)') AS [02] -- [Diag02]
		, xmlDiagPos.value('/d[1]/p[3]',  'varchar(4)') AS [03] -- [Diag03]
		, xmlDiagPos.value('/d[1]/p[4]',  'varchar(4)') AS [04] -- [Diag04]
		, xmlDiagPos.value('/d[1]/p[5]',  'varchar(4)') AS [05] -- [Diag05]
		, xmlDiagPos.value('/d[1]/p[6]',  'varchar(4)') AS [06] -- [Diag06]
		, xmlDiagPos.value('/d[1]/p[7]',  'varchar(4)') AS [07] -- [Diag07]
		, xmlDiagPos.value('/d[1]/p[8]',  'varchar(4)') AS [08] -- [Diag08]
		, xmlDiagPos.value('/d[1]/p[9]',  'varchar(4)') AS [09] -- [Diag09]
		, xmlDiagPos.value('/d[1]/p[10]', 'varchar(4)') AS [10] -- [Diag10]
		, xmlDiagPos.value('/d[1]/p[11]', 'varchar(4)') AS [11] -- [Diag11]
		, xmlDiagPos.value('/d[1]/p[12]', 'varchar(4)') AS [12] -- [Diag12]
		, xmlDiagPos.value('/d[1]/p[13]', 'varchar(4)') AS [13] -- [Diag13]
		, xmlDiagPos.value('/d[1]/p[14]', 'varchar(4)') AS [14] -- [Diag14]
		, xmlDiagPos.value('/d[1]/p[15]', 'varchar(4)') AS [15] -- [Diag15]
		, xmlDiagPos.value('/d[1]/p[16]', 'varchar(4)') AS [16] -- [Diag16]
		, xmlDiagPos.value('/d[1]/p[17]', 'varchar(4)') AS [17] -- [Diag17]
		, xmlDiagPos.value('/d[1]/p[18]', 'varchar(4)') AS [18] -- [Diag18]
		, xmlDiagPos.value('/d[1]/p[19]', 'varchar(4)') AS [19] -- [Diag19]
		, xmlDiagPos.value('/d[1]/p[20]', 'varchar(4)') AS [20] -- [Diag20]
		
		FROM cte_tag__age_gender__expand_diag		AS previous_cte
) -- /cte_expand
--select top 100 * from cte_expand
--select COUNT(*) as nRecords FROM cte_expand
/*
SELECT *
	into #cte_expand
	FROM cte_expand
;
GO
CREATE INDEX IX_#cte_expand ON #cte_expand(GRID, GenderC, AgeBand_AA_Alt)
;

;
WITH
cte_expand
AS (
	SELECT * FROM #cte_expand
)
*/
,
/*
melt diagnosis fields onto (icd10code, value)
*/
cte_melt(GRID, icd10, pos, GenderC, AgeBand_AA_Alt)
AS (
SELECT
	GRID
--	, LEFT(unpvt.icd10, 4) as [icd10]
	, unpvt.icd10

--	, CONVERT(integer, unpvt.Diags)	AS [pos]
	, unpvt.Diags as [pos]

	, unpvt.[GenderC]
	, unpvt.[AgeBand_AA_Alt]
	
	FROM cte_expand		AS previous_cte
UNPIVOT
	(icd10 for Diags IN (
--		  [Diag01], [Diag02], [Diag03], [Diag04], [Diag05], [Diag06], [Diag07], [Diag08], [Diag09], [Diag10]
--		, [Diag11], [Diag12], [Diag13], [Diag14], [Diag15], [Diag16], [Diag17], [Diag18], [Diag19], [Diag20]
		  [01], [02], [03], [04], [05], [06], [07], [08], [09], [10]
		, [11], [12], [13], [14], [15], [16], [17], [18], [19], [20]
		)
	) AS unpvt
) -- /cte_melt
--select top 100 * from cte_melt
--select COUNT(*) as nRecords FROM cte_melt
,
/*
Tag on the alcohol related attributable fraction based on condition, age and gender
*/
cte_tag_af(GRID, icd10, pos, uid, af, [cause basis])
AS (
SELECT
	previous_cte.GRID
	, previous_cte.icd10
	, previous_cte.pos
	, LU_UID_ICD.[uid]
	, LU_AAF_AG.[af]
	, LU_AAC.[cause basis]
	
	FROM cte_melt														AS previous_cte
	
		LEFT JOIN
			[ucs-bisqldev].[PHIIT].[dbo].[tmpIB__lu__uid_icd]			AS LU_UID_ICD
				ON (previous_cte.icd10 = LU_UID_ICD.codes)

		LEFT JOIN
			[ucs-bisqldev].[PHIIT].[dbo].[tmpIB__aac]					AS LU_AAC
				ON (LU_UID_ICD.[uid] = LU_AAC.[condition uid])
				
		LEFT JOIN
			[ucs-bisqldev].[PHIIT].[dbo].[tmpIB__aaf_ag]				AS LU_AAF_AG
				ON (
					(LU_AAF_AG.[analysis type] IN ('any', 'morb')) AND
					(LU_UID_ICD.[uid] = LU_AAF_AG.[condition uid]) AND
					
					(previous_cte.[GenderC] = LU_AAF_AG.[gender]) AND
					(previous_cte.[AgeBand_AA_Alt] = LU_AAF_AG.[ageband aa alt])
				)

		WHERE
			(NOT LU_UID_ICD.uid IS NULL) AND
			(NOT LU_AAF_AG.af IS NULL)
	
) -- /cte_tag_af
--select top 100 * from cte_tag_af
/*
Main - start the chain
*/
SELECT * FROM cte_tag_af
--	ORDER BY GRID ASC, af DESC, pos ASC
;


/*  Performance

329,000 rows in financial year match Record selection.

 * Using [Diagxx] string, no conversion to int

1000 cast rows - 506 returned - 15s, 16s

* Using [xx] string with conversion

1000 cast rows - 506 returned - 16s
4000 ... 3103 rows ... 1m34s
4000 ... 2763 rows ... 53s

400,000 ... 100 min ... 1h40m ... hmm

... 814 returned in 1m20s ...
... 1400 in 2m

... 262,630 rows returned in 1h34m

*/