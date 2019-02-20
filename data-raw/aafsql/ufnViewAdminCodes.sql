/*

To create in ucs-bisqldev.phiit

*/

USE [PHIIT]
GO

/****** Object:  UserDefinedFunction [dbo].[ufnViewAdminCodes]    Script Date: 03/01/2018 11:25:24 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ufnViewAdminCodes]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[ufnViewAdminCodes]
GO

USE [PHIIT]
GO

/****** Object:  UserDefinedFunction [dbo].[ufnViewAdminCodes]    Script Date: 03/01/2018 11:25:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[ufnViewAdminCodes]
(
	@sField as varchar(256) 
)
RETURNS TABLE
AS
RETURN (
	SELECT *
		FROM [ucs-bisqldb].[Shared_Reference].[dbo].[Administrative_Codes]
		WHERE ([Field_name] = @sField)
)
;



GO


