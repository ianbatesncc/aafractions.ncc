/*

ALCOHOL SPECIFIC ADMISSIONS QUERY (record level)

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
	, AC1.Description                                                           "Gender"
	, IP.Consultant_Episode_Start_Date
	, IP.Consultant_Episode_End_Date
	, DATEDIFF(DAY,IP.Consultant_Episode_Start_Date,IP.Consultant_Episode_End_Date) "Episode LOS"
	, IP.Discharge_Date_Hospital_Spell_Provider
	, LEFT(IP.Diagnosis_ICD_1,3)                                                "3 Digit Prim Diag Code"
	, IP.Diagnosis_ICD_1                                                        "Prim Diag Code"
	, CC.Description                                                            "Prim Diag Code Desc"
	, IP.Diagnosis_ICD_Concatenated_D
	, CC.Chapter                                                                "ICD_10 Chapter"
	, CC.[Group]                                                                "ICD_10 Group"
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
	, CAST(LAPH.[Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2))        "Principal_Alcohol_Related_Fraction"
	, '1'                                                                       "Count"


    FROM [Public_Health].[dbo].[LAPH_IP] AS LAPH
    
        LEFT JOIN [Public_Health].[dbo].[HES_IP] AS IP 
            ON IP.Generated_Record_Identifier = LAPH.Generated_Record_Identifier
    
        LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes] AS CC 
            ON CC.Code =IP.Diagnosis_ICD_1 AND CC.Field_Name = 'Diagnosis_ICD'
    
        LEFT JOIN [Shared_Reference].[dbo].[National_IMD_Scores_2015] AS IMD 
            ON IMD.LSOA_2011 = IP.GIS_LSOA_2011_D
    
        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes] AS AC4 
            ON AC4.Code = IP.Finished_Consultant_Episode AND AC4.Field_Name = 'Finished_Indicator'
    
        LEFT JOIN [Shared_Reference].[dbo].[Local_Area_Committees] AS LAC 
            ON LAC.Electoral_Ward = IP.Current_Electoral_Ward 
    
        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes] AS AC 
            ON AC.Code = IP.Ethnic_Category AND AC.Field_Name = 'Ethnic_Category'
    
        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes] AS AC1 
            ON AC1.Code = IP.Gender AND AC1.Field_Name = 'GENDER'

    WHERE
    
        IP.Consultant_Episode_End_Date BETWEEN '20150401 00:00:00' AND '20160331 23:59:59'
        
        AND
        
        (
            IP.Local_Authority_District = 'E06000018'
            or
            IP.CCG_of_Residence = '04k'
        )
        
        AND 
        
        /* includes only finished episodes*/
        IP.Episode_Status = 3
        
        AND
        
        /*
        includes ordinary admissions (1), day cases (2) and 
        mothers and babies (5)
        */
        IP.Patient_Classification IN ('1', '2', '5')
        
        AND
        
        LAPH.Principal_Alcohol_Related_Fraction = '1.00'
        
        and
        
        IP.Consultant_Episode_Number = 1
