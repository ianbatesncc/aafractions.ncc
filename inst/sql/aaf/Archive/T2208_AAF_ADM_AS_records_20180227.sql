/*

ALCOHOL SPECIFIC ADMISSIONS QUERY (record level)

LAPE 6.02

*/

/*

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
-- Looks like 2011/04 to 2017/12 is complete

-- Dates are exclusive
-- Six years 2012-2017
set @datestart = '2011/03/31'
--set @datestart = '2011/12/31'
--set @dateend = '2017/01/01'
set @dateend = '2017/11/01'

-- 2015/16 (dates exclusive)
set @datestart = '2015/03/31'
set @dateend = '2016/04/01'

/*

SELECT top 1000

	'HES LAPH alcohol-specific' as data_source


	/* Record and individual pseudoID
	*/	
    , LAPH.[HES_Identifier_Encrypted]
	, LAPH.[Generated_Record_Identifier]
	, IP.SUS_Generated_Spell_Id 

	/* Demographics
	*/
	, AC1.Description                                                           AS [Gender]
	, left(AC1.Description, 1)													AS [GenderC]

	, IP.Age_at_Start_of_Episode_D												AS [Age_SYOA]
    , case
		when (IP.Age_at_Start_of_Episode_D > 74) then '75+'
		when (IP.Age_at_Start_of_Episode_D > 64) then '65-74'
		when (IP.Age_at_Start_of_Episode_D > 54) then '55-64'
		when (IP.Age_at_Start_of_Episode_D > 44) then '45-54'
		when (IP.Age_at_Start_of_Episode_D > 34) then '35-44'
		when (IP.Age_at_Start_of_Episode_D > 24) then '25-34'
		when (IP.Age_at_Start_of_Episode_D > 15) then '16-24'
		when (IP.Age_at_Start_of_Episode_D >= 0) then '00-15'
		else 'Age unknown'
    end																			AS [AgeBand_AA]
    , ABPH.Alcohol_Fraction_AgeBand												AS [AgeBand_AA_alt]
    , ABPH.AgeBand_ESP															AS [AgeBand_ESP]
	
	/* When
	*/
	, datepart(yyyy, IP.Consultant_Episode_End_Date)							AS [CalYear]
	, datepart(mm, IP.Consultant_Episode_End_Date)								AS [CalMonth]
	
	/* What
	*/
	, LEFT(IP.Diagnosis_ICD_1, 3)                                               [PrimDiagCode3]
	, IP.Diagnosis_ICD_1                                                        [PrimDiagCodeFull]
	, IP.Diagnosis_ICD_Concatenated_D											[AllDiagConcat]
	
	/* Where
	*/
	, IP.Local_Authority_District
	, IP.CCG_of_Residence
	, IP.GIS_LSOA_2011_D
	
	/* How much
	*/
	, LAPH.[Principal_Alcohol_Related_Diagnosis]								AS [PrincipalAADiag]
	, CAST(LAPH.[Principal_Alcohol_Related_Fraction] AS DECIMAL (10, 2))        AS [Principal_Alcohol_Related_Fraction]
	, 1																			AS [Count]


    FROM [Public_Health].[dbo].[LAPH_IP] AS LAPH
    
        LEFT JOIN [Public_Health].[dbo].[HES_IP] AS IP 
            ON IP.Generated_Record_Identifier = LAPH.Generated_Record_Identifier
            
        LEFT JOIN [Shared_Reference].[dbo].[Age_Bands_Public_Health] AS ABPH
			ON (IP.Age_at_Start_of_Episode_D = ABPH.Age_Years)
    
        LEFT JOIN [Shared_Reference].[dbo].[Clinical_Codes] AS CC 
            ON CC.Code = IP.Diagnosis_ICD_1 AND CC.Field_Name = 'Diagnosis_ICD'
    
        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes] AS AC4 
            ON AC4.Code = IP.Finished_Consultant_Episode AND AC4.Field_Name = 'Finished_Indicator'
    
    /* select * from [Shared_Reference].dbo.[Administrative_Codes] ac where (ac.Field_Name = 'GENDER')
    */
        LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes] AS AC1 
            ON AC1.Code = IP.Gender AND AC1.Field_Name = 'GENDER'
            
    WHERE
    
		/* When - Events beteween dates specified
		*/
        (
			(IP.Consultant_Episode_End_Date > @datestart) AND
			(IP.Consultant_Episode_End_Date < @dateend)
		)
        
        AND
        
        /* Where
        */
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
        
        /* What - first episode and includes only finished episodes
        */
        (IP.Consultant_Episode_Number = 1)
        
        and
        
        (IP.Episode_Status = 3)
                
        AND
        
        /* Who - 
        includes ordinary admissions (1), day cases (2) and 
        mothers and babies (5)
        */
        (IP.Patient_Classification IN ('1', '2', '5'))
        
        AND
        
        /* What - only AF +ve
        */
        (LAPH.Principal_Alcohol_Related_Fraction = '1.00')
        
