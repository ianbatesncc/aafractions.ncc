/*

ALCOHOL RELATED ADMISSIONS QUERY - NARROW MEASURE (record level)

PHOF 2.18
LAPE 10.01

Alcohol related hospital admissions based on the narrow measure- includes all 
admission episodes where the primary code is an alcohol related condition and 
episodes where primary diagnosis is not an alcohol related condition but one of
the secondary codes is an external cause code with an attributable fraction that
falls within a specified date (date is based on the consultant episode end date)

******/

-- both sections have date parameters which must reflect the same time period 


declare @datestart as datetime
declare @dateend as datetime

-- Dates are exclusive

-- Five years 2012-2016
set @datestart = '2011/12/31'
set @dateend = '2017/01/01'

-- Single year 2016
/*
set @datestart = '2015/12/31'
set @dateend = '2017/01/01'
*/

-- Single year 2015/16
--set @datestart = '2015/03/31'
--set @dateend = '2016/04/01'

-- Max. span in FY terms.
set @datestart = '2011/03/31'
set @dateend = '2017/04/01'

/*

This section of the query extracts all episodes where the primary diagnosis is 
an alcohol related condition

Note Alcohol related conditions include all alcohol specific conditions plus 
those causally implicated in some but not all cases of the outcome

IB: trying to simplify to (af > 0) AND ( (primdiag in (set of ICD10codes)) OR (secdiag in (set of external codes))

*****/

SELECT
	'HES LAPH alcohol-related (narrow)' as data_source 

    , LAPH.[HES_Identifier_Encrypted]
    , LAPH.[Generated_Record_Identifier]
    , IP.SUS_Generated_Spell_Id
--    , IP.Admission_Date_Hospital_Provider_Spell
    , IP.Age_at_Start_of_Episode_D
    , case
		when (IP.Age_at_Start_of_Episode_D > 74) then '  75+ Yrs'
		when (IP.Age_at_Start_of_Episode_D > 64) then '65-74 Yrs'
		when (IP.Age_at_Start_of_Episode_D > 54) then '55-64 Yrs'
		when (IP.Age_at_Start_of_Episode_D > 44) then '45-54 Yrs'
		when (IP.Age_at_Start_of_Episode_D > 34) then '35-44 Yrs'
		when (IP.Age_at_Start_of_Episode_D > 24) then '25-34 Yrs'
		when (IP.Age_at_Start_of_Episode_D > 15) then '16-24 Yrs'
		when (IP.Age_at_Start_of_Episode_D >= 0) then ' 0-15 Yrs'
    end as																		"Age Banding"
--	, IP.Ethnic_Category
--	, AC.Description                                                            "Ethnicity"
--	, IP.Gender                                                                 "Gender code"
	, AC1.Description                                                           "Gender"
--	, IP.Consultant_Episode_Start_Date
--	, IP.Consultant_Episode_End_Date
	, datepart(yyyy, IP.Consultant_Episode_End_Date)							as [CalYear]
	, datepart(mm, IP.Consultant_Episode_End_Date)								as [CalMonth]
--	, datediff (day, IP.Consultant_Episode_Start_Date, IP.Consultant_Episode_End_Date) "Episode LOS"
--	, IP.Discharge_Date_Hospital_Spell_Provider
	, left(IP.Diagnosis_ICD_1, 3)                                               "3 digit prim diag"
	, IP.Diagnosis_ICD_1                                                        "Prim Diag Code"
--	, CC.Description                                                            "Prim Diag Code Desc"
	, IP.Diagnosis_ICD_Concatenated_D
--	, CC.Chapter                                                                "ICD_10 Chapter"
--	, CC.[Group]                                                                "ICD_10 Group"
--	, IP.Consultant_Episode_Number
	, IP.Local_Authority_District
	, IP.Practice_Code_of_Registered_GP
--	, IP.IMD_Index_of_Multiple_Deprivation
--	, IMD.IMD_District_Quintile
--	, IMD.IMD_National_Decile
--	, IP.[Postcode_Sector_D]
--	, IP.Current_Electoral_Ward
--	, LAC.Ward_Name
--	, LAC.Local_Area_Committee
	, IP.CCG_of_Residence
	, IP.GIS_LSOA_2011_D
