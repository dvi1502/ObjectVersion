CREATE PROCEDURE [DWHSchema].[AddObjVersion]
     @dbuuid	varchar(36)
    ,@dbname	varchar(50)
	,@username	nvarchar(50)
    ,@ref		xml
    ,@curobj	xml
	,@hostname	nvarchar(50) = null
AS
	BEGIN TRY


		DECLARE @dbid INT;

		DECLARE @x TABLE ([name] nvarchar(1512),[uuid] nvarchar(36), [enable] binary(1), [dbid] smallint);
		INSERT INTO @x VALUES (@dbname, @dbuuid, 0x00, 0);

		MERGE [DWHSchema].[DBCodes] AS target
		USING (SELECT [name],[uuid],[enable],[dbid] FROM @x) AS source ([name],[uuid],[enable],[dbid]) 
			ON (target.uuid = source.uuid)
				WHEN NOT MATCHED BY TARGET THEN INSERT VALUES (source.[name],source.[uuid],source.[enable]);


		SELECT @dbid = [dbid] FROM [DWHSchema].[DBCodes] WHERE [enable] = 0x01 AND [uuid]= @dbuuid
		IF NOT EXISTS (SELECT @dbid WHERE @dbid IS NOT NULL) 
		BEGIN
			RAISERROR(50073,1,1,@dbname);
			RETURN -1;
		END;

		DECLARE @typeObj varchar(100);
		SELECT @typeObj = T.c.query('fn:local-name(.)').value('.','varchar(100)') FROM @ref.nodes('//*') As T(c);

		IF EXISTS (SELECT 1 FROM [DWHSchema].[BlackObjectList] WHERE [dont_save_version] = 1 AND [val] = @typeObj) BEGIN
			RAISERROR(50074,1,2,@typeObj);
			RETURN 0;
		END;

		DECLARE @docdate datetime;
		SELECT @docdate = @curobj.query('/*/Date').value('.','datetime');

		DECLARE @uuid varchar(36);
		SELECT @uuid = @ref.value('(/*)[1]','VARCHAR(36)');

		BEGIN TRANSACTION;

		DECLARE @h UNIQUEIDENTIFIER;
	
		DECLARE @MessageBody XML;
		SET @MessageBody = (
		SELECT * FROM (
		SELECT
			 @username		as username
			,GETDATE()		as [curdate]
			,COMPRESS(CONVERT(nvarchar(max),@curobj))as [curobj]
			,COMPRESS(CONVERT(nvarchar(max),@ref))	as [ref]
			,@uuid			as [uuid]
			,@dbid 			as [dbid]
			,@hostname 		as hostname
			,@docdate 		as docdate
			,@typeObj 		as typeObj
			) as msg
			FOR XML AUTO, BINARY BASE64
		);

		--SELECT @MessageBody;

		BEGIN DIALOG CONVERSATION @h 
		FROM SERVICE [//Kolbasavs.ru/ObjectVersion/ObjectService] 
		TO SERVICE '//Kolbasavs.ru/ObjectVersion/ObjectService'
		ON CONTRACT [//Kolbasavs.ru/ObjectVersion/ObjectContract] 
		WITH ENCRYPTION = OFF;
	
		SEND ON CONVERSATION @h 
		MESSAGE TYPE [//Kolbasavs.ru/ObjectVersion/RequestMessage] 
			(@MessageBody);
		END CONVERSATION @h;

		COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH 
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		DECLARE @ErrorNumber INT = ERROR_NUMBER();
		DECLARE @ErrorLine INT = ERROR_LINE();
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorState INT = ERROR_STATE();
		DECLARE @CurentDate datetime = GETDATE();
		DECLARE @Data xml = null
		--RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

		EXECUTE [dbo].[ProcedureLog] 
		   @ErrorNumber
		  ,@ErrorLine
		  ,@ErrorMessage
		  ,@ErrorSeverity
		  ,@ErrorState
		  ,@CurentDate
		  ,@Data;

	END CATCH;

GO

GRANT EXECUTE ON [DWHSchema].[AddObjVersion]
    TO [ObjectVersionCommonRole]; 
GO