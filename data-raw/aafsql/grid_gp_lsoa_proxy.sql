/*

skinny file for gp to lsoa by population distribution

- sample from distribution
- not distribution weighted

*/

--
-- skinny file storage
--


USE [PHIIT]
GO

/****** Object:  Table [dbo].[tmpIB__PHIT_IP__aamethod]    Script Date: 03/01/2018 11:45:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

/* Clear table or create
*/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tmpIB__GP_LSOA_PROXY__PHIT_IP]') AND type in (N'U'))
	DELETE FROM [dbo].[tmpIB__GP_LSOA_PROXY__PHIT_IP]
ELSE
	BEGIN
	CREATE TABLE [dbo].[tmpIB__GP_LSOA_PROXY__PHIT_IP](
		[GRID]				[bigint]			NULL
		, [practice_code]	[varchar](10)		NULL
		, [lsoa11cd]		[varchar](10)		NULL
	) ON [PRIMARY]
	;
	CREATE UNIQUE CLUSTERED INDEX [PK_grid_prac] ON [dbo].[tmpIB__GP_LSOA_PROXY__PHIT_IP]
	(
		[GRID]	ASC
		, [practice_code] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	END
GO

--SET ANSI_PADDING OFF
GO

--
-- date range
--


declare @datestart as datetime
declare @dateend as datetime

declare @fystart as varchar(4) ;
declare @fyend as varchar(4) ;

set @fystart = '2016' /* -- '2012' '2013' -- '2014' -- '2015' */
set @fyend   = '2017' /* -- '2013' '2014' -- '2013' -- '2016' */

set @datestart = @fystart + '/03/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16
--set @datestart = @fystart + '/03/31'	;	set @dateend = @fystart + '/07/01' ; -- FY 2015/16 Q1
--set @datestart = @fystart + '/06/30'	;	set @dateend = @fystart + '/10/01' ; -- FY 2015/16 Q2
--set @datestart = @fystart + '/09/30'	;	set @dateend = @fyend   + '/01/01' ; -- FY 2015/16 Q3
--set @datestart = @fystart + '/12/31'	;	set @dateend = @fyend   + '/04/01' ; -- FY 2015/16 Q4


--
-- extract gp data
--
;
WITH
cte_select
AS (
SELECT
	IP.Generated_Record_Identifier			AS GRID
	, IP.Practice_Code_of_Registered_GP		as practice_code
	, datepart(yyyy, IP.Consultant_Episode_End_Date) as calyear
	, datepart(qq, IP.Consultant_Episode_End_Date) as calquarter
	, IP.GIS_LSOA_2011_D						as lsoa11cd
	--, IP.GIS_Local_Authority_District_D
	--, IP.Local_Authority_District
	--, IP.CCG_of_Residence
	--, IP.Government_Office_Region

	FROM
		[ucs-bisqldb].[Public_Health].[dbo].[HES_IP]	AS IP
		
	WHERE
	(	
		-- Who - NUH
		(IP.provider_code_d = 'RX1') AND
		(IP.GIS_LSOA_2011_D IS NULL) AND
	
		-- When - Events between dates specified
		(IP.Consultant_Episode_End_Date > @datestart) AND
		(IP.Consultant_Episode_End_Date < @dateend)
	)
)

--select * from cte_select order by Local_authority_district ;

INSERT
	INTO tmpIB__GP_LSOA_PROXY__PHIT_IP
	SELECT
		GRID, practice_code, lsoa11cd
	FROM cte_select
;

select * FROM tmpIB__GP_LSOA_PROXY__PHIT_IP
;