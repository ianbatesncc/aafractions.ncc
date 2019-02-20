/*

Apply methods

 - alcohol-related (narrow)
-- - alcohol-related (broad)
 - alcohol-specific

*/

use Public_Health
;
GO

/*

Set date range

- just to limit size of query

*/

declare @datestart as datetime
declare @dateend as datetime

declare @fystart as varchar(4) ;
declare @fyend as varchar(4) ;

set @fystart = '2015' /* -- '2012' '2013' -- '2014' -- '2015' */
set @fyend   = '2016' /* -- '2013' '2014' -- '2013' -- '2016' */

set @datestart = @fystart + '/03/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16
--set @datestart = @fystart + '/03/31'	;	set @dateend = @fystart + '/07/01' ; -- FY 2015/16 Q1
--set @datestart = @fystart + '/06/30'	;	set @dateend = @fystart + '/10/01' ; -- FY 2015/16 Q2
--set @datestart = @fystart + '/09/30'	;	set @dateend = @fyend   + '/01/01' ; -- FY 2015/16 Q3
--set @datestart = @fystart + '/12/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16 Q4


/*

analysis type

Mortality or morbidity - alters value of Alcohol related attributable fraction

*/

declare @analysistype as nvarchar(16)

--set @analysistype = 'mort' -- TODO
set @analysistype = 'morb'

declare @analysismethod as nvarchar(32)
set @analysismethod = 'alcohol-related (broad)'
--set @analysismethod = 'alcohol-related (narrow)'
--set @analysismethod = 'alcohol-specific'


