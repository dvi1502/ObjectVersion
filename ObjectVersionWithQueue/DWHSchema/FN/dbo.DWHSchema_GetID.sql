CREATE FUNCTION [DWHSchema].[GetID]
(	
	@TypeID nvarchar(150),
	@refid bigint
)
RETURNS TABLE 
AS
RETURN 
(
SELECT [refid], MAX(id) VerID
		FROM [DWHSchema].[VersionsCompress2] (NOLOCK) 
		WHERE ((ID > @refid)OR(@refid is null)) 
		AND [typeObj] = @TypeID
		GROUP BY [refid]
)
GO

GRANT SELECT ON [DWHSchema].[GetID] TO [ObjectVersionCommonRole]; 
GO

GRANT SELECT ON [DWHSchema].[GetID] TO [Guest]; 
GO