--	, IP.GIS_LSOA_2001_D
	, LAPH.[Principal_Alcohol_Related_Diagnosis]
	, CC2.DESCRIPTION                                                           "Principal Alcohol Related Diagnosis Desc"
	, CAST(LAPH.[Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2))        "Principal_Alcohol_Related_Fraction"
	, RANK() OVER
	    (
    	    PARTITION BY LAPH.HES_Identifier_Encrypted
--    	    ORDER BY LAPH.Generated_Record_Identifier desc
--    	    ORDER BY IP.SUS_Generated_Spell_Id desc
			ORDER BY IP.Admission_Date_Hospital_Provider_Spell DESC
        )                                                                       "Rank"
	, '1'                                                                       "Count"
    
    FROM (
		SELECT * 
			, CAST([Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2)) AS af
			FROM [Public_Health].[dbo].[LAPH_IP]
			WHERE CAST([Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2)) <> 0
		)																		AS LAPH

        LEFT JOIN (
			SELECT *
				, LEFT(Diagnosis_ICD_1, 3) as diag_icd_1__3
			FROM [Public_Health].[dbo].[HES_IP]
        )																		AS IP
            ON IP.Generated_Record_Identifier = LAPH.Generated_Record_Identifier

        LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes]                     AS CC 
            ON CC.Code = IP.Diagnosis_ICD_1 AND CC.Field_Name = 'Diagnosis_ICD'

        LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes]                     AS CC2 
            ON CC2.Code = LAPH.Principal_Alcohol_Related_Diagnosis AND CC2.Field_Name = 'Diagnosis_ICD'

		/*
        LEFT JOIN [Shared_Reference].[dbo].[National_IMD_Scores_2015]           AS IMD 
            ON IMD.LSOA_2011 = IP.GIS_LSOA_2011_D

        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]               AS AC4 
            ON AC4.Code = IP.Finished_Consultant_Episode AND AC4.Field_Name = 'Finished_Indicator'

        LEFT JOIN [Shared_Reference].[dbo].[Local_Area_Committees]              AS LAC 
            ON LAC.Electoral_Ward = IP.Current_Electoral_Ward 

        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]               AS AC 
            ON AC.Code = IP.Ethnic_Category AND AC.Field_Name = 'Ethnic_Category'
		*/

        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]               AS AC1 
            ON AC1.Code = IP.Gender AND AC1.Field_Name = 'GENDER'
    
    WHERE 
    
        --(IP.Consultant_Episode_End_Date BETWEEN @datestart AND @dateend)
        (
			(IP.Consultant_Episode_End_Date > @datestart) AND
			(IP.Consultant_Episode_End_Date < @dateend)
		)

        -- identifies nottingham city residents
        
        AND
        
        (
            IP.Local_Authority_District in (
				'E06000018',
	            'E07000170', 'E07000171', 'E07000172', 'E07000173'
	            , 'E07000174', 'E07000175', 'E07000176'
				)
            OR
            
            IP.CCG_of_Residence in (
				'04K',
				'02Q', '04E', '04H', '04L', '04M', '04N'
				)
        )

        AND
        
        (
        
			/* Primary diagnosis is an alcohol attributable condition
			*/
			(
	        
				/* Partially attributable codes */
				( 
					IP.diag_icd_1__3 LIKE 'C0[0-9]' OR -- C00-C09
					IP.diag_icd_1__3 LIKE 'C1[0-458]' OR -- C10-C14, C15, C18
					IP.diag_icd_1__3 IN (
						'C20', 'C22', 'C32', 'C50'
						, 'G40', 'G41'
						, 'I47', 'I48', 'I50', 'I51', 'I85'
						, 'K73', 'K74', 'K85'
						, 'O03'
					   ) OR
					IP.diag_icd_1__3 LIKE 'I1[0-5]' OR -- I10-I15
					IP.diag_icd_1__3 LIKE 'I6[0-6]' OR -- I60-62, I69.0-I69.2, I63-66, I69.3-I69.4
					IP.Diagnosis_ICD_1 LIKE 'I69[0-4]' OR -- I60-62, I69.0-I69.2, I63-66, I69.3-I69.4
					((IP.diag_icd_1__3 = 'L40') AND (IP.Diagnosis_ICD_1 <> 'L405')) OR -- L40 exc. L40.5
					IP.Diagnosis_ICD_1 = 'K861' -- K86, K86.1
	                
				) /* /Partially attributable codes */
	            
				OR
	            
				/* wholly attributable codes 
				*/
				(
					IP.diag_icd_1__3 IN ('F10', 'K70', 'X45') OR
					IP.Diagnosis_ICD_1 IN (
						'E244', 'G312', 'G621', 'G721', 'I426', 'K292', 'K860'
						, 'T510', 'T511', 'T519'
					)
				) /* /wholly attributable codes */
			)
	        
			OR
	        
			/* an alcohol attributable external code appears in the secondary diagnoses
			*/
			(
				Diagnosis_ICD_Concatenated_D like '%;V9[0-7]%' OR		-- V90-94, V95-97
				Diagnosis_ICD_Concatenated_D like '%;W[01][0-9]%' OR	-- W00-W19
				Diagnosis_ICD_Concatenated_D like '%;W2[4-9]%' OR		-- W24-W31, W32-W34
				Diagnosis_ICD_Concatenated_D like '%;W3[0-4]%' OR		-- W24-W31, W32-W34
				Diagnosis_ICD_Concatenated_D like '%;W6[5-9]%' OR		-- W65-74, W78-79
				Diagnosis_ICD_Concatenated_D like '%;W7[0-489]%' OR		-- W65-74, W78-79
				Diagnosis_ICD_Concatenated_D like '%;X0[0-9]%' OR		-- X00-X09
				Diagnosis_ICD_Concatenated_D like '%;X[6-9][0-9]%' OR	-- X60-X84, Y10-Y34, X85-Y09
				Diagnosis_ICD_Concatenated_D like '%;Y[0-2][0-9]%' OR	-- X60-X84, Y10-Y34, X85-Y09
				Diagnosis_ICD_Concatenated_D like '%;Y3[0-4]%' OR		-- X60-X84, Y10-Y34, X85-Y09
				-- S
				-- V12-V14 (.3 -.9), V19.4-V19.6, V19.9, V20-V28 (.3 -.9), V29-V79 (.4 -.9), V80.3-V80.5
				--, V81.1, V82.1, V82.9, V83-V86 (.0 -.3), V87.0-V87.9, V89.2, V89.3, V89.9 
				Diagnosis_ICD_Concatenated_D like '%;V1[2-4][3-9]%' OR
				Diagnosis_ICD_Concatenated_D like '%;V19[4-69]%' OR
				Diagnosis_ICD_Concatenated_D like '%;V2[0-8][3-9]%' OR
				Diagnosis_ICD_Concatenated_D like '%;V29[4-9]%' OR
				Diagnosis_ICD_Concatenated_D like '%;V[3-7][0-9][4-9]%' OR
				Diagnosis_ICD_Concatenated_D like '%;V80[3-5]%' OR
				Diagnosis_ICD_Concatenated_D like '%;V8[12]1%' OR
				Diagnosis_ICD_Concatenated_D like '%;V829%' OR
				Diagnosis_ICD_Concatenated_D like '%;V8[3-6][0-3]%' OR
				Diagnosis_ICD_Concatenated_D like '%;V87[0-9]%' OR
				Diagnosis_ICD_Concatenated_D like '%;V89[239]%' OR
				-- SS
				-- V02-V04 (.1, .9), V06.1, V09.2, V09.3 
				Diagnosis_ICD_Concatenated_D like '%;V0[2-4][1-9]%' OR
				Diagnosis_ICD_Concatenated_D like '%;V061%' OR
				Diagnosis_ICD_Concatenated_D like '%;V09[23]%'
			)
	        
        )
        
        AND
        
        /* the record has an attributable fraction in the first place
         - that is harmful i.e. greater than 0
        */
		--CAST(LAPH.[Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2)) <> 0.00
		--CAST(LAPH.[Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2)) > 0.00
		(af > 0)

