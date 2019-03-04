/*

ALCOHOL RELATED ADMISSIONS QUERY - NARROW MEASURE (record level)

Alcohol related hospital admissions based on the narrow measure- includes all 
admission episodes where the primary code is an alcohol related condition and 
episodes where primary diagnosis is not an alcohol related condition but one of
the secondary codes is an external cause code with an attributable fraction that
falls within a specified date (date is based on the consultant episode end date)

******/

-- both sections have date parameters which must reflect the same time period 

/*

This section of the query extracts all episodes where the primary diagnosis is 
an alcohol related condition

Note Alcohol related conditions include all alcohol specific conditions plus 
those causally implicated in some but not all cases of the outcome

*****/

SELECT 
    LAPH.[HES_Identifier_Encrypted]
    , LAPH.[Generated_Record_Identifier]
    , IP.SUS_Generated_Spell_Id
    , IP.Admission_Date_Hospital_Provider_Spell
    , IP.Age_at_Start_of_Episode_D
    , CASE
        WHEN IP.Age_at_Start_of_Episode_D BETWEEN  0 AND 15 THEN '0-15 Yrs'
        WHEN IP.Age_at_Start_of_Episode_D BETWEEN 16 AND 24 THEN '16-24 Yrs'
        WHEN IP.Age_at_Start_of_Episode_D BETWEEN 25 AND 34 THEN '25-34 Yrs'
        WHEN IP.Age_at_Start_of_Episode_D BETWEEN 35 AND 44 THEN '35-44 Yrs'
        WHEN IP.Age_at_Start_of_Episode_D BETWEEN 45 AND 54 THEN '45-54 Yrs'
        WHEN IP.Age_at_Start_of_Episode_D BETWEEN 55 AND 64 THEN '55-64 Yrs'
        WHEN IP.Age_at_Start_of_Episode_D BETWEEN 65 AND 74 THEN '65-74 Yrs'
        WHEN IP.Age_at_Start_of_Episode_D >74 THEN '75+ Yrs'
    End                                                                         "Age Banding"
	, IP.Ethnic_Category
	, AC.Description                                                            "Ethnicity"
	, IP.Gender                                                                 "Gender code"
	, AC1.Description                                                           "Gender"
	, IP.Consultant_Episode_Start_Date
	, IP.Consultant_Episode_End_Date
	, datediff (day, IP.Consultant_Episode_Start_Date, IP.Consultant_Episode_End_Date) "Episode LOS"
	, IP.Discharge_Date_Hospital_Spell_Provider
	, left(IP.Diagnosis_ICD_1, 3)                                               "3 digit prim diag"
	, IP.Diagnosis_ICD_1                                                        "Prim Diag Code"
	, CC.Description                                                            "Prim Diag Code Desc"
	, IP.Diagnosis_ICD_Concatenated_D
	, CC.Chapter                                                                "ICD_10 Chapter"
	, IP.Consultant_Episode_Number
	, IP.Local_Authority_District
	, IP.Practice_Code_of_Registered_GP
	, IP.IMD_Index_of_Multiple_Deprivation
	, IMD.IMD_District_Quintile
	, IMD.IMD_National_Decile
	, IP.[Postcode_Sector_D]
	, IP.Current_Electoral_Ward
	, LAC.Ward_Name
	, LAC.Local_Area_Committee
	, IP.CCG_of_Residence
	, IP.GIS_LSOA_2011_D
	, IP.GIS_LSOA_2001_D
	, LAPH.[Principal_Alcohol_Related_Diagnosis]
	, CC2.DESCRIPTION                                                           "Principal Alcohol Related Diagnosis Desc"
	, CAST(LAPH.[Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2))        "Principal_Alcohol_Related_Fraction"
	, RANK() OVER
	    (
    	    PARTITION BY LAPH.HES_Identifier_Encrypted
    	    ORDER BY LAPH.Generated_Record_Identifier desc
        )                                                                       "Rank"
	, '1'                                                                       "Count"
    
    FROM [Public_Health].[dbo].[LAPH_IP]                                        AS LAPH

        LEFT JOIN [Public_Health].[dbo].[HES_IP]                                AS IP
            ON IP.Generated_Record_Identifier = LAPH.Generated_Record_Identifier

        LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes]                     AS CC 
            ON CC.Code =IP.Diagnosis_ICD_1 AND CC.Field_Name = 'Diagnosis_ICD'

        LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes]                     AS CC2 
            ON CC2.Code =LAPH.Principal_Alcohol_Related_Diagnosis AND CC2.Field_Name = 'Diagnosis_ICD'

        LEFT JOIN [Shared_Reference].[dbo].[National_IMD_Scores_2015]           AS IMD 
            ON IMD.LSOA_2011 = IP.GIS_LSOA_2011_D

        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]               AS AC4 
            ON AC4.Code = IP.Finished_Consultant_Episode AND AC4.Field_Name = 'Finished_Indicator'

        LEFT JOIN [Shared_Reference].[dbo].[Local_Area_Committees]              AS LAC 
            ON LAC.Electoral_Ward = IP.Current_Electoral_Ward 

        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]               AS AC 
            ON AC.Code = IP.Ethnic_Category AND AC.Field_Name = 'Ethnic_Category'

        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]               AS AC1 
            ON AC1.Code = IP.Gender AND AC1.Field_Name = 'GENDER'
    
    WHERE 
    
        IP.Consultant_Episode_End_Date BETWEEN '20150401 00:00:00' AND '20160331 23:59:59'

        -- identifies nottingham city residents
        
        AND
        
        (
            IP.Local_Authority_District = 'E06000018'
            or
            IP.CCG_of_Residence = '04K'
        )

        AND
        
        (
        
            /* Partially attributable codes */
            
            (
                LEFT (IP.Diagnosis_ICD_1, 3) IN (
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
                    
                OR

                IP.Diagnosis_ICD_1 IN (
                    'I690', 'I692', 'I693', 'I694'
                    , 'J100', 'J110'
                    , 'K850', 'K851', 'K852', 'K853', 'K858', 'K859'
                    , 'K860', 'K861'
                )
            )
            
            OR
            
            /* wholly attributable codes */
            
            (
                LEFT (IP.Diagnosis_ICD_1, 3) IN (
                    'F10', 'K70', 'X45', 'X65', 'Y15', 'Y90', 'Y91'
                )

                OR

                IP.Diagnosis_ICD_1 IN (
                    'E244', 'G312', 'G621', 'G721', 'I426', 'K292', 'K852', 'K860', 'Q860', 'R780', 'T510', 'T511', 'T519'
                )
            )
        )
        
        AND
        
        CAST(LAPH.[Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2)) <> 0.00
     
UNION ALL
 
/*

This section extracts all episodes where the primary diagnosis is not an alcohol
specific condition but the secondary diagnosis is an external cause code

*/

SELECT 
    LAPH.[HES_Identifier_Encrypted]
	, LAPH.[Generated_Record_Identifier]
	, IP.SUS_Generated_Spell_Id
	, IP.Admission_Date_Hospital_Provider_Spell
	, IP.Age_at_Start_of_Episode_D
	, CASE
	    WHEN IP.Age_at_Start_of_Episode_D BETWEEN  0 AND 15 THEN '0-15 Yrs'
        WHEN IP.Age_at_Start_of_Episode_D BETWEEN 16 AND 24 THEN '16-24 Yrs'
        WHEN IP.Age_at_Start_of_Episode_D BETWEEN 25 AND 34 THEN '25-34 Yrs'
        WHEN IP.Age_at_Start_of_Episode_D BETWEEN 35 AND 44 THEN '35-44 Yrs'
        WHEN IP.Age_at_Start_of_Episode_D BETWEEN 45 AND 54 THEN '45-54 Yrs'
        WHEN IP.Age_at_Start_of_Episode_D BETWEEN 55 AND 64 THEN '55-64 Yrs'
        WHEN IP.Age_at_Start_of_Episode_D BETWEEN 65 AND 74 THEN '65-74 Yrs'
        WHEN IP.Age_at_Start_of_Episode_D >74 THEN '75+ Yrs'
    End                                                                         "Age Banding"
	, IP.Ethnic_Category
	, AC.Description                                                            "Ethnicity"
	, IP.Gender                                                                 "Gender code"
	, AC1.Description                                                           "Gender"
	, IP.Consultant_Episode_Start_Date
	, IP.Consultant_Episode_End_Date
	, datediff(day, IP.Consultant_Episode_Start_Date, IP.Consultant_Episode_End_Date)    "Episode LOS"
	, IP.Discharge_Date_Hospital_Spell_Provider
	, left(IP.Diagnosis_ICD_1, 3)                                               "3 digit prim diag"
	, IP.Diagnosis_ICD_1                                                        "Prim Diag Code"
	, CC.Description                                                            "Prim Diag Code Desc"
	, IP.Diagnosis_ICD_Concatenated_D
	, CC.Chapter                                                                "ICD_10 Chapter"
	, IP.Consultant_Episode_Number
	, IP.Local_Authority_District
	, IP.Practice_Code_of_Registered_GP
	, IP.IMD_Index_of_Multiple_Deprivation
	, IMD.IMD_District_Quintile
	, IMD.IMD_National_Decile
	, IP.[Postcode_Sector_D]
	, IP.Current_Electoral_Ward
	, LAC.Ward_Name
	, LAC.Local_Area_Committee
	, IP.CCG_of_Residence
	, IP.GIS_LSOA_2011_D
	, IP.GIS_LSOA_2001_D
	, LAPH.[Principal_Alcohol_Related_Diagnosis]
	, CC2.DESCRIPTION                                                           "Principal Alcohol Related Diagnosis Desc"
	, CAST(LAPH.[Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2))        "Principal_Alcohol_Related_Fraction"
	, RANK() OVER (
    	    PARTITION BY LAPH.HES_Identifier_Encrypted
    	    ORDER BY LAPH.Generated_Record_Identifier desc
        )                                                                       "Rank"
	, '1'                                                                       "Count"

    FROM [Public_Health].[dbo].[LAPH_IP]                                        AS LAPH
    
        LEFT JOIN [Public_Health].[dbo].[HES_IP]                                AS IP
            ON IP.Generated_Record_Identifier =LAPH.Generated_Record_Identifier
            
        LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes]                     AS CC 
            ON CC.Code =IP.Diagnosis_ICD_1 AND CC.Field_Name = 'Diagnosis_ICD'

        LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes]                     AS CC2 
            ON CC2.Code =LAPH.Principal_Alcohol_Related_Diagnosis AND CC2.Field_Name = 'Diagnosis_ICD'

        LEFT JOIN [Shared_Reference].[dbo].[National_IMD_Scores_2015]           AS IMD 
            ON IMD.LSOA_2011 = IP.GIS_LSOA_2011_D

        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]               AS AC4 
            ON AC4.Code = IP.Finished_Consultant_Episode AND AC4.Field_Name = 'Finished_Indicator'

        LEFT JOIN [Shared_Reference].[dbo].[Local_Area_Committees]              AS LAC 
            ON LAC.Electoral_Ward = IP.Current_Electoral_Ward 

        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]               AS AC 
            ON AC.Code = IP.Ethnic_Category AND AC.Field_Name = 'Ethnic_Category'

        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]               AS AC1 
            ON AC1.Code = IP.Gender AND AC1.Field_Name = 'GENDER'

    WHERE
    
        IP.Consultant_Episode_End_Date BETWEEN '20150401 00:00:00' AND '20160331 23:59:59'

        AND
        
        (
            IP.Local_Authority_District = 'E06000018' or IP.CCG_of_Residence = '04K'
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
            'F10', 'K70', 'X45', 'X65', 'Y15', 'Y90', 'Y91'
        )
        
        AND
        
        IP.Diagnosis_ICD_1 NOT IN (
            'E244', 'G312', 'G621', 'G721', 'I426', 'K292', 'K852', 'K860', 'Q860', 'R780', 'T510', 'T511', 'T519'
        ) /* wholly attributable codes */
        
        AND
        
        CAST(LAPH.[Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2)) <> 0.00
