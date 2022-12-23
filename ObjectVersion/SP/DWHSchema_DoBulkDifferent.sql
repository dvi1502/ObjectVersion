CREATE PROCEDURE [DWHSchema].[DoBulkDifferent] 
	@startDate datetime 
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @RefUUID varchar(36);
	DECLARE @i int = 0;
	DECLARE @ii int = 0;
	DECLARE @Status0 int = 0;
	DECLARE @Status1 int = -1;


	UPDATE [DWHSchema].[versions] SET [status] = @Status0
	WHERE 1=1 AND [status] is null

	DECLARE cur123 CURSOR FOR 
		SELECT DISTINCT [refuuid]
		FROM [DWHSchema].[versions] 
		WHERE [status] = 0 
		;

	OPEN cur123;

	FETCH NEXT FROM cur123 INTO @RefUUID;
	WHILE  @@FETCH_STATUS=0 BEGIN

		EXECUTE @ii = [DWHSchema].[DoDfferentObj2] @RefUUID,@Status0,@Status1;
		SET @i = @i + @ii;

		UPDATE [DWHSchema].[versions] 
		SET [status] = @Status1
		WHERE	[refuuid] = @RefUUID 
			AND [status] = @Status0

		FETCH NEXT FROM cur123 INTO @RefUUID;
	END;

	CLOSE cur123;
	DEALLOCATE cur123;


	INSERT INTO [DWHSchema].[VersionsCompress]([id],[ref],[dbname],[username],[curdate],[curobj],[refuuid],[hostname],[docdate],[status],[typeObj],[curobj_checksum],[curobj_hashbytes])
	SELECT [id],[ref],[dbname],[username],[curdate],
	NULL,
	[refuuid],[hostname],[docdate],-1,[typeObj],CHECKSUM(CAST([curobj] as nvarchar(max))),HASHBYTES('SHA2_256',CAST([curobj] as nvarchar(max))) 
	FROM [DWHSchema].[versions] WHERE [Status] = @Status1;

	MERGE INTO [DWHSchema].[VersionsObjectStorage] as dest
	USING (

		SELECT [curobj_checksum],[curobj_hashbytes],[refuuid],MAX([curobj]) 
		FROM (
			SELECT 
				CHECKSUM(CAST([curobj] as nvarchar(max))) as [curobj_checksum],
				HASHBYTES('SHA2_256',CAST([curobj] as nvarchar(max))) as [curobj_hashbytes],
				[refuuid],
				COMPRESS(CONVERT(nvarchar(max),[curobj])) as [curobj]  
			FROM [DWHSchema].[Versions] 
			WHERE [Status] = @Status1
		) AS xx0 
		GROUP BY [curobj_checksum],[curobj_hashbytes],[refuuid]

		) AS src ([curobj_checksum],[curobj_hashbytes],[refuuid],[curobj])
		ON dest.[curobj_checksum] = src.[curobj_checksum] and dest.[refuuid]=src.[refuuid]
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT ([curobj_checksum],[curobj_hashbytes],[refuuid],[curobj])
			VALUES ( src.[curobj_checksum],src.[curobj_hashbytes],src.[refuuid],src.[curobj])
	;

	DELETE FROM [DWHSchema].[Versions] WHERE [Status] = @Status1;


	RETURN @i

END
GO