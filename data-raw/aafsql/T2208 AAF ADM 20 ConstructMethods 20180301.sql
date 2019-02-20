USE [PHIIT]
GO

/****** Object:  Table [dbo].[tmpib__AA__PHIT_IP__aamethod]    Script Date: 03/01/2018 11:45:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

/* Clear table or create
*/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tmpIB__AA__PHIT_IP__aamethod]') AND type in (N'U'))
	DELETE FROM [dbo].[tmpIB__AA__PHIT_IP__aamethod]
ELSE
	BEGIN
	CREATE TABLE [dbo].tmpIB__AA__PHIT_IP__aamethod(
		[aa_method] [varchar](48) NULL
		, [GRID] [bigint] NULL
		, [icd10] [varchar](4) NULL
		, [pos] [smallint] NULL
		, [aa_uid] [smallint] NULL
		, [aa_gender]	[varchar](4)		NULL
		, [aa_agesyoa]	[smallint]			NULL
		, [aa_ageband]	[varchar](8)		NULL
		, [af] [decimal](10,2) NULL
	) ON [PRIMARY]
	;
	CREATE UNIQUE CLUSTERED INDEX [PK_aamethod_grid] ON [dbo].[tmpIB__AA__PHIT_IP__aamethod]
	(
		[aa_method]	ASC
		, [GRID]	ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	END
GO

SET ANSI_PADDING OFF
GO


USE [PHIIT]
GO

/* some inserts
*/

/*

alcohol-related (broad)

- cte_filter
- cte_rank
- SQL: INSERT INTO [dbo].[tmpib__AA__PHIT_IP__aamethod] ... WHERE [aa_rank_1_highest] = 1

*/

;
WITH
cte_filter -- ([GRID], [icd10], [pos], [aa_uid], aa_gender, aa_agesyoa, aa_ageband, [af])
AS (
	SELECT
		* -- [GRID], [icd10], [pos], [aa_uid], aa_gender, aa_agesyoa, aa_ageband, [af]
	FROM [PHIIT].[dbo].[tmpIB__AA__PHIT_IP__melt]
	WHERE (af > 0)

) -- /cte_filter
,
cte_rank -- ([GRID], [icd10], [pos], [aa_uid], aa_gender, aa_agesyoa, aa_ageband, [af], [aa_rank_1_highest])
AS (
SELECT *
	, ROW_NUMBER() OVER(PARTITION BY GRID ORDER BY af DESC, pos ASC) AS [aa_rank_1_highest]
	FROM cte_filter

) -- /cte_rank
INSERT INTO [dbo].[tmpIB__AA__PHIT_IP__aamethod]
SELECT
	'alcohol-related (broad)'	AS [method]
	, GRID, icd10, pos, aa_uid, aa_gender, aa_agesyoa, aa_ageband, af
	FROM cte_rank
	WHERE ([aa_rank_1_highest] = 1)
;

GO


/*

 alcohol-related (narrow)

 - Consider primary code as princicpal unless there is a secondary code.
 - IF there is BOTH a primary condition AND a secondary external condition, take HIGHEST AF as principal.
  - IGNORE [cause attribution] and filter on icd10 like [VWXY] - miscalassified some external as individidual.
   - AHA! Actually choose the right records.  Oops.

- cte_filter
- cte_sort_rank
- cte_promote
- cte_rank_of_rank
- SQL: INSERT INTO [dbo].[tmpib__AA__PHIT_IP__aamethod] ... WHERE [aa_rank_of_rank_1_highest] = 1

*/

;

-- current

-- narrow pos1override:
-- rank by af then pos, promote pos 1 to rank 1 and re-rank.
--
-- Necessary as (pos == 1 cause) should override any (external cause pos > 1)
-- even if (external cause af) > (pos == 1 cause af).
--
-- narrow phe:
-- HOWEVER NOT in PHE SQL ...

WITH
cte_filter -- (GRID, icd10, pos, aa_uid, aa_gender, aa_agesyoa, aa_ageband, af)
AS (
	SELECT * --[GRID], [icd10], [pos], [aa_uid], aa_gender, aa_agesyoa, aa_ageband, [af]
			FROM [PHIIT].[dbo].[tmpib__AA__PHIT_IP__melt]
			WHERE ( (af > 0) AND ((pos = 1) OR (icd10 like '[VWXY]%')) )
) -- /cte_filter
,
cte_sort_rank --(GRID, icd10, pos, aa_uid, aa_gender, aa_agesyoa, aa_ageband, af, [aa_rank_1_highest])
AS (
	SELECT *
		, ROW_NUMBER() OVER(PARTITION BY GRID ORDER BY af DESC, pos ASC) AS [aa_rank_1_highest]
		FROM cte_filter
) -- /cte_sort_rank
,
cte_promote -- ([GRID], [icd10], [pos], [aa_uid], aa_gender, aa_agesyoa, aa_ageband, [af], [aa_rank_1_highest])
AS (
	SELECT * -- [GRID], [icd10], [pos], [aa_uid], aa_gender, aa_agesyoa, aa_ageband, [af]
		, case pos
			when 1 then 1
			else [aa_rank_1_highest] + 1
		end as [aa_rank_1_highest__adj]
		FROM cte_sort_rank
) -- /cte_promote
/* need an extra rank of rank */
,
cte_rank_of_rank -- ([GRID], [icd10], [pos], [aa_uid], aa_gender, aa_agesyoa, aa_ageband, [af], [aa_rank_1_highest], [aa_rank_of_rank_1_highest])
AS (
	SELECT *
		, ROW_NUMBER() OVER(PARTITION BY GRID ORDER BY [aa_rank_1_highest__adj] ASC) AS [aa_rank_of_rank_1_highest]
		FROM cte_promote
) -- /cte_rank_of_rank
INSERT INTO [dbo].[tmpIB__AA__PHIT_IP__aamethod]
--SELECT * FROM cte_rank_of_rank
SELECT
	'alcohol-related (narrow) pos1override'	AS [method]
	, GRID, icd10, pos, aa_uid, aa_gender, aa_agesyoa, aa_ageband, af
	FROM cte_rank_of_rank
	WHERE ([aa_rank_of_rank_1_highest] = 1)

UNION ALL

SELECT
	'alcohol-related (narrow) phe'	AS [method]
	, GRID, icd10, pos, aa_uid, aa_gender, aa_agesyoa, aa_ageband, af
	FROM cte_sort_rank
	WHERE ([aa_rank_1_highest] = 1)
;
GO

/*

alcohol-specific

- cte_filter
- cte_rank
- SQL: INSERT INTO [dbo].[tmpib__AA__PHIT_IP__aamethod] ... WHERE [aa_rank_1_highest] = 1

*/

;
WITH
cte_filter -- () -- GRID, icd10, pos, uid, af, aa_rank_1_highest)
AS (
	SELECT * -- [GRID], [icd10], [pos], [aa_uid], aa_gender, aa_agesyoa, aa_ageband, [af]
	FROM [PHIIT].[dbo].[tmpib__AA__PHIT_IP__melt]
--	WHERE (af = 1.0)
	WHERE (af > 0.99)

) -- /cte_filter
,
cte_rank
AS (
	SELECT *
		, ROW_NUMBER() OVER(PARTITION BY GRID ORDER BY af DESC, pos ASC) AS [aa_rank_1_highest]
		FROM cte_filter

) -- /cte_rank
INSERT INTO [dbo].[tmpib__AA__PHIT_IP__aamethod]
SELECT
	'alcohol-specific'	AS [aa_method]
	, GRID, icd10, pos, aa_uid, aa_gender, aa_agesyoa, aa_ageband, af
	FROM cte_rank
	WHERE ([aa_rank_1_highest] = 1)