/*
     
UNION ALL
 
/*

This section extracts all episodes where the primary diagnosis is not an alcohol
specific condition but the secondary diagnosis is an external cause code

*/

SELECT 
    LAPH.[HES_Identifier_Encrypted]
	, LAPH.[Generated_Record_Identifier]
	, IP.SUS_Generated_Spell_Id
--	, IP.Admission_Date_Hospital_Provider_Spell
	, IP.Age_at_Start_of_Episode_D
    , case
		when (IP.Age_at_Start_of_Episode_D > 74) then '  75+ Yrs'
		when (IP.Age_at_Start_of_Episode_D > 64) then '65-74 Yrs'
		when (IP.Age_at_Start_of_Episode_D > 54) then '55-64 Yrs'
		when (IP.Age_at_Start_of_Episode_D > 44) then '45-54 Yrs'
		when (IP.Age_at_Start_of_Episode_D > 34) then '35-44 Yrs'
		when (IP.Age_at_Start_of_Episode_D > 24) then '25-34 Yrs'
		when (IP.Age_at_Start_of_Episode_D > 15) then '16-24 Yrs'
		when (IP.Age_at_Start_of_Episode_D >= 0) then ' 0-15 Yrs'
    end as																		"Age Banding"
--	, IP.Ethnic_Category
--	, AC.Description                                                            "Ethnicity"
--	, IP.Gender                                                                 "Gender code"
	, AC1.Description                                                           "Gender"
