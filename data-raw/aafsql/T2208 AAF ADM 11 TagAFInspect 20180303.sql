/*

ALCOHOL ADMISSIONS QUERY (record level)

 - Split diag_concat into separate rows
 - tag on relevant AA condition
 - store in tmpIB__AA__PHIT_IP__melt

*/

/*

1Q - 3m28s - 63912 rows
20180625: 1Y - 7m14s - 263145 rows 

... aagh NOW 7000 rows - 12 mins ... what's happened ..

*/

/*

storage

*/

USE [PHIIT]
GO

/****** Object:  Table [dbo].[tmpIB__PHIT_IP__aamethod]    Script Date: 03/01/2018 11:45:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

/* Clear table or create
*/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tmpIB__AA__PHIT_IP__melt]') AND type in (N'U'))
	DELETE FROM [dbo].[tmpIB__AA__PHIT_IP__melt]
ELSE
	BEGIN
	CREATE TABLE [dbo].[tmpIB__AA__PHIT_IP__melt](
		[GRID]			[bigint]			NULL
		, [icd10]		[varchar](4)		NULL
		, [pos]			[smallint]			NULL
		, [aa_uid]		[smallint]			NULL
		, [aa_gender]	[varchar](4)		NULL
		, [aa_agesyoa]	[smallint]			NULL
		, [aa_ageband]	[varchar](8)		NULL
		, af			[decimal](10,2)		NULL
	) ON [PRIMARY]
	;
	CREATE UNIQUE CLUSTERED INDEX [PK_grid_pos] ON [dbo].[tmpIB__AA__PHIT_IP__melt]
	(
		[GRID]	ASC
		, [pos] DESC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	END
GO

--SET ANSI_PADDING OFF
GO


/*

Set date range

- just to limit size of query

*/

declare @datestart as datetime
declare @dateend as datetime

declare @fystart as varchar(4) ;
declare @fyend as varchar(4) ;

--set @fystart = '2015' -- '2013' -- '2014' -- '2015'
--set @fystart = '2013' -- '2013' -- '2014' -- '2015'
set @fystart = '2015' -- '2013' -- '2014' -- '2015'
set @fyend   = '2016' -- '2014' -- '2013' -- '2016'

--set @fystart = '2016' -- '2013' -- '2014' -- '2015'
--set @fyend   = '2017' -- '2014' -- '2013' -- '2016'

set @datestart = @fystart + '/03/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16
--set @datestart = @fystart + '/03/31'	;	set @dateend = @fystart + '/07/01' ; -- FY 2015/16 Q1
--set @datestart = @fystart + '/06/30'	;	set @dateend = @fystart + '/10/01' ; -- FY 2015/16 Q2
--set @datestart = @fystart + '/09/30'	;	set @dateend = @fyend   + '/01/01' ; -- FY 2015/16 Q3
--set @datestart = @fystart + '/12/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16 Q4

/*

Main
 
 - cte_select
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
cte_select(GRID, Diag_Concat_adj)
AS (
	SELECT
		IP.Generated_Record_Identifier			AS GRID
		, case
			when IP.Diagnosis_ICD_Concatenated_D IS null then IP.Diagnosis_ICD_1 -- + ';'
			else replace(Diagnosis_ICD_Concatenated_D + ';', ';;', '')
		end										AS Diag_Concat_adj
		
		FROM
			[ucs-bisqldb].[Public_Health].[dbo].[HES_IP]	AS IP
			
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

			
) -- /cte_select
--select top 100 * from cte_select
--select COUNT(*) as nRecords FROM cte_select
,
cte_expand_diag(GRID, xmlDiagPos)
AS (
SELECT /* Top 4000 */
	-- uid
	previous_cte.GRID
	-- clinical
	, CONVERT(xml
		, '<d>' + -- <diag><pos> etc
			replace(previous_cte.Diag_Concat_adj, ';', '</d><d>') +
			'</d>'
	)												AS [xmlDiagPos]
	
	FROM 
		cte_select							AS previous_cte
		
) -- /cte_expand_diag
--select top 100 * from cte_expand_diag
--select COUNT(*) as nRecords FROM cte_expand_diag
,
/*
split diagnosis concatenated field into multiple fields
*/
cte_expand(GRID
	, [01], [02], [03], [04], [05], [06], [07], [08], [09], [10]
	, [11], [12], [13], [14], [15], [16], [17], [18], [19], [20]
)
AS (
	SELECT
		previous_cte.GRID
		-- explicit trim to four characters
		, xmlDiagPos.value('/d[1]',  'varchar(4)') AS [01] -- [Diag01]
		, xmlDiagPos.value('/d[2]',  'varchar(4)') AS [02] -- [Diag02]
		, xmlDiagPos.value('/d[3]',  'varchar(4)') AS [03] -- [Diag03]
		, xmlDiagPos.value('/d[4]',  'varchar(4)') AS [04] -- [Diag04]
		, xmlDiagPos.value('/d[5]',  'varchar(4)') AS [05] -- [Diag05]
		, xmlDiagPos.value('/d[6]',  'varchar(4)') AS [06] -- [Diag06]
		, xmlDiagPos.value('/d[7]',  'varchar(4)') AS [07] -- [Diag07]
		, xmlDiagPos.value('/d[8]',  'varchar(4)') AS [08] -- [Diag08]
		, xmlDiagPos.value('/d[9]',  'varchar(4)') AS [09] -- [Diag09]
		, xmlDiagPos.value('/d[10]', 'varchar(4)') AS [10] -- [Diag10]
		, xmlDiagPos.value('/d[11]', 'varchar(4)') AS [11] -- [Diag11]
		, xmlDiagPos.value('/d[12]', 'varchar(4)') AS [12] -- [Diag12]
		, xmlDiagPos.value('/d[13]', 'varchar(4)') AS [13] -- [Diag13]
		, xmlDiagPos.value('/d[14]', 'varchar(4)') AS [14] -- [Diag14]
		, xmlDiagPos.value('/d[15]', 'varchar(4)') AS [15] -- [Diag15]
		, xmlDiagPos.value('/d[16]', 'varchar(4)') AS [16] -- [Diag16]
		, xmlDiagPos.value('/d[17]', 'varchar(4)') AS [17] -- [Diag17]
		, xmlDiagPos.value('/d[18]', 'varchar(4)') AS [18] -- [Diag18]
		, xmlDiagPos.value('/d[19]', 'varchar(4)') AS [19] -- [Diag19]
		, xmlDiagPos.value('/d[20]', 'varchar(4)') AS [20] -- [Diag20]
		
		FROM cte_expand_diag		AS previous_cte
) -- /cte_expand
--select top 100 * from cte_expand
--select COUNT(*) as nRecords FROM cte_expand
--select * FROM cte_expand
,
/*
melt diagnosis fields onto (icd10code, value)
*/
cte_melt(GRID, icd10, pos)
AS (
SELECT
	GRID
	, unpvt.icd10

	, CONVERT(integer, unpvt.Diags)	AS [pos]
--	, unpvt.Diags as [pos]

	FROM cte_expand		AS previous_cte
UNPIVOT
	(icd10 for Diags IN (
		  [01], [02], [03], [04], [05], [06], [07], [08], [09], [10]
		, [11], [12], [13], [14], [15], [16], [17], [18], [19], [20]
		)
	) AS unpvt
) -- /cte_melt
--select top 100 * from cte_melt
--select COUNT(*) as nRecords FROM cte_melt
,
cte_inspect(GRID, icd10, pos, aa_uid)
AS
(
SELECT
	GRID, icd10, pos, LU_UID_ICD.[uid] AS [aa_uid] --previous_cte.icd10
	FROM cte_melt														AS previous_cte
		LEFT JOIN [ucs-bisqldev].[PHIIT].[dbo].[tmpIB__AA__lu__uid_icd]	AS LU_UID_ICD
			ON (previous_cte.icd10 = LU_UID_ICD.codes)

	WHERE
		(NOT LU_UID_ICD.[uid] IS NULL)
)
--select top 100 * from cte_inspect
INSERT INTO [PHIIT].dbo.tmpIB__AA__PHIT_IP__melt
SELECT -- Top 100
	GRID, icd10, pos, aa_uid, NULL, NULL, NULL, NULL
	FROM cte_inspect
;

/*

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
	, LU_AF_AG.[af]
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


2018/05/03

49960 in 1m35s ...

731138 rows in 19m02s (three FYs 2013/14, 2014/15, 2015/16)
731138 rows in 18m40s (three FYs 2013/14, 2014/15, 2015/16)



*/

*/

/*

SELECT 'tmpIB__PHIT_IP__201516' as tbl, COUNT(*) as n FROM [ucs-bisqldev].PHIIT.dbo.tmpIB__PHIT_IP__201516
UNION ALL
SELECT 'tmpIB__PHIT_IP__201516__20180302' as tbl, COUNT(*) as n FROM [ucs-bisqldev].PHIIT.dbo.tmpIB__PHIT_IP__201516__20180302
;

GO

DELETE FROM [ucs-bisqldev].PHIIT.dbo.tmpIB__PHIT_IP__201516 ;
GO

INSERT INTO [ucs-bisqldev].PHIIT.dbo.tmpIB__PHIT_IP__201516
SELECT * FROM [ucs-bisqldev].PHIIT.dbo.tmpIB__PHIT_IP__201516__20180302 ;
GO

*/