--GO;

*/

/*

;WITH cte (ProductId, ProductName,SupplierId,Prod_Attributes)
AS
(
SELECT 
    [ProductId],
    [ProductName],
    [SupplierId],
    CONVERT(XML,'<Product><Attribute>' 
        + REPLACE([Descr],',', '</Attribute><Attribute>') 
        + '</Attribute></Product>') AS Prod_Attributes
FROM @t
)
SELECT 
    [ProductID],
    [SupplierId],
    Prod_Attributes.value('/Product[1]/Attribute[1]','varchar(25)') AS [Type],
    Prod_Attributes.value('/Product[1]/Attribute[2]','varchar(25)') AS [Length],
    Prod_Attributes.value('/Product[1]/Attribute[3]','varchar(25)') AS [Height],
    Prod_Attributes.value('/Product[1]/Attribute[4]','varchar(25)') AS [Weight]
FROM cte


*/


/*

NO Indexes

TOP 1000 - 2s - 21 rows
TOP 10000 - 11s - 402 rows
TOP 100000 - 2m44 - 22,315 rows

With Indexes

TOP 1000 - 1s - 21 rows
TOP 10000 - 11s - 402 rows
TOP 20000 - 20s - 790 rows
TOP 100000 - 2m39 - 22,315 rows

*/

-- 2015/16 (dates exclusive)
declare @fystart as varchar(4) ;
declare @fyend as varchar(4) ;

set @fystart = '2015'
set @fyend   = '2016'

--set @datestart = @fystart + '/03/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16
set @datestart = @fystart + '/03/31'	;	set @dateend = @fystart + '/07/01' ; -- FY 2015/16 Q1
--set @datestart = @fystart + '/06/30'	;	set @dateend = @fystart + '/10/01' ; -- FY 2015/16 Q2
--set @datestart = @fystart + '/09/30'	;	set @dateend = @fyend   + '/01/01' ; -- FY 2015/16 Q3
--set @datestart = @fystart + '/12/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16 Q4

/*

Tag all records with an alcohol related attributable fraction

Filters records by pattern class, finished episode, epidsode type

 - NO geography filter
 - NO harm-only (i.e. af > 0) filter

Tags all alcohol related diagnosis

Any non-related set as (NULL) with af as zero.

Includes measures related to further analysis for speciifc measures - i.e.

 - diagnosis code position (1 is primary)
 - condition status (external or other)
 - rank (based on [af] DESC [pos] ASC 
 
 USE GRID to match back to IP to do any further analysis re: demographics etc.
 
*/

