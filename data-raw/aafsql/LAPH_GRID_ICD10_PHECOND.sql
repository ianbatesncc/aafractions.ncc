/****** Script for SelectTopNRows command from SSMS  ******/

/*
SELECT [HES_Identifier_Encrypted]
      ,[Generated_Record_Identifier]
      --,[Age_31Aug]
      --,[Area_Team_GP_Practice]
      --,[Area_Team_Residence]
      --,[Area_Team_Treatment]
      --,[Commissioning_Region_GP_Practice]
      --,[Commissioning_Region_Residence]
      --,[Commissioning_Region_Treatment]
      ,[Principal_Alcohol_Related_Diagnosis]
      ,[Principal_Alcohol_Related_Fraction]
      --,[Age_Days]
      --,[Age_Weeks]
      --,[Age_Conception]
      ,[Financial_Year_D]
  FROM [Public_Health].[dbo].[LAPH_IP]
  WHERE
	NOT [Principal_Alcohol_Related_Diagnosis] IS NULL
	
	AND
	
	Financial_Year_D in ('1516', '1617', '1718')
	;
	
	
SELECT 
	COUNT(*) as nEvents
	,[Financial_Year_D]
	FROM [Public_Health].[dbo].[LAPH_IP]
	WHERE
		NOT [Principal_Alcohol_Related_Diagnosis] IS NULL
	GROUP BY
		[Financial_Year_D]
;
*/

;
WITH
cte_group AS
(
SELECT 
	COUNT(*) as nEvents
	,[Principal_Alcohol_Related_Diagnosis]	--AS ICD10_Diag

	FROM [Public_Health].[dbo].[LAPH_IP]
	
	WHERE
		NOT [Principal_Alcohol_Related_Diagnosis] IS NULL
	GROUP BY
		[Principal_Alcohol_Related_Diagnosis]
)
, cte_tag AS
(
SELECT 
	SUM(nEvents) as nEvents
	, cte_prev.[Principal_Alcohol_Related_Diagnosis]	--AS ICD10_Diag
	, CC_AA.[Description]					AS ICD10_Desc
	, CC_AA.[Chapter]						AS ICD10_Chapter
	, CC_AA.[Group]							AS ICD10_Group
	, AA_DIAG_COND.uid						AS aa_cid
	, AA_COND.[condition cat1]
	, AA_COND.[condition cat2]
	, AA_COND.[condition desc]
	, AA_COND.[condition attribution]
	, AA_COND.[cause basis]
	, AA_COND.[icd codes]
	
	FROM cte_group AS cte_prev
	
	LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes]			AS CC_AA
        ON (CC_AA.Code = cte_prev.[Principal_Alcohol_Related_Diagnosis] AND CC_AA.Field_Name = 'Diagnosis_ICD')
        
	LEFT JOIN [ucs-bisqldev].PHIIT.dbo.tmpIB__AA__lu__uid_icd		AS AA_DIAG_COND
		ON (AA_DIAG_COND.codes = cte_prev.[Principal_Alcohol_Related_Diagnosis])
		
	LEFT JOIN [ucs-bisqldev].PHIIT.dbo.tmpIB__AA__aac				AS AA_COND
		ON (AA_COND.[condition uid] = AA_DIAG_COND.uid)

	WHERE
		NOT [Principal_Alcohol_Related_Diagnosis] IS NULL
	GROUP BY
		cte_prev.[Principal_Alcohol_Related_Diagnosis]
		, CC_AA.[Description]
		, CC_AA.[Chapter]
		, CC_AA.[Group]
		, AA_DIAG_COND.uid
		, AA_COND.[condition cat1]
		, AA_COND.[condition cat2]
		, AA_COND.[condition desc]
		, AA_COND.[condition attribution]
		, AA_COND.[cause basis]
		, AA_COND.[icd codes]
)
SELECT *
	FROM cte_tag
	
	--WHERE aa_cid IS NULL

	ORDER BY
		[Principal_Alcohol_Related_Diagnosis]
;

/*

SELECT 
	COUNT(*) as nEvents
	,[Principal_Alcohol_Related_Diagnosis]	--AS ICD10_Diag
	, CC_AA.[Description]					AS ICD10_Desc
	, CC_AA.[Chapter]						AS ICD10_Chapter
	, CC_AA.[Group]							AS ICD10_Group
	, AA_DIAG_COND.uid						AS aa_cid
	, AA_COND.[condition cat1]
	, AA_COND.[condition cat2]
	, AA_COND.[condition desc]
	, AA_COND.[condition attribution]
	, AA_COND.[cause basis]
	, AA_COND.[icd codes]
	
	FROM [Public_Health].[dbo].[LAPH_IP]
	
	LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes]			AS CC_AA
        ON (CC_AA.Code = LAPH_IP.[Principal_Alcohol_Related_Diagnosis] AND CC_AA.Field_Name = 'Diagnosis_ICD')
        
	LEFT JOIN [ucs-bisqldev].PHIIT.dbo.tmpIB__AA__lu__uid_icd		AS AA_DIAG_COND
		ON (AA_DIAG_COND.codes = LAPH_IP.[Principal_Alcohol_Related_Diagnosis])
		
	LEFT JOIN [ucs-bisqldev].PHIIT.dbo.tmpIB__AA__aac				AS AA_COND
		ON (AA_COND.[condition uid] = AA_DIAG_COND.uid)

	WHERE
		NOT [Principal_Alcohol_Related_Diagnosis] IS NULL
	GROUP BY
		[Principal_Alcohol_Related_Diagnosis]
		, CC_AA.[Description]
		, CC_AA.[Chapter]
		, CC_AA.[Group]
		, AA_DIAG_COND.uid
		, AA_COND.[condition cat1]
		, AA_COND.[condition cat2]
		, AA_COND.[condition desc]
		, AA_COND.[condition attribution]
		, AA_COND.[cause basis]
		, AA_COND.[icd codes]
		ORDER BY
		[Principal_Alcohol_Related_Diagnosis]
;

*/