--	, IP.Consultant_Episode_Start_Date
--	, IP.Consultant_Episode_End_Date
	, datepart(yyyy, IP.Consultant_Episode_End_Date)							as [CalYear]
	, datepart(mm, IP.Consultant_Episode_End_Date)								as [CalMonth]
--	, datediff(day, IP.Consultant_Episode_Start_Date, IP.Consultant_Episode_End_Date)    "Episode LOS"
--	, IP.Discharge_Date_Hospital_Spell_Provider
	, left(IP.Diagnosis_ICD_1, 3)                                               "3 digit prim diag"
	, IP.Diagnosis_ICD_1                                                        "Prim Diag Code"
	, CC.Description                                                            "Prim Diag Code Desc"
	, IP.Diagnosis_ICD_Concatenated_D
	, CC.Chapter                                                                "ICD_10 Chapter"
	, CC.[Group]                                                                "ICD_10 Group"
--	, IP.Consultant_Episode_Number
	, IP.Local_Authority_District
	, IP.Practice_Code_of_Registered_GP
--	, IP.IMD_Index_of_Multiple_Deprivation
--	, IMD.IMD_District_Quintile
--	, IMD.IMD_National_Decile
--	, IP.[Postcode_Sector_D]
--	, IP.Current_Electoral_Ward
--	, LAC.Ward_Name
--	, LAC.Local_Area_Committee
	, IP.CCG_of_Residence
	, IP.GIS_LSOA_2011_D