/*

main

*/
;
WITH
/*
Select fields of relevance from HES IP and filter on record status re: 
patient classification and episode status
*/
cte_adjustage
AS (
SELECT
	*
	--, case when IP.Age_at_Start_of_Episode_D > 7000 then 0 else IP.Age_at_Start_of_Episode_D end as [Age_at_Start_of_Episode_D__adj]
	, CASE
		WHEN (NOT IP.Age_at_Start_of_Episode_D IS NULL) THEN
			CASE WHEN (IP.Age_at_Start_of_Episode_D > 7000) THEN 0 ELSE IP.Age_at_Start_of_Episode_D	END
		ELSE
			CASE WHEN (IP.Age_On_Admission > 7000)			THEN 0 ELSE IP.Age_On_Admission				END
		END
															AS [Age_at_Start_of_Episode_D__adj]
	FROM [Public_Health].[dbo].[HES_IP] as IP
) -- /cte_adjustage
,
cte_filter(data_source, [aa method], GenderC, [Age_SYOA], [AgeBand_ESP], af, [condition uid], LADCD)
AS (
SELECT
	'HES IP with local AF calculation'	AS [data_source]
	, PHIT_IP.[aa method]				AS [AA method]
	-- uid
--	, IP.Generated_Record_Identifier	AS [GRID]
	-- demographics
	, LEFT(ACGENDER.Description, 1)		AS [GenderC] -- MF
--	, IP.Age_at_Start_of_Episode_D		AS [Age_SYOA]
	, IP.Age_at_Start_of_Episode_D__adj	AS [Age_SYOA]
	, ABPH.AgeBand_ESP					AS [AgeBand_ESP] -- x[x]-y[y] | a90+
	-- clinical
	, PHIT_IP.af						AS [af]
--	, AAC.[condition desc]
--	, AAC.[condition cat2]
	, AAC.[condition uid]
	-- where
	, IP.Local_Authority_District		AS [LADCD]
	
	FROM 
		--[Public_Health].[dbo].[HES_IP]											AS IP
		cte_adjustage															AS IP
		
			INNER JOIN [ucs-bisqldev].PHIIT.dbo.tmpIB__PHIT_IP__aamethod		AS PHIT_IP
				ON (
					(PHIT_IP.[aa method] = @analysismethod) AND
					(PHIT_IP.[GRID] = IP.Generated_Record_Identifier)
				)

			LEFT JOIN [ucs-bisqldev].PHIIT.dbo.tmpIB__aac						AS AAC
				ON (AAC.[condition uid] = PHIT_IP.[uid])
				
			LEFT JOIN [Shared_Reference].[dbo].[Age_Bands_Public_Health]		AS ABPH
				ON (
					(ABPH.[ESP_Year] = '2013') AND
					(IP.Age_at_Start_of_Episode_D__adj = ABPH.Age_Years)
				)
				
			LEFT JOIN [Shared_Reference].[dbo].[Administrative_Codes]			AS ACGENDER
				ON (ACGENDER.Field_Name = 'gender' AND ACGENDER.Code = IP.Gender)
				
				
	WHERE
		(
			-- When - Events between dates specified
			(IP.Consultant_Episode_End_Date > @datestart) AND
			(IP.Consultant_Episode_End_Date < @dateend)
		)
		AND
		(
			-- where
			(IP.Local_Authority_District in (
				'E06000018'
	            , 'E07000170', 'E07000171', 'E07000172', 'E07000173'
	            , 'E07000174', 'E07000175', 'E07000176'
			))
            -- or (IP.CCG_of_Residence in ('04K', '02Q', '04E', '04H', '04L', '04M', '04N'))
		)
) -- /cte_filter
--SELECT * FROM cte_filter WHERE AgeBand_ESP is null ;
,
cte_tag_conditions(data_source, [aa method], GenderC, [AgeBand_ESP], af, [condition group], LADCD)
AS (
	SELECT
		data_source, [aa method], GenderC, 'All ages' AS [AgeBand_ESP], af
		, case
			when [condition uid] in (136, 137, 138, 139, 141, 143)	then '1: Alcohol related cardiovascular disease conditions (9.03) (broad)'
			when [condition uid] in (102)							then '2,5: Mental and behavioural disorders (9.04, 10.04) (broad, narrow resp.)'
			when [condition uid] in (108)							then '3: Alcoholic liver disease (9.05) (broad)'
			when [condition uid] in (157, 159, 161, 163, 165, 167)	then '4: Unintentional injuries (10.03) (related narrow)'
			when [condition uid] in (117)							then '6: Intentional self poisoning (10.05) (related narrow)'
		end															AS [condition group]
		, LADCD
		FROM cte_filter
		WHERE [condition uid] in (
			  136, 137, 138, 139, 141, 143
			, 102
			, 108
			, 157, 159, 161, 163, 165, 167
			, 117
		)
) -- /cte_tag_conditions
,
cte_tag_broad_agebands(data_source, [aa method], GenderC, [AgeBand_ESP], af, [condition group], LADCD)
AS
(
SELECT
	data_source
	, [aa method]
	, GenderC
	, case 
		when [Age_SYOA] > 120		then '4: WARNING: Over 120 yrs'
		when [Age_SYOA] > 64		then '3: Over 65s (10.08) (related narrow)'
		when [Age_SYOA] > 39 		then '2: 40-64 yrs (10.07) (related narrow)'
		when [Age_SYOA] >= 0		then '1: Under 40s (10.06) (related narrow)'
		else						'WARNING: Unknown age'
	end								AS [AgeBand_ESP]
	, af
	, 'All conditions' AS [condition group]
	, LADCD
	FROM cte_filter
	
UNION ALL

SELECT 
	data_source, [aa method], GenderC
	, '0: Under 18 (5.02) (specific)' as [AgeBand_ESP], af
	, 'All conditions' AS [condition group]
	, LADCD
	FROM cte_filter
	WHERE ([AGE_SYOA] between 0 AND 17) -- OR (AGE_SYOA > 7000)
	
) -- /cte_tag_broad_agebands
,
cte_count_broadageband_gender_lad(data_source, [aa method], GenderC, [AgeBand_ESP], LADCD, [condition group], nRecords, nAttributable)
AS
(
SELECT
	data_source
	, [aa method]
	, GenderC
	, [AgeBand_ESP]
	, LADCD
	, [condition group]
	, COUNT(*) as nRecords
	, SUM(af) as nAttributable
	
	FROM (
		SELECT
			data_source, [aa method], GenderC
			, 'All ages' AS [AgeBand_ESP], af
			, convert(nvarchar(4), AAC.[condition uid]) + ': ' + AAC.[icd codes] + ': ' + AAC.[condition desc] AS [condition group]
			, LADCD
			
			FROM cte_filter
				LEFT JOIN [ucs-bisqldev].PHIIT.dbo.tmpIB__aac AS AAC
					ON (cte_filter.[condition uid] = AAC.[condition uid])
		
		UNION ALL
		
		SELECT data_source, [aa method], GenderC
			, 'All ages' as [AgeBand_ESP], af
			, 'All conditions' AS [condition group], LADCD
			FROM cte_filter
	
		UNION ALL
		
		SELECT * FROM cte_tag_broad_agebands
		
		UNION ALL
		
		SELECT * FROM cte_tag_conditions
	) u
	
	GROUP BY
		data_source
		, [aa method]
		, GenderC
		, [AgeBand_ESP]
		, LADCD
		, [condition group]
) -- /cte_count_broadageband_gender_lad
,
cte_sump(data_source, [aa method], GenderC, [AgeBand_ESP], LADCD, [condition group], nRecords, nAttributable)
AS
(
SELECT
	data_source, [aa method], GenderC, AgeBand_ESP, LADCD, [condition group], nRecords, nAttributable
	FROM cte_count_broadageband_gender_lad
	
UNION ALL

SELECT
	data_source, [aa method], 'P' AS GenderC, AgeBand_ESP, LADCD, [condition group], sum(nRecords), sum(nAttributable)
	FROM cte_count_broadageband_gender_lad
	GROUP BY data_source, [aa method], AgeBand_ESP, LADCD, [condition group]
) -- /cte_sump
,
cte_sum_utla(data_source, [aa method], GenderC, [AgeBand_ESP], LADCD, [condition group], nRecords, nAttributable)
AS
(
SELECT * from cte_sump

UNION ALL

SELECT
	data_source, [aa method], GenderC, AgeBand_ESP, 'E10000024' AS LADCD, [condition group], sum(nRecords), sum(nAttributable)
	FROM cte_sump
	WHERE (LEFT(cte_sump.LADCD, 3) = 'E07')
	GROUP BY data_source, [aa method], GenderC, AgeBand_ESP, [condition group]

) -- /cte_sum_utla
SELECT * from cte_sum_utla
	WHERE
		LADCD IN ('E10000024' ,'E06000018') AND
		GenderC in ('P')
	ORDER BY
		LADCD ASC
		, AgeBand_ESP ASC
		, GenderC DESC
		, [condition group] ASC
;
GO