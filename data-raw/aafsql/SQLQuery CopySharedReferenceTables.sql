
USE PHIIT
;
GO

/*

Copy tables to PHIIT to ellow executaion plan estimation.

*/

-- Administrative Codes - Gender

/* copy shared reference and AG Bands Public Health to allow exeuctaion plan investigation
*/
IF OBJECT_ID('[PHIIT].[dbo].[Administrative_Codes]') IS NOT NULL
BEGIN
DROP TABLE PHIIT.dbo.[Administrative_Codes]
END
;
GO

SELECT * INTO [Administrative_Codes]
FROM [ucs-bisqldb].[Shared_Reference].[dbo].[Administrative_Codes] AS AC
	WHERE (AC.[Field_Name] = 'gender')
;
GO
	
CREATE UNIQUE CLUSTERED INDEX [ix_fieldname_code_group] ON [dbo].[Administrative_Codes] 
(
	[Field_Name] ASC,
	[Code] ASC,
	[Group] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

-- AgeBand Public Health

IF OBJECT_ID('[PHIIT].dbo.[Age_Bands_Public_Health]') IS NOT NULL
BEGIN
DROP TABLE [PHIIT].dbo.[Age_Bands_Public_Health]
END
;
GO

SELECT * INTO [PHIIT].dbo.[Age_Bands_Public_Health]
FROM [ucs-bisqldb].[Shared_Reference].[dbo].[Age_Bands_Public_Health]
;
GO

CREATE UNIQUE CLUSTERED INDEX [ix_AgeYears_ESPYear_AgeBandESP] ON [dbo].[Age_Bands_Public_Health] 
(
	[Age_Years] ASC,
	[ESP_Year] ASC,
	[AgeBand_ESP] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [ix_AgeBandESP_ESPYear] ON [dbo].[Age_Bands_Public_Health] 
(
	[AgeBand_ESP] ASC,
	[ESP_Year] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

