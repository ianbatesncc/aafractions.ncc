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

--set @fystart = '2015' /* -- '2012' '2013' -- '2014' -- '2015' */
set @fystart = '2015' /* -- '2012' '2013' -- '2014' -- '2015' */
set @fyend   = '2016' /* -- '2013' '2014' -- '2013' -- '2016' */

set @datestart = @fystart + '/03/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16
--set @datestart = @fystart + '/03/31'	;	set @dateend = @fystart + '/07/01' ; -- FY 2015/16 Q1
--set @datestart = @fystart + '/06/30'	;	set @dateend = @fystart + '/10/01' ; -- FY 2015/16 Q2
--set @datestart = @fystart + '/09/30'	;	set @dateend = @fyend   + '/01/01' ; -- FY 2015/16 Q3
--set @datestart = @fystart + '/12/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16 Q4


/*

analysis type

Mortality or morbidity - alters falue of Aalcohol related attributable fraction

*/

declare @analysistype as nvarchar(16)

--set @analysistype = 'mort' -- TODO
set @analysistype = 'morb'

declare @analysismethod as nvarchar(32)
--set @analysismethod = 'alcohol-related (broad)'
--set @analysismethod = 'alcohol-related (narrow)'
set @analysismethod = 'alcohol-specific'


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
cte_filter(data_source, date_start, date_end, [aa method], GenderC, [Age_SYOA], [AgeBand_ESP], af, LADCD, LSOA11CD)
AS (
SELECT
	'HES IP with local AF calculation'	AS [data_source]

	, @datestart						AS [date_start]
	, @dateend							AS [date_end]

	, PHIT_IP.[aa method]				AS [AA method]

	-- demographics
	, LEFT(ACGENDER.Description, 1)		AS [GenderC] -- MF
	, IP.Age_at_Start_of_Episode_D__adj	AS [Age_SYOA]
	, ABPH.AgeBand_ESP					AS [AgeBand_ESP] -- x[x]-y[y] | a90+

	-- clinical
	, PHIT_IP.af						AS [af]

	-- where
	, IP.Local_Authority_District		AS [LADCD]
	, IP.GIS_LSOA_2011_D				AS [LSOA11CD]
	
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
cte_tag_u18(data_source, date_start, date_end, [aa method], GenderC, [AgeBand_ESP], af, LADCD, LSOA11CD)
AS (
SELECT 
	data_source, date_start, date_end, [aa method], GenderC
	, '0: Under 18 (5.02) (specific)' as [AgeBand_ESP]
	, af
	, LADCD, LSOA11CD
	FROM cte_filter
	WHERE ([AGE_SYOA] between 0 AND 17) -- OR (AGE_SYOA > 7000)
	
) -- /cte_tag_u18
--SELECT top 100 * from cte_tag_u18 ;
,
cte_aggegate_over__ageband(data_source, date_start, date_end, [aa method], GenderC, [AgeBand_ESP], LADCD, LSOA11CD, nRecords, nAttributable)
AS (
SELECT
	data_source
	, date_start
	, date_end
	, [aa method]
	, GenderC
	, [AgeBand_ESP]
	, LADCD
	, LSOA11CD

	, COUNT(*) as nRecords
	, SUM(af) as nAttributable
	
	FROM (
		-- All ages, all conditions
		SELECT data_source, date_start, date_end, [aa method], GenderC
			, 'All ages' as [AgeBand_ESP], af
			, LADCD, LSOA11CD
			FROM cte_filter
	
		UNION ALL
		
		-- broad age bands
		SELECT * FROM cte_tag_u18
	) u
	
	GROUP BY
		data_source
		, date_start
		, date_end
		, [aa method]
		, GenderC
		, [AgeBand_ESP]
		, LADCD
		, LSOA11CD
) -- /cte_aggegate_over__ageband
--select top 100 * from cte_aggegate_over__ageband ;
,
cte_sump(data_source, date_start, date_end, [aa method], GenderC, [AgeBand_ESP], LADCD, LSOA11CD, nRecords, nAttributable)
AS (
	SELECT
		data_source, date_start, date_end, [aa method], GenderC, AgeBand_ESP, LADCD, LSOA11CD
		, nRecords, nAttributable
		FROM cte_aggegate_over__ageband
		
	UNION ALL

	SELECT
		data_source, date_start, date_end, [aa method], 'P' AS GenderC, AgeBand_ESP, LADCD, LSOA11CD
		, sum(nRecords), sum(nAttributable)
		FROM cte_aggegate_over__ageband
		GROUP BY data_source, date_start, date_end, [aa method], AgeBand_ESP, LADCD, LSOA11CD
		
) -- /cte_sump
SELECT * FROM cte_sump ;

/*
,
cte_sum_utla(data_source, date_start, date_end, [aa method], GenderC, [AgeBand_ESP], LADCD, LSOA11CD, [condition group], nRecords, nAttributable)
AS (
-- full detail
SELECT * from cte_sump

UNION ALL

-- County Subtotal
SELECT
	data_source, date_start, date_end, [aa method], GenderC, AgeBand_ESP
	, 'E10000024' AS LADCD, 'All LSOAS' as LSOA11CD
	, [condition group]
	, sum(nRecords), sum(nAttributable)
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
*/