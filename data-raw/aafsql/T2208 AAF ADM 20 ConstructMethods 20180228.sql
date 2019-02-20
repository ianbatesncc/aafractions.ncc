/****** Script for SelectTopNRows command from SSMS  ******/

use Public_Health
;
GO

/*

alcohol-related (broad)

*/

;
WITH
cte_filter -- () -- GRID, icd10, pos, uid, af, [cause basis], aa_rank_1_highest)
AS (
	SELECT
		[GRID], [icd10], [pos], [uid], [af], [cause basis]
	FROM [PHIIT].[dbo].[tmpIB__PHIT_IP__201516]
	WHERE (af > 0)
 
 ) -- cte_filter
 
 , cte_rank
 AS
 (
	SELECT *
		, ROW_NUMBER() OVER(PARTITION BY GRID ORDER BY af DESC, pos ASC) AS [aa_rank_1_highest]
		FROM cte_filter
 
 ) -- cte_rank
 
 SELECT
	'alcohol-related (broad)'	AS [method]
	, GRID, icd10, uid, af, pos, [cause basis]
	FROM cte_rank
	WHERE ([aa_rank_1_highest] = 1)
	ORDER BY GRID
;

GO

/*

alcohol-related (narrow)

*/

;
WITH
cte_filter -- () -- GRID, icd10, pos, uid, af, [cause basis], aa_rank_1_highest)
AS (
	SELECT
		[GRID], [icd10], [pos], [uid], [af], [cause basis]
	FROM [PHIIT].[dbo].[tmpIB__PHIT_IP__201516]
	WHERE (
		(af > 0)
		AND
		(
			(pos = 1) OR ([cause basis] = 'external')
		)
	)
 
 ) -- cte_filter
 
 , cte_rank
 AS
 (
	SELECT *
		, ROW_NUMBER() OVER(PARTITION BY GRID ORDER BY af DESC, pos ASC) AS [aa_rank_1_highest]
		FROM cte_filter
 
 ) -- cte_rank
 
 SELECT
	'alcohol-related (narrow)'	AS [method]
	, GRID, icd10, uid, af, pos, [cause basis]
	FROM cte_rank
	WHERE (
		(pos = 1) OR ([aa_rank_1_highest] = 1)
	)
	ORDER BY GRID
;
GO

/*

alcohol-specific

*/

;
WITH
cte_filter -- () -- GRID, icd10, pos, uid, af, [cause basis], aa_rank_1_highest)
AS (
	SELECT
		[GRID], [icd10], [pos], [uid], [af], [cause basis]
	FROM [PHIIT].[dbo].[tmpIB__PHIT_IP__201516]
--	WHERE (af = 1.0)
	WHERE (af > 0.99)
 
 ) -- cte_filter
 
 , cte_rank
 AS
 (
	SELECT *
		, ROW_NUMBER() OVER(PARTITION BY GRID ORDER BY af DESC, pos ASC) AS [aa_rank_1_highest]
		FROM cte_filter
 
 ) -- cte_rank
 
 SELECT
	'alcohol-specific'	AS [method]
	, GRID, icd10, uid, af, pos, [cause basis]
	FROM cte_rank
	WHERE ([aa_rank_1_highest] = 1)
	ORDER BY GRID
;

GO