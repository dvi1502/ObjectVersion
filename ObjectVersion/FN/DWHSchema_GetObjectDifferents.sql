CREATE FUNCTION [DWHSchema].[GetObjectDifferents]
(
	@RefUUID varchar(36)
	
)
RETURNS @ver TABLE (
	 [_CurID]		bigint
	,[_PrevID]		bigint
    ,[_key]		nvarchar(100)
    ,[_newVal]	nvarchar(max)
    ,[_oldVal]	nvarchar(max)
	)

AS
BEGIN

	DECLARE @tbl TABLE (
		[id] bigint
	);

	INSERT INTO @tbl
	SELECT ID 
		FROM [DWHSchema].[Versions] WITH (NOLOCK)
		WHERE [refuuid] = @RefUUID 
	UNION ALL
	SELECT v.[id]
		FROM [DWHSchema].[VersionsCompress] v (NOLOCK) 
		LEFT JOIN [DWHSchema].[VersionsObjectStorage] vs (NOLOCK)
		ON v.[curobj_checksum] = vs.[curobj_checksum] and v.[refuuid]=vs.[refuuid]
		WHERE v.[refuuid] = @RefUUID 
	;

	INSERT INTO @ver
		SELECT 
			   [version_id]			as [_CurID]
			  ,[version_perv]		as [_PrevID]
			  ,[key]				as [_key]
			  ,[newVal]				as [_newVal]
			  ,[oldVal]				as [_oldVal]
		  FROM [DWHSchema].[Differents] WITH (NOLOCK)
  				WHERE [version_id] IN 
				(SELECT id FROM @tbl);
		

	RETURN;

END

GO

GRANT SELECT ON [DWHSchema].[GetObjectDifferents]
    TO [ObjVerUser]; 
GO