;

GO

/* inspect top 100 */

SELECT top 10 * FROM [tmpib__AA__PHIT_IP__aamethod]
;

/*

pivot to inspect

*/

SELECT [aa_method], sum(af) as nAttrib
	FROM [tmpib__AA__PHIT_IP__aamethod]
	GROUP BY [aa_method]
;
GO

SELECT
	GRID, [alcohol-related (broad)], [alcohol-related (narrow) phe], [alcohol-related (narrow) pos1override], [alcohol-specific]
	FROM (
		SELECT
			[aa_method]
			, GRID
			--, icd10
			, convert(decimal(10,2), af) as af
			from [tmpib__AA__PHIT_IP__aamethod]
	) as sourcet
	PIVOT
	(
		--max([icd10])
		max([af])
		for [aa_method] in ([alcohol-related (broad)], [alcohol-related (narrow) phe], [alcohol-related (narrow) pos1override], [alcohol-specific])
	) as pvt
	WHERE
	(
		([alcohol-related (narrow) phe] <> [alcohol-related (narrow) pos1override])
	)
;
GO



--
-- Older versions - NOT working
--

/*

alcohol-related (narrow) orig

 - Consider priamry code as princicpal unless there is a secondary code.  That is select primary over secondary.
 - IF there is BOTH a priamy ar condaiton AND a secondary external condition, take PRIMARY as principal.

 alcohol-related (narrow) liberal

 - Consider priamry code as princicpal unless there is a secondary code.
 - IF there is BOTH a priamy ar condaiton AND a secondary external condition, take HIGHEST AF as principal.
 - Primary aa or Secondary external just a selection method - base af on any alcohol related condition.

*/


/*
-- orig

WITH
cte_filter -- () -- GRID, icd10, pos, uid, af, [cause basis], aa_rank_1_highest)
AS (
	SELECT [GRID], [icd10], [pos], [uid], [af], [cause basis]
		FROM [PHIIT].[dbo].[tmpib__AA__PHIT_IP__201516]
		WHERE ( (af > 0) AND ((pos = 1) OR ([cause basis] = 'external')) )
) -- /cte_filter
,
cte_rank
AS (
	SELECT *
		, ROW_NUMBER() OVER(PARTITION BY GRID ORDER BY af DESC, pos ASC) AS [aa_rank_1_highest]
		FROM cte_filter
) -- /cte_rank
,
cte_rank_amended
AS (
	SELECT
		[GRID], [icd10], [pos], [uid], [af], [cause basis]
		, case pos
			when 1 then 1
			else [aa_rank_1_highest] + 1
		end as [aa_rank_1_highest]
		FROM cte_rank
) -- /cte_rank_amended
INSERT INTO [dbo].[tmpib__AA__PHIT_IP__aamethod]
SELECT
	'alcohol-related (narrow) orig'	AS [method]
	, GRID, icd10, pos, uid, af, [cause basis]
	FROM cte_rank_amended
	WHERE ([aa_rank_1_highest] = 1)
;
--GO


-- liberal
;
WITH
cte_prefilter -- () -- GRID
AS (
	/* Choose only Records that match prim diag aa OR Sec diag aaexternal */
	SELECT [GRID]
		FROM [ucs-bisqldev].[PHIIT].[dbo].[tmpib__AA__PHIT_IP__201516]
		WHERE ((af > 0) AND ((pos = 1) OR ([cause basis] = 'external')))
		GROUP BY [GRID]
) -- /cte_prefilter
,
cte_filter -- () -- GRID, icd10, pos, uid, af, [cause basis])
AS (
	SELECT
		PHIT_IP.[GRID], [icd10], [pos], [uid], [af], [cause basis]
	FROM [ucs-bisqldev].[PHIIT].[dbo].[tmpib__AA__PHIT_IP__201516]		AS PHIT_IP
		INNER JOIN cte_prefilter
			ON (PHIT_IP.GRID = cte_prefilter.GRID)

) -- /cte_filter
,
cte_rank -- () -- GRID, icd10, pos, uid, af, [cause basis], aa_rank_1_highest
AS (
	SELECT *
		, ROW_NUMBER() OVER(PARTITION BY GRID ORDER BY af DESC, pos ASC) AS [aa_rank_1_highest]
		FROM cte_filter

) -- /cte_rank
INSERT INTO [dbo].[tmpib__AA__PHIT_IP__aamethod]
SELECT
	'alcohol-related (narrow) liberal'	AS [method]
	, GRID, icd10, pos, uid, af, [cause basis]
	FROM cte_rank
	WHERE ([aa_rank_1_highest] = 1)
;
--GO

*/
