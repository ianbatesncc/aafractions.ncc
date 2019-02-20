/*
SELECT
	'HES IP NHIS' as data_source
      ,left([Principal_Alcohol_Related_Diagnosis], 3) as aa_ICD10_3
      ,[Principal_Alcohol_Related_Diagnosis] as aa_ICD10
      ,min([Principal_Alcohol_Related_Fraction]) as af_min
      ,max([Principal_Alcohol_Related_Fraction]) as af_max
      , COUNT(*) as nrecords
  FROM [Public_Health].[dbo].[LAPH_IP]
  GROUP BY
      [Principal_Alcohol_Related_Diagnosis]
GO
*/


SELECT
	'HES IP NHIS' as data_source
	, aa_ICD10_3
	, aa_ICD10
	, prim_ICD10
	, concat_ICD10
    , min(af) as af_min
    , max(af) as af_max
    , SUM(af) as sf
	, COUNT(*) as nrecords
	
	, case
		when /* af > 0 AND */ (aa_ICD10 = prim_ICD10) then 'narrow - primary'
		--when /* af > 0 AND */ (concat_ICD10 like '%;[VWXY]%') then 'POSSIBLY narrow'
		when aa_ICD10 like '[VWXY]%' then 'narrow - external'
		else 'NOT narrow'
	end as isNarrow
	
    , [Gender_desc]
    , [Age AA Banding]
    
    FROM (
		SELECT *
			, case
				when (HES_IP.Age_at_Start_of_Episode_D > 74) then '75+   Yrs'
				when (HES_IP.Age_at_Start_of_Episode_D > 64) then '65-74 Yrs'
				when (HES_IP.Age_at_Start_of_Episode_D > 54) then '55-64 Yrs'
				when (HES_IP.Age_at_Start_of_Episode_D > 44) then '45-54 Yrs'
				when (HES_IP.Age_at_Start_of_Episode_D > 34) then '35-44 Yrs'
				when (HES_IP.Age_at_Start_of_Episode_D > 24) then '25-34 Yrs'
				when (HES_IP.Age_at_Start_of_Episode_D > 15) then '16-24 Yrs'
				when (HES_IP.Age_at_Start_of_Episode_D >= 0) then '00-15 Yrs'
				else										'[Unknown age]'
			end as [Age AA Banding]
			, AC1.Description as [Gender_desc]
			, [Diagnosis_ICD_1] as prim_ICD10
			, [Diagnosis_ICD_Concatenated_D] as concat_ICD10
			
			FROM [Public_Health].[dbo].[HES_IP]
			
				LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]   AS AC1
					ON (AC1.Code = HES_IP.Gender AND AC1.Field_Name = 'GENDER')
		)																AS IP
		
        LEFT JOIN (
			SELECT *
				, CAST([Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2)) AS af
				, left([Principal_Alcohol_Related_Diagnosis], 3) as aa_ICD10_3
				, [Principal_Alcohol_Related_Diagnosis] as aa_ICD10
				
				FROM [Public_Health].[dbo].[LAPH_IP]						
				)														AS LAPH
            ON (LAPH.Generated_Record_Identifier = IP.Generated_Record_Identifier)

	WHERE
		(af > 0) 
		AND ((aa_ICD10 <> prim_ICD10)) -- for inspection
		
	GROUP BY
		aa_ICD10_3
		, aa_ICD10
		, prim_ICD10
		, concat_ICD10
		, [Gender_desc]
		, [Age AA Banding]

	ORDER BY
		aa_ICD10_3
		, aa_ICD10
		, prim_ICD10
		, concat_ICD10
		, [Gender_desc]
		, [Age AA Banding]
/*
		, sf DESC
		, nrecords DESC
		*/

/*
SELECT 
	case 
	when 'Hello;World' like '%;[VWXY]%' then 'Yes'
	--when 'Hello;World' like '%;[VWXY]%' then 'Yes'
	else 'No'
	end
*/