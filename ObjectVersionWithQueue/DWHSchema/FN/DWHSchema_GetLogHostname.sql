CREATE FUNCTION [DWHSchema].[GetLogHostname]
(	
	@hostname  nvarchar(100),
	@startdate datetime,
	@enddate   datetime 
)
RETURNS @returntable TABLE
	(
	 [id]				bigint
	 ,[ref]				xml
	 ,[username]		nvarchar(100)
	 ,[hostname]		nvarchar(100)
	 ,[curdate]			datetime2
	 ,[curobj]			xml
	 ,[refuuid]			nvarchar(36)
	 ,[sizeCurObj]		bigint
	 ,[curobj_checksum]	bigint
	)


AS
BEGIN
	DECLARE @interval int = 3;
	IF (DATEDIFF(DAY, @startdate, @enddate) > @interval) BEGIN
		--RAISERROR (51000, -1, -1, 'Time interval set too long.');
		INSERT INTO @returntable ([username],[curdate]) values ('Time interval set too long. Dataset is stripped. And many more lines not shown ...',@startdate); 
		SET @startdate =  DATEADD(day,-@interval,@enddate);
	END;

	INSERT INTO @returntable ([id] ,[ref],[username],[hostname],[curdate],[curobj],[refuuid],[sizeCurObj],[curobj_checksum]) 
	SELECT  
	   v.[id]
      ,v.[ref]
      ,v.[username]
      ,v.[hostname]
      ,v.[curdate]
      ,CONVERT(xml,DECOMPRESS(vs.[curobj])) as [curobj]
      ,v.[refuuid]
	  ,DATALENGTH(vs.[curobj]) sizeCurObj
	  ,v.[curobj_checksum]

	  FROM [DWHSchema].[VersionsCompress] v (NOLOCK)
		LEFT JOIN [DWHSchema].[VersionsObjectStorage] vs (NOLOCK)
		ON v.[curobj_checksum] = vs.[curobj_checksum] and v.[refuuid]=vs.[refuuid]
	  WHERE  1=1
	  and [curdate]  between @startdate and @enddate
	  and hostname = @hostname
	  ;

	INSERT INTO @returntable ([id] ,[ref],[username],[hostname],[curdate],[curobj],[refuuid],[sizeCurObj],[curobj_checksum]) 
	SELECT  
	   v.[id]
      ,v.[ref]
      ,v.[username]
      ,v.[hostname]
      ,v.[curdate]
      ,CONVERT(xml,DECOMPRESS(vs.[curobj])) as [curobj]
      ,v.[refuuid]
	  ,DATALENGTH(vs.[curobj]) sizeCurObj
	  ,v.[curobj_checksum]

	  FROM [DWHSchema].[VersionsCompress2] v (NOLOCK)
		LEFT JOIN [DWHSchema].[VersionsObjectStorage] vs (NOLOCK)
		ON v.[curobj_checksum] = vs.[curobj_checksum] and v.[refuuid]=vs.[refuuid]
	  WHERE  1=1
	  and [curdate]  between @startdate and @enddate
	  and hostname = @hostname
	  ;


	RETURN;

END
GO

GRANT SELECT ON [DWHSchema].[GetLogHostname]
    TO [ObjectVersionCommonRole]; 
GO