
CREATE FUNCTION [DWHSchema].[GetObjVersions](	
	@RefUUID varchar(36),
	@dbname varchar(36) = ''
)
RETURNS TABLE 
AS
RETURN 
(

	SELECT TOP 1000
	   v.[id]
      ,v.[ref]
      ,v.[username]
      ,v.[hostname]
      ,v.[curdate]
      , CONVERT(xml,DECOMPRESS(vs.[curobj])) as [curobj]
      ,v.[refuuid]
	  ,v.[dbid]
	  ,DATALENGTH(vs.[curobj]) sizeCurObj
	  ,v.[curobj_checksum]

		FROM [DWHSchema].[VersionsCompress] v (NOLOCK) 
		LEFT JOIN [DWHSchema].[VersionsObjectStorage] vs (NOLOCK)
		ON v.[curobj_checksum] = vs.[curobj_checksum] and v.[refuuid]=vs.[refuuid]
		WHERE v.[refuuid] = @RefUUID 

	UNION ALL

	SELECT TOP 1000
	   v.[id]
      ,v.[ref]
      ,v.[username]
      ,v.[hostname]
      ,v.[curdate]
      , CONVERT(xml,DECOMPRESS(vs.[curobj])) as [curobj]
      ,v.[refuuid]
	  ,v.[dbid]
	  ,DATALENGTH(vs.[curobj]) sizeCurObj
	  ,v.[curobj_checksum]

		FROM [DWHSchema].[VersionsCompress2] v (NOLOCK) 
		LEFT JOIN [DWHSchema].[VersionsObjectStorage] vs (NOLOCK)
		ON v.[curobj_checksum] = vs.[curobj_checksum] and v.[refuuid]=vs.[refuuid]
		WHERE v.[refuuid] = @RefUUID 


)

GO

GRANT SELECT ON [DWHSchema].[GetObjVersions]
    TO [ObjectVersionCommonRole]; 
GO