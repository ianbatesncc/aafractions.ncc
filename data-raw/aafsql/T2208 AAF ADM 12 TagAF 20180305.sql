/*
ALCOHOL ADMISSIONS QUERY (record level)

 - Tag each Record with condition and ag relevant arf
*/

use PHIIT;
GO

/*
Main

 - cte_grid
 - cte_filter_ip
 - cte_tag__age_gender
 - cte_join
 - cte_tag_af
*/
;
WITH
/*
Select fields of relevance from HES IP and filter on record status re:
patient classification and episode status
*/
cte_grid(GRID)
AS (
	SELECT GRID FROM [dbo].tmpIB__AA__PHIT_IP__melt
	GROUP BY GRID
)
,
cte_filter_ip(GRID, Age_SYOA__adj, Gender)
AS (
	SELECT
		IP.Generated_Record_Identifier				        AS GRID
		, CASE
			WHEN NOT IP.Age_at_Start_of_Episode_D IS NULL THEN
				CASE
					WHEN (IP.Age_at_Start_of_Episode_D > 7000) THEN 0
					ELSE IP.Age_at_Start_of_Episode_D
				END
			ELSE
				CASE
					WHEN (IP.Age_On_Admission > 7000) THEN 0
					ELSE IP.Age_On_Admission
				END
		END													AS Age_SYOA__adj
		, IP.Gender

		FROM
			[ucs-bisqldb].[Public_Health].[dbo].[HES_IP]	AS IP

			INNER JOIN cte_grid
				ON (IP.Generated_Record_Identifier = cte_grid.GRID)
)
,
cte_tag__age_gender(GRID, GenderC, Age_SYOA__adj, AgeBand_AA)
AS (
    SELECT
    	previous_cte.GRID
    	, LEFT(ACGENDER.Description, 1)			AS [GenderC]	-- MF
    	, previous_cte.Age_SYOA__adj
    	, ABPH.[Alcohol_Fraction_AgeBand]		AS [AgeBand_AA] -- axxyy | a75+

    	FROM
    		cte_filter_ip						AS previous_cte

			LEFT JOIN [ucs-bisqldb].[Shared_Reference].[dbo].[Age_Bands_Public_Health]
		                                        AS ABPH
				ON (
					(ABPH.[ESP_Year] = '2013') AND
					(ABPH.Age_Years = previous_cte.Age_SYOA__adj)
				)

			LEFT JOIN [ucs-bisqldb].[Shared_Reference].[dbo].[Administrative_Codes]
		                                        AS ACGENDER
				ON (
					(ACGENDER.Field_Name = 'gender') AND
					(ACGENDER.Code = previous_cte.Gender)
				)
)
,
/*
join IP (GRID, age, gender) to AF melt (GRID, uid, pos, icd10)
*/
cte_join(GRID, GenderC, Age_SYOA__adj, AgeBand_AA, icd10, pos, aa_uid)
AS (
    SELECT
    	PHIT_IP__MELT.GRID

    	, previous_cte.GenderC
    	, previous_cte.Age_SYOA__adj
    	, previous_cte.AgeBand_AA

    	, PHIT_IP__MELT.icd10
    	, PHIT_IP__MELT.pos
    	, PHIT_IP__MELT.aa_uid

    	FROM
    	    dbo.tmpIB__AA__PHIT_IP__melt		AS PHIT_IP__MELT
    		LEFT JOIN cte_tag__age_gender		AS previous_cte
    			ON (PHIT_IP__MELT.GRID = previous_cte.GRID)
)
,
/*
Tag on the alcohol related attributable fraction based on condition, age and gender
*/
cte_tag_af(GRID, icd10, pos, aa_uid, af, GenderC, Age_SYOA__adj, AgeBand_AA)
AS (
    SELECT
    	previous_cte.GRID

    	, previous_cte.icd10
    	, previous_cte.pos
    	, previous_cte.aa_uid

    	, LU_AAF_AG.[af]

    	, previous_cte.[GenderC]
    	, previous_cte.Age_SYOA__adj
    	, previous_cte.[AgeBand_AA]

    	FROM cte_join											AS previous_cte

		LEFT JOIN
			[ucs-bisqldev].[PHIIT].[dbo].[tmpIB__AA__aaf_ag]	AS LU_AAF_AG
				ON (
					(LU_AAF_AG.[analysis type] IN ('any', 'morb')) AND
					(previous_cte.[aa_uid] = LU_AAF_AG.[condition uid]) AND

					(previous_cte.[GenderC] = LU_AAF_AG.[gender]) AND
					(previous_cte.[AgeBand_AA] = LU_AAF_AG.[ageband aa alt])
				)
)
/*
Main - start the chain
*/
UPDATE tmpIB__AA__PHIT_IP__melt
	SET
		tmpIB__AA__PHIT_IP__melt.af = previous_cte.af
		, tmpIB__AA__PHIT_IP__melt.aa_gender = previous_cte.genderc
		, tmpIB__AA__PHIT_IP__melt.aa_agesyoa = previous_cte.Age_SYOA__adj
		, tmpIB__AA__PHIT_IP__melt.aa_ageband = previous_cte.ageband_aa

	FROM
		cte_tag_af		AS previous_cte

	WHERE
		(
			(tmpIB__AA__PHIT_IP__melt.GRID = previous_cte.GRID) AND
			(tmpIB__AA__PHIT_IP__melt.pos = previous_cte.pos)
		)
;
GO

/* Missing age or gender - mostly gender
*/

select COUNT(*) as nAFNULL from tmpIB__AA__PHIT_IP__melt
WHERE af is null
;
