/*

ALCOHOL SPECIFIC ADMISSIONS QUERY (record level)

LAPE 6.02

*/

declare @datestart as datetime
declare @dateend as datetime

-- Inspect years
/*
select
	count(*) as n
	, DATEPART(YYYY, IP.Consultant_Episode_End_Date) as CalYear
	, DATEPART(mm, IP.Consultant_Episode_End_Date) as CalMonth
	from
		[Public_Health].[dbo].[HES_IP] AS IP
	group by
		DATEPART(YYYY, IP.Consultant_Episode_End_Date)
		, DATEPART(mm, IP.Consultant_Episode_End_Date)
	order by
		DATEPART(YYYY, IP.Consultant_Episode_End_Date)
		, DATEPART(mm, IP.Consultant_Episode_End_Date)
		;
*/
-- Looks like 2011/04 to 2017/11 is complete

-- Dates are exclusive
-- Six years 2012-2017
set @datestart = '2011/03/31'
--set @datestart = '2011/12/31'
--set @dateend = '2017/01/01'
set @dateend = '2017/11/01'

SELECT
	'HES LAPH alcohol-specific' as data_source
	
    , LAPH.[HES_Identifier_Encrypted]
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
	, AC1.Description                                                           "Gender"
--	, IP.Consultant_Episode_Start_Date
	, datepart(yyyy, IP.Consultant_Episode_End_Date)							as [CalYear]
	, datepart(mm, IP.Consultant_Episode_End_Date)								as [CalMonth]
--	, DATEDIFF(DAY,IP.Consultant_Episode_Start_Date,IP.Consultant_Episode_End_Date) "Episode LOS"
--	, IP.Discharge_Date_Hospital_Spell_Provider
	, LEFT(IP.Diagnosis_ICD_1,3)                                                "3 Digit Prim Diag Code"
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
	, CAST(LAPH.[Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2))        "Principal_Alcohol_Related_Fraction"
	, '1'                                                                       "Count"


    FROM [Public_Health].[dbo].[LAPH_IP] AS LAPH
    
        LEFT JOIN [Public_Health].[dbo].[HES_IP] AS IP 
            ON IP.Generated_Record_Identifier = LAPH.Generated_Record_Identifier
    
        LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes] AS CC 
            ON CC.Code =IP.Diagnosis_ICD_1 AND CC.Field_Name = 'Diagnosis_ICD'
    
		/*
        LEFT JOIN [Shared_Reference].[dbo].[National_IMD_Scores_2015] AS IMD 
            ON IMD.LSOA_2011 = IP.GIS_LSOA_2011_D
    
        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes] AS AC4 
            ON AC4.Code = IP.Finished_Consultant_Episode AND AC4.Field_Name = 'Finished_Indicator'
    
        LEFT JOIN [Shared_Reference].[dbo].[Local_Area_Committees] AS LAC 
            ON LAC.Electoral_Ward = IP.Current_Electoral_Ward 
    
        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes] AS AC 
            ON AC.Code = IP.Ethnic_Category AND AC.Field_Name = 'Ethnic_Category'
        */
    
        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes] AS AC1 
            ON AC1.Code = IP.Gender AND AC1.Field_Name = 'GENDER'

    WHERE
		/*
		Events beteween dates specified
		*/
        --(IP.Consultant_Episode_End_Date BETWEEN @datestart AND @dateend)
        (
			(IP.Consultant_Episode_End_Date > @datestart) AND
			(IP.Consultant_Episode_End_Date < @dateend)
		)
        
        AND
        
        (
            IP.Local_Authority_District in (
				'E06000018'
	            , 'E07000170', 'E07000171', 'E07000172', 'E07000173'
	            , 'E07000174', 'E07000175', 'E07000176'
				)
            or
            IP.CCG_of_Residence in ('04K', '02Q', '04E', '04H', '04L', '04M', '04N')
        )
        
        AND 
        
        /* includes only finished episodes*/
        (IP.Episode_Status = 3)
        
        AND
        
        /*
        includes ordinary admissions (1), day cases (2) and 
        mothers and babies (5)
        */
        (IP.Patient_Classification IN ('1', '2', '5'))
        
        AND
        
        (LAPH.Principal_Alcohol_Related_Fraction = '1.00')
        
        and
        
        (IP.Consultant_Episode_Number = 1)
