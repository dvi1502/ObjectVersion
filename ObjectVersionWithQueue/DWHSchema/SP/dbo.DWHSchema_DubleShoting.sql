CREATE PROCEDURE [DWHSchema].[DWHSchema_DubleShoting]
	@countR int = 50
AS
BEGIN

	DECLARE 
	 @refuuid varchar(36)
	,@id bigint
	,@checksum bigint
	,@username varchar(150)
	,@sc int = 0;


	DECLARE cur CURSOR FOR
	SELECT [refuuid],[curobj_checksum],[username],[id]
	FROM (
		SELECT TOP(10000) [refuuid],[curobj_checksum],[username],count(*) as c,min(id) as [id]
		  FROM [DWHSchema].[VersionsCompress2]
		  GROUP BY [refuuid],[curobj_checksum],[username]
		  HAVING count(*) > @countR
	) as tbb;

	OPEN cur;
	FETCH NEXT FROM cur INTO @refuuid,@checksum,@username,@id;
	WHILE @@FETCH_STATUS=0 BEGIN

		DELETE FROM [DWHSchema].[VersionsCompress2]
		WHERE [refuuid]=@refuuid and [curobj_checksum]=@checksum and [username]=@username
		AND id <> @id;
	
		IF (@sc%100 =0)	PRINT @sc;
		SET @sc = @sc + 1;
	
		FETCH NEXT FROM cur INTO @refuuid,@checksum,@username,@id;
	END;

	CLOSE cur;
	DEALLOCATE cur;

	RETURN 0;

END
GO

GRANT EXECUTE ON [DWHSchema].[DWHSchema_DubleShoting]
    TO [ObjectVersionCommonRole]; 
GO