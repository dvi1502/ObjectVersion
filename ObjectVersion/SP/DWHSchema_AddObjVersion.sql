
CREATE PROCEDURE [DWHSchema].[AddObjVersion]
     @dbuuid varchar(36)
    ,@dbname varchar(50)
	,@username nvarchar(50)
    ,@ref xml
    ,@curobj xml
	,@hostname nvarchar(50) = null
AS
   
    BEGIN TRY

		DECLARE @x TABLE ([name] nvarchar(1512),[uuid] nvarchar(36), [enable] binary(1));
		INSERT INTO @x VALUES (@dbname, @dbuuid, 0x00);

		MERGE [DWHSchema].[DBCodes] AS target
		USING (SELECT [name],[uuid],[enable] FROM @x) AS source ([name],[uuid],[enable]) 
		ON (target.uuid = source.uuid)
			WHEN NOT MATCHED BY TARGET THEN INSERT VALUES (source.[name],source.[uuid],source.[enable]);
		IF NOT EXISTS (SELECT 1 FROM [DWHSchema].[DBCodes] WHERE [enable] = 0x01 AND [uuid]= @dbuuid) 
		BEGIN
			RETURN;
		END;

		DECLARE @typeObj varchar(100);
		SELECT @typeObj = T.c.query('fn:local-name(.)').value('.','varchar(100)') FROM @ref.nodes('//*') As T(c);

		IF EXISTS (SELECT 1 FROM [DWHSchema].[BlackObjectList] WHERE [dont_save_version] = 1 AND [val] = @typeObj) BEGIN
			RETURN 0;
		END;

		DECLARE @docdate datetime;
		SELECT @docdate = @curobj.query('/*/Date').value('.','datetime');

		DECLARE @uuid varchar(36);
		SELECT @uuid = @ref.value('(/*)[1]','VARCHAR(36)');

		BEGIN TRANSACTION;
		INSERT INTO [DWHSchema].[Versions]
				([username]
				,[curdate]
				,[curobj]
			
				,[ref]
				,[refuuid]
				,[dbname]
				,[hostname]
				,[docdate]
				,[typeObj]
				)
			VALUES
				(@username
				,GETDATE()
				,@curobj

				,@ref
				,@uuid
				,@dbuuid
				,@hostname
				,@docdate
				,@typeObj
				)
		COMMIT TRANSACTION;
		
	END TRY
	BEGIN CATCH 
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		DECLARE @ErrorNumber INT = ERROR_NUMBER();
		DECLARE @ErrorLine INT = ERROR_LINE();
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorState INT = ERROR_STATE();
		--RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH;
GO

GRANT EXECUTE ON [DWHSchema].[AddObjVersion]
    TO [ObjVerUser]; 
GO