--	, IP.GIS_LSOA_2001_D
	, LAPH.[Principal_Alcohol_Related_Diagnosis]
	, CC2.DESCRIPTION                                                           "Principal Alcohol Related Diagnosis Desc"
	, CAST(LAPH.[Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2))        "Principal_Alcohol_Related_Fraction"
	, RANK() OVER (
    	    PARTITION BY LAPH.HES_Identifier_Encrypted
--    	    ORDER BY LAPH.Generated_Record_Identifier desc
--    	    ORDER BY IP.SUS_Generated_Spell_Id desc
			ORDER BY IP.Admission_Date_Hospital_Provider_Spell DESC
        )                                                                       "Rank"
	, '1'                                                                       "Count"

    FROM [Public_Health].[dbo].[LAPH_IP]                                        AS LAPH
    
        LEFT JOIN [Public_Health].[dbo].[HES_IP]                                AS IP
            ON IP.Generated_Record_Identifier =LAPH.Generated_Record_Identifier
            
        LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes]                     AS CC 
            ON CC.Code =IP.Diagnosis_ICD_1 AND CC.Field_Name = 'Diagnosis_ICD'

        LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes]                     AS CC2 
            ON CC2.Code =LAPH.Principal_Alcohol_Related_Diagnosis AND CC2.Field_Name = 'Diagnosis_ICD'
		/*
        LEFT JOIN [Shared_Reference].[dbo].[National_IMD_Scores_2015]           AS IMD 
            ON IMD.LSOA_2011 = IP.GIS_LSOA_2011_D

        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]               AS AC4 
            ON AC4.Code = IP.Finished_Consultant_Episode AND AC4.Field_Name = 'Finished_Indicator'

        LEFT JOIN [Shared_Reference].[dbo].[Local_Area_Committees]              AS LAC 
            ON LAC.Electoral_Ward = IP.Current_Electoral_Ward 

        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]               AS AC 
            ON AC.Code = IP.Ethnic_Category AND AC.Field_Name = 'Ethnic_Category'
        */

        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]               AS AC1 
            ON AC1.Code = IP.Gender AND AC1.Field_Name = 'GENDER'

    WHERE
    
        --(IP.Consultant_Episode_End_Date BETWEEN @datestart AND @dateend)
        (
			(IP.Consultant_Episode_End_Date > @datestart) AND
			(IP.Consultant_Episode_End_Date < @dateend)
		)

        -- identifies nottingham city residents
        
        AND
        
        (
            IP.Local_Authority_District in (
				'E06000018'
	            , 'E07000170', 'E07000171', 'E07000172', 'E07000173'
	            , 'E07000174', 'E07000175', 'E07000176'
				)
            or
            IP.CCG_of_Residence in ('04Q', '02Q', '04E', '04H', '04L', '04M', '04N')
        )
        
        -- identifies episodes where the principal alcohol diagnosis is an 
        -- external cause code
        
        and
        
        (
            LAPH.Principal_Alcohol_Related_Diagnosis LIKE ('V%')
            OR
            LAPH.Principal_Alcohol_Related_Diagnosis LIKE ('W%')
            OR
            LAPH.Principal_Alcohol_Related_Diagnosis LIKE ('X%')
            OR
            LAPH.Principal_Alcohol_Related_Diagnosis LIKE ('Y%')
        )


        -- excludes episodes where a partially or wholly attributable code is 
        -- the primary diagnosis 
        
        AND
        
        LEFT(IP.Diagnosis_ICD_1, 3) NOT IN (
            'A15', 'A16', 'A17', 'A18', 'A19'
            , 'C00', 'C01', 'C02', 'C03', 'C04', 'C05', 'C06', 'C07', 'C08', 'C09'
            , 'C10', 'C11', 'C12', 'C13', 'C14', 'C15', 'C18', 'C19'
            , 'C20', 'C21', 'C22'
            , 'C32'
            , 'C50'
            , 'E11'
            , 'G40', 'G41'
            , 'I10', 'I11', 'I12', 'I13', 'I14', 'I15'
            , 'I20', 'I21', 'I22', 'I23', 'I24', 'I25'
            , 'I47', 'I48'
            , 'I60', 'I61', 'I62', 'I63', 'I64', 'I65', 'I66'
            , 'I85'
            , 'J12', 'J13', 'J14', 'J15', 'J18'
            , 'K73', 'K74'
            , 'K80'
            , 'O03'
            , 'P05', 'P07'
        )
        
        AND
        
        IP.Diagnosis_ICD_1 NOT IN (
            'I690', 'I692', 'I693', 'I694'
            , 'J100', 'J110'
            , 'K850', 'K851', 'K852', 'K853', 'K858', 'K859'
            , 'K860', 'K861'
        ) /* Partially attributable codes */
        
        AND
        
        LEFT(IP.Diagnosis_ICD_1, 3) NOT IN (
            'f10', 'K70', 'X45', 'X65', 'Y15', 'Y90', 'Y91'
        )
        
        AND
        
        IP.Diagnosis_ICD_1 NOT IN (
            'E244', 'G312', 'G621', 'G721', 'I426', 'K292', 'K852', 'K860', 'Q860', 'R780', 'T510', 'T511', 'T519'
        ) /* wholly attributable codes */
        
        AND
        
        CAST(LAPH.[Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2)) <> 0.00

*/