;
WITH cte_expand_filter(GRID, GenderC, AgeBand_AA_Alt, xmlDiagPos)
AS
(
SELECT TOP 10000
	/* uid
	*/
	IP.Generated_Record_Identifier		AS [GRID]
	
	/* demographics
	*/
	, LEFT(ACGENDER.Description, 1)		AS [GenderC] -- MF
	, ABPH.Alcohol_Fraction_AgeBand		AS [AgeBand_AA_alt] -- axxyy | a75+
	
	/* clinical
	*/
	, CONVERT(xml
		, '<diag><pos>' +
			replace(IP.Diagnosis_ICD_Concatenated_D, ';', '</pos><pos>') +
			'</pos></diag>'
	) AS [DiagPos]
	
	FROM 
		[Public_Health].[dbo].[HES_IP]											AS IP
		
			LEFT JOIN [Shared_Reference].[dbo].[Age_Bands_Public_Health]		AS ABPH
				ON (
					(ABPH.[ESP_Year] = '2013') AND
					(IP.Age_at_Start_of_Episode_D = ABPH.Age_Years)
				)
				
			LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]			AS ACGENDER
				ON (ACGENDER.Field_Name = 'GENDER' AND ACGENDER.Code = IP.Gender)
	WHERE
			/* 
			* What - first episode and includes only finished episodes
			* Who - includes ordinary admissions (1), day cases (2) and 
				mothers and babies (5)
			* When - Events beteween dates specified
	        * Where
		    */
			(
				(IP.Consultant_Episode_Number = 1) AND
				(IP.Episode_Status = 3) AND
				(IP.Patient_Classification IN ('1', '2', '5'))
			)
			AND
			(
				(IP.Consultant_Episode_End_Date > @datestart) AND
				(IP.Consultant_Episode_End_Date < @dateend)
			))
SELECT *
	, t3.GRID
	, t3.icd10			as ar_diag_code
	, t3.pos			as ar_diag_pos
	, t3.aa_rank_1_highest as ar_diag_rank_1_highest
	
	, t3.af				as ar_frac
	, t3.af_nn			as ar_frac_nonneg
	
	, t3.uid			as ar_cond_uid
	, t3.[cause basis]	as ar_cond_cause_basis
	
FROM ( -- t3
SELECT *
	, ROW_NUMBER() OVER(PARTITION BY GRID ORDER BY t2.af_nn DESC, t2.pos ASC) AS [aa_rank_1_highest]

	FROM
	( -- t2
	SELECT
		GRID
		, unpvt.icd10
		, convert(integer, SUBSTRING(unpvt.Diags, 5, 2))			AS [pos]
		
		, LU_UID_ICD.uid

		, unpvt.[GenderC]
		, unpvt.[AgeBand_AA_Alt]

		, LU_AAF_AG.[af]
		, case when (af < 0) then 0 else af	END						AS [af_nn]
		
		, LU_AAC.[cause basis]
		
		FROM
			( -- t_expand -> unpvt
			SELECT
				cte_expand.GRID
				, cte_expand.[GenderC]
				, cte_expand.[AgeBand_AA_Alt]

				, xmlDiagPos.value('/diag[1]/pos[1]',  'varchar(4)') AS [Diag01]
				, xmlDiagPos.value('/diag[1]/pos[2]',  'varchar(4)') AS [Diag02]
				, xmlDiagPos.value('/diag[1]/pos[3]',  'varchar(4)') AS [Diag03]
				, xmlDiagPos.value('/diag[1]/pos[4]',  'varchar(4)') AS [Diag04]
				, xmlDiagPos.value('/diag[1]/pos[5]',  'varchar(4)') AS [Diag05]
				, xmlDiagPos.value('/diag[1]/pos[6]',  'varchar(4)') AS [Diag06]
				, xmlDiagPos.value('/diag[1]/pos[7]',  'varchar(4)') AS [Diag07]
				, xmlDiagPos.value('/diag[1]/pos[8]',  'varchar(4)') AS [Diag08]
				, xmlDiagPos.value('/diag[1]/pos[9]',  'varchar(4)') AS [Diag09]
				, xmlDiagPos.value('/diag[1]/pos[10]', 'varchar(4)') AS [Diag10]
				, xmlDiagPos.value('/diag[1]/pos[11]', 'varchar(4)') AS [Diag11]
				, xmlDiagPos.value('/diag[1]/pos[12]', 'varchar(4)') AS [Diag12]
				, xmlDiagPos.value('/diag[1]/pos[13]', 'varchar(4)') AS [Diag13]
				, xmlDiagPos.value('/diag[1]/pos[14]', 'varchar(4)') AS [Diag14]
				, xmlDiagPos.value('/diag[1]/pos[15]', 'varchar(4)') AS [Diag15]
				, xmlDiagPos.value('/diag[1]/pos[16]', 'varchar(4)') AS [Diag16]
				, xmlDiagPos.value('/diag[1]/pos[17]', 'varchar(4)') AS [Diag17]
				, xmlDiagPos.value('/diag[1]/pos[18]', 'varchar(4)') AS [Diag18]
				, xmlDiagPos.value('/diag[1]/pos[19]', 'varchar(4)') AS [Diag19]
				, xmlDiagPos.value('/diag[1]/pos[20]', 'varchar(4)') AS [Diag20]
				
				FROM cte_expand_filter
				
			) t_expand
		
		UNPIVOT
			(icd10 for Diags IN (
				[Diag01], [Diag02], [Diag03], [Diag04], [Diag05], [Diag06], [Diag07], [Diag08], [Diag09], [Diag10]
				, [Diag11], [Diag12], [Diag13], [Diag14], [Diag15], [Diag16], [Diag17], [Diag18], [Diag19], [Diag20]
				)
		) AS unpvt
		
		LEFT JOIN
			[ucs-bisqldev].[PHIIT].[dbo].[tmpIB__lu__uid_icd]			AS LU_UID_ICD
				ON (unpvt.icd10 = LU_UID_ICD.codes)

		LEFT JOIN
			[ucs-bisqldev].[PHIIT].[dbo].[tmpIB__aac]					AS LU_AAC
				ON (LU_UID_ICD.[uid] = LU_AAC.[condition uid])
				
		LEFT JOIN
			[ucs-bisqldev].[PHIIT].[dbo].[tmpIB__aaf_ag]				AS LU_AAF_AG
				ON (
					(LU_AAF_AG.[analysis type] IN ('any', 'morb')) AND
					(LU_UID_ICD.[uid] = LU_AAF_AG.[condition uid]) AND
					(unpvt.[GenderC] = LU_AAF_AG.[gender]) AND
					(unpvt.[AgeBand_AA_Alt] = LU_AAF_AG.[ageband aa alt])
				)
				
		WHERE
			(NOT LU_UID_ICD.uid IS NULL)
			
	) t2
	) t3
	
	ORDER BY
		[GRID] ASC
		, [aa_rank_1_highest] ASC
;

--GO


	



/*
--Create the table and insert values as portrayed in the previous example.
CREATE TABLE pvt (VendorID int, Emp1 int, Emp2 int,
    Emp3 int, Emp4 int, Emp5 int);
--GO
INSERT INTO pvt VALUES (1,4,3,5,4,4);
INSERT INTO pvt VALUES (2,4,1,5,5,5);
INSERT INTO pvt VALUES (3,4,3,5,4,4);
INSERT INTO pvt VALUES (4,4,2,5,5,4);
INSERT INTO pvt VALUES (5,5,1,5,5,5);
--GO
--Unpivot the table.
SELECT VendorID, Employee, Orders
FROM 
   (SELECT VendorID, Emp1, Emp2, Emp3, Emp4, Emp5
   FROM pvt) p
UNPIVOT
   (Orders FOR Employee IN 
      (Emp1, Emp2, Emp3, Emp4, Emp5)
)AS unpvt;
--GO;
*/

/*
WITH DatePeriods(ThisWeek,LastWeek,MonthToDate,QuarterToDate,YearToDate) AS
(
    SELECT  "...date functions..." AS ThisWeek
            "...date functions..." AS LastWeek
            "...date functions..." AS MonthToDate
            "...date functions..." AS QuarterToDate
            "...date functions..." AS YearToDate
)
SELECT Desciption,Value
FROM DatePeriods
UNPIVOT
(
    Value FOR Desciption IN (ThisWeek,LastWeek,MonthToDate,QuarterToDate,YearToDate)
) AS Source

*/

*/

/*

1Q - 3m28s - 63912 rows

*/

declare @datestart as datetime
declare @dateend as datetime

declare @fystart as varchar(4) ;
declare @fyend as varchar(4) ;

set @fystart = '2012' -- '2013' -- '2014' -- '2015'
set @fyend   = '2013' -- '2014' -- '2013' -- '2016'

--set @datestart = @fystart + '/03/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16
--set @datestart = @fystart + '/03/31'	;	set @dateend = @fystart + '/07/01' ; -- FY 2015/16 Q1
--set @datestart = @fystart + '/06/30'	;	set @dateend = @fystart + '/10/01' ; -- FY 2015/16 Q2
--set @datestart = @fystart + '/09/30'	;	set @dateend = @fyend   + '/01/01' ; -- FY 2015/16 Q3
set @datestart = @fystart + '/12/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16 Q4

;
WITH
/*
Select fields of relevance from HES IP and filter on record status re: 
patient classification and episode status
*/
cte_filter(GRID, GenderC, AgeBand_AA_Alt, xmlDiagPos)
AS
(
SELECT
	-- uid
	IP.Generated_Record_Identifier		AS [GRID]
	-- demographics
	, LEFT(ACGENDER.Description, 1)		AS [GenderC] -- MF
	, ABPH.Alcohol_Fraction_AgeBand		AS [AgeBand_AA_alt] -- axxyy | a75+
	-- clinical
	, CONVERT(xml
		, '<diag><pos>' +
			replace(IP.Diagnosis_ICD_Concatenated_D, ';', '</pos><pos>') +
			'</pos></diag>'
	)									AS [xmlDiagPos]
	
	FROM 
		[Public_Health].[dbo].[HES_IP]											AS IP
		
			LEFT JOIN [Shared_Reference].[dbo].[Age_Bands_Public_Health]		AS ABPH
				ON (
					(ABPH.[ESP_Year] = '2013') AND
					(IP.Age_at_Start_of_Episode_D = ABPH.Age_Years)
				)
				
			LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]			AS ACGENDER
				ON (ACGENDER.Field_Name = 'GENDER' AND ACGENDER.Code = IP.Gender)
	WHERE
		(
			-- What - first (admission) episode and includes only finished episodes
			(IP.Consultant_Episode_Number = 1) AND
			(IP.Episode_Status = 3) AND
			-- Who - includes ordinary admissions (1), day cases (2) and mothers and babies (5)
			(IP.Patient_Classification IN ('1', '2', '5'))
		)
		AND
		(
			-- When - Events between dates specified
			(IP.Consultant_Episode_End_Date > @datestart) AND
			(IP.Consultant_Episode_End_Date < @dateend)
		)
) -- cte_filter
/*
split diagnosis concatenated field into multiple fields
*/
, cte_expand(GRID, GenderC, AgeBand_AA_Alt
	, Diag01, Diag02, Diag03, Diag04, Diag05, Diag06, Diag07, Diag08, Diag09, Diag10
	, Diag11, Diag12, Diag13, Diag14, Diag15, Diag16, Diag17, Diag18, Diag19, Diag20
)
AS
(
	SELECT
		cte_filter.GRID
		, cte_filter.[GenderC]
		, cte_filter.[AgeBand_AA_Alt]

		, xmlDiagPos.value('/diag[1]/pos[1]',  'varchar(4)') AS [Diag01]
		, xmlDiagPos.value('/diag[1]/pos[2]',  'varchar(4)') AS [Diag02]
		, xmlDiagPos.value('/diag[1]/pos[3]',  'varchar(4)') AS [Diag03]
		, xmlDiagPos.value('/diag[1]/pos[4]',  'varchar(4)') AS [Diag04]
		, xmlDiagPos.value('/diag[1]/pos[5]',  'varchar(4)') AS [Diag05]
		, xmlDiagPos.value('/diag[1]/pos[6]',  'varchar(4)') AS [Diag06]
		, xmlDiagPos.value('/diag[1]/pos[7]',  'varchar(4)') AS [Diag07]
		, xmlDiagPos.value('/diag[1]/pos[8]',  'varchar(4)') AS [Diag08]
		, xmlDiagPos.value('/diag[1]/pos[9]',  'varchar(4)') AS [Diag09]
		, xmlDiagPos.value('/diag[1]/pos[10]', 'varchar(4)') AS [Diag10]
		, xmlDiagPos.value('/diag[1]/pos[11]', 'varchar(4)') AS [Diag11]
		, xmlDiagPos.value('/diag[1]/pos[12]', 'varchar(4)') AS [Diag12]
		, xmlDiagPos.value('/diag[1]/pos[13]', 'varchar(4)') AS [Diag13]
		, xmlDiagPos.value('/diag[1]/pos[14]', 'varchar(4)') AS [Diag14]
		, xmlDiagPos.value('/diag[1]/pos[15]', 'varchar(4)') AS [Diag15]
		, xmlDiagPos.value('/diag[1]/pos[16]', 'varchar(4)') AS [Diag16]
		, xmlDiagPos.value('/diag[1]/pos[17]', 'varchar(4)') AS [Diag17]
		, xmlDiagPos.value('/diag[1]/pos[18]', 'varchar(4)') AS [Diag18]
		, xmlDiagPos.value('/diag[1]/pos[19]', 'varchar(4)') AS [Diag19]
		, xmlDiagPos.value('/diag[1]/pos[20]', 'varchar(4)') AS [Diag20]
		
		FROM cte_filter
) -- cte_expand
/*
melt diagnosis fields onto (icd10code, value)
*/
, cte_melt(GRID, icd10, pos, GenderC, AgeBand_AA_Alt)
AS
(
SELECT
	GRID
	, unpvt.icd10
	, CONVERT(integer, SUBSTRING(unpvt.Diags, 5, 2))	AS [pos]
	, unpvt.[GenderC]
	, unpvt.[AgeBand_AA_Alt]
	
	FROM cte_expand
UNPIVOT
	(icd10 for Diags IN (
		  [Diag01], [Diag02], [Diag03], [Diag04], [Diag05], [Diag06], [Diag07], [Diag08], [Diag09], [Diag10]
		, [Diag11], [Diag12], [Diag13], [Diag14], [Diag15], [Diag16], [Diag17], [Diag18], [Diag19], [Diag20]
		)
	) AS unpvt
) -- cte_melt
/*
Tag on the alcohol related attributable fraction based on condition, age and gender
*/
, cte_tag_af(GRID, icd10, pos, uid, af, [cause basis])
AS
(
SELECT
	GRID
	, icd10
	, pos
	, LU_UID_ICD.[uid]
	, LU_AAF_AG.[af]
	, LU_AAC.[cause basis]
	
	FROM cte_melt
	
		LEFT JOIN
			[ucs-bisqldev].[PHIIT].[dbo].[tmpIB__lu__uid_icd]			AS LU_UID_ICD
				ON (cte_melt.icd10 = LU_UID_ICD.codes)

		LEFT JOIN
			[ucs-bisqldev].[PHIIT].[dbo].[tmpIB__aac]					AS LU_AAC
				ON (LU_UID_ICD.[uid] = LU_AAC.[condition uid])
				
		LEFT JOIN
			[ucs-bisqldev].[PHIIT].[dbo].[tmpIB__aaf_ag]				AS LU_AAF_AG
				ON (
					(LU_AAF_AG.[analysis type] IN ('any', 'morb')) AND
					(LU_UID_ICD.[uid] = LU_AAF_AG.[condition uid]) AND
					
					(cte_melt.[GenderC] = LU_AAF_AG.[gender]) AND
					(cte_melt.[AgeBand_AA_Alt] = LU_AAF_AG.[ageband aa alt])
				)

		WHERE
			(NOT LU_UID_ICD.uid IS NULL) AND
			(NOT LU_AAF_AG.af IS NULL)
	
) -- cte_tag_af
/*
Main - start the chain
*/
--SELECT * FROM (
--	SELECT * FROM cte_expand -- cte_tag_af
	SELECT * FROM cte_tag_af
--	) t
--	ORDER BY GRID ASC, af DESC, pos ASC
;
