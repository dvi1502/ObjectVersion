CREATE PROCEDURE [DWHSchema].[ProcessingQueueActivation]
AS
BEGIN
  SET NOCOUNT ON;
 
  DECLARE @conversation_handle UNIQUEIDENTIFIER;
  DECLARE @message_body XML;
  DECLARE @message_type_name sysname;
  DECLARE @checkDiff bit =  0;

  begin try

	begin transaction;

		 WAITFOR 
		 (
			  RECEIVE TOP (1)
				@conversation_handle = conversation_handle,
				@message_body = CAST(message_body AS XML),
				@message_type_name = message_type_name

			  FROM [DWHSchema].[CheckVersionObjectQueue]
		 ), TIMEOUT 1000;

         IF (0 != @@rowcount) 
         BEGIN

			IF @message_type_name = N'//Kolbasavs.ru/ObjectVersion/RequestMessage'
			BEGIN

				DECLARE
				@CurID			bigint,
				@PrevID			bigint,
				@RefUUID		varchar(36),
				@CurChecKSum	bigint,
				@PrevChecKSum	bigint,
				@CurObj			xml, 
				@PrevObj		xml;
	
				SELECT  @CurID = NEXT VALUE FOR [DWHSchema].[ObjectVersionSequence];

				DECLARE @tblEntityList TABLE (
					[id]		bigint NOT NULL,
					[ref]		[xml] NOT NULL,
					[dbid]		[smallint] NULL,
					[username]	[nvarchar](50) NULL,
					[curdate]	[datetime2](7) NULL,
					[curobj]	[xml] NULL,
					[refuuid]	[varchar](36) NULL,
					[hostname]	[nvarchar](50) NULL,
					[docdate]	[datetime] NULL,
					[status]	[smallint] NULL,
					[typeObj]	[nvarchar](100) NULL		
				);

				INSERT INTO @tblEntityList 
				(
					[id]
					,[username]
					,[curdate]
					,[curobj]
					,[ref]
					,[refuuid]
					,[dbid]
					,[hostname]
					,[docdate]
					,[typeObj]
				)
				SELECT 
					@CurID
					,T.c.value('@username', 'varchar(50)')		as  username
					,T.c.value('@curdate', '[datetime2](7)')	as [curdate]
					,CONVERT(xml,DECOMPRESS(T.c.value('@curobj','varbinary(max)'))) as curobj
					,CONVERT(xml,DECOMPRESS(T.c.value('@ref','varbinary(max)')))	as ref
					,T.c.value('@uuid', 'varchar(36)')		as refuuid
					,T.c.value('@dbid', 'smallint')	as [dbid]
					,T.c.value('@hostname', 'varchar(50)')	as hostname
					,T.c.value('@docdate', 'datetime')		as docdate
					,T.c.value('@typeObj', 'varchar(100)')	as typeObj		
				FROM @message_body.nodes('/*') AS T(c)

				SELECT TOP(1) 
					@CurObj = [curobj], 
					@RefUUID = [refuuid]  
				FROM @tblEntityList;

				IF (@checkDiff = 1) 
				BEGIN

					SELECT TOP(1)
					@PrevObj =  CONVERT(xml,DECOMPRESS(vos.[curobj])),
					@PrevID = vc.[id]
					FROM [DWHSchema].[VersionsCompress2] vc (NOLOCK)
					LEFT JOIN [DWHSchema].[VersionsObjectStorage] vos (NOLOCK)
					ON vc.[refuuid] = vos.[refuuid] AND vc.[curobj_checksum] = vos.[curobj_checksum]
					WHERE vc.[id] = (
						select max(id) 
						from [DWHSchema].[VersionsCompress2] (NOLOCK)
						where [refuuid] = @RefUUID  
					);

					SET @CurChecKSum =  CHECKSUM(CAST(COALESCE(@CurObj, '') as nvarchar(max)));
					SET @PrevChecKSum = CHECKSUM(CAST(COALESCE(@PrevObj,'') as nvarchar(max)));
		
					DECLARE @XmlName varchar(100),@XmlValue xml,@Value varchar(max),@XmlTable xml;

					DECLARE @MAPVALUES TABLE (
							 [source] varchar(100),
							 [key] varchar(100), 
							 [value] varchar(max)
							 );
	
					IF @CurChecKSum <> @PrevChecKSum BEGIN 

						DECLARE c0 CURSOR FOR 
							SELECT    
								T.c.query('fn:local-name(.)').value('.','varchar(max)') [XmlName],
								T.c.query('.') [XmlValue],
								T.c.query('.').value('.','nvarchar(max)') [Value],
								CASE 
									WHEN LEN(T.c.query('././Row').value('.','varchar(max)')) = 0 
									THEN NULL 
									ELSE T.c.query('././Row') 
								END [XmlTable]
							FROM @CurObj.nodes('/*/*') T(c);

						OPEN c0;
						FETCH NEXT FROM c0 INTO @XmlName,@XmlValue,@Value,@XmlTable;
						WHILE @@FETCH_STATUS = 0 BEGIN

							IF @XmlTable IS NULL BEGIN 
					
								INSERT INTO @MAPVALUES ([source],[key],[value])
								SELECT [source],[XmlName],[XmlValue] FROM (
								SELECT 
									'SRC' [source],
									@XmlName [XmlName],
									ROW_NUMBER() OVER (ORDER BY GETDATE()) [XmlKey], 
									@Value [XmlValue]
								) as D

							END
							ELSE BEGIN

								DECLARE cc0 CURSOR FOR 
									SELECT 
											[XmlName]+'['+CONVERT(varchar(100),[XmlKey])+']' as [XmlKey], [XmlValue] 
									FROM (
										SELECT @XmlName [XmlName], 	ROW_NUMBER() OVER (ORDER BY GETDATE()) [XmlKey], T.c.query('.') [XmlValue]
										FROM @XmlTable.nodes('/*:Row') T(c)
									) as D;

								OPEN cc0;
								FETCH NEXT FROM cc0 INTO @XmlName,@XmlValue;
								WHILE @@FETCH_STATUS = 0 BEGIN

									INSERT INTO @MAPVALUES ([source],[key],[value])
									SELECT 'SRC' [source], @XmlName+'.'+T.c.query('fn:local-name(.)').value('.','varchar(max)') [XmlKey], 
										T.c.query('.').value('.','nvarchar(max)') [Value]
									FROM @XmlValue.nodes('/*:Row/*') T(c);

									FETCH NEXT FROM cc0 INTO @XmlName,@XmlValue;
								END;
								CLOSE cc0;
								DEALLOCATE cc0;

								END;

								FETCH NEXT FROM c0 INTO @XmlName,@XmlValue,@Value,@XmlTable;

							END;
							CLOSE c0;
							DEALLOCATE c0;

						DECLARE c1 CURSOR FOR 
							SELECT    
							T.c.query('fn:local-name(.)').value('.','varchar(max)') [XmlName],
							T.c.query('.') [XmlValue],
							T.c.query('.').value('.','nvarchar(max)') [Value],
							CASE 
								WHEN LEN(T.c.query('././Row').value('.','varchar(max)')) = 0 
								THEN NULL 
								ELSE T.c.query('././Row') 
							END [XmlTable]
							FROM @PrevObj.nodes('/*/*') T(c);

						OPEN c1;
						FETCH NEXT FROM c1 INTO @XmlName,@XmlValue,@Value,@XmlTable;
						WHILE @@FETCH_STATUS = 0 BEGIN

							IF @XmlTable IS NULL BEGIN 
					
								INSERT INTO @MAPVALUES ([source],[key],[value])
								--SELECT [source],[XmlName]+'['+CONVERT(varchar(100),[XmlKey])+']',[XmlValue] FROM (
								SELECT [source],[XmlName],[XmlValue] FROM (
								SELECT 
									'DEST' [source],
									@XmlName [XmlName],
									ROW_NUMBER() OVER (ORDER BY GETDATE()) [XmlKey], 
									@Value [XmlValue]
								) as D

							END
							ELSE BEGIN

								DECLARE cc1 CURSOR FOR SELECT [XmlName]+'['+CONVERT(varchar(100),[XmlKey])+']' as [XmlKey], [XmlValue] FROM (
								SELECT @XmlName [XmlName], ROW_NUMBER() OVER (ORDER BY GETDATE()) [XmlKey], T.c.query('.') [XmlValue]
								FROM @XmlTable.nodes('/*:Row') T(c)) as D;
								OPEN cc1;
								FETCH NEXT FROM cc1 INTO @XmlName,@XmlValue;
								WHILE @@FETCH_STATUS = 0 BEGIN

									INSERT INTO @MAPVALUES ([source],[key],[value])
									SELECT 'DEST' [source], @XmlName+'.'+T.c.query('fn:local-name(.)').value('.','varchar(max)') [XmlKey], 
										T.c.query('.').value('.','nvarchar(max)') [Value]
									FROM @XmlValue.nodes('/*:Row/*') T(c);

									FETCH NEXT FROM cc1 INTO @XmlName,@XmlValue;
								END;
								CLOSE cc1;
								DEALLOCATE cc1;

							END;
							 FETCH NEXT FROM c1 INTO @XmlName,@XmlValue,@Value,@XmlTable;
						END;

						CLOSE c1;
						DEALLOCATE c1;

					END; -- IF (@CurChecKSum <> @PrevChecKSum)

                 END; -- IF (@checkDiff = 1)

				INSERT INTO [DWHSchema].[VersionsCompress2]
				([ref],[dbid],[username],[curdate],[refuuid],[hostname],[docdate],[status],[typeObj]
				,[curobj_checksum],[refid]
				--,[curobj_hashbytes]
				)
				SELECT [ref],[dbid],[username],[curdate],[refuuid],[hostname],[docdate],-1,[typeObj]
				,CHECKSUM(CAST([curobj] as nvarchar(max))),[DWHSchema].[fnGetBinary1C]([refuuid])
				--,HASHBYTES('SHA2_256',CAST([curobj] as nvarchar(max))) 
				FROM @tblEntityList;

				SELECT @CurID = @@IDENTITY;

				IF (@checkDiff = 1) 
				BEGIN
					DELETE FROM [DWHSchema].[Differents] WHERE [version_id] = @CurID;
					INSERT INTO [DWHSchema].[Differents] ([version_id],version_perv,[key],[newVal],[oldVal])
						SELECT @CurID,@PrevID,[key] as [Key], MAX(v0) as [newVal], MAX(v1) as [oldVal] FROM (
						SELECT [source],[key],null as v0,[value] as v1 
						FROM @MAPVALUES 
						WHERE [source] = 'DEST'
						UNION ALL
						SELECT [source],[key],[value],null 
						FROM @MAPVALUES 
						WHERE [source] = 'SRC') AS S
						GROUP BY [key] 
						HAVING COALESCE(MAX(v0),'')<>COALESCE(MAX(v1),'');
				END;  -- IF (@checkDiff = 1)


				MERGE INTO [DWHSchema].[VersionsObjectStorage] as dest
				USING (
					SELECT [curobj_checksum]
					--,[curobj_hashbytes]
					,[refuuid],MAX([curobj]) 
					FROM (
						SELECT 
							CHECKSUM(CAST([curobj] as nvarchar(max))) as [curobj_checksum],
							--HASHBYTES('SHA2_256',CAST([curobj] as nvarchar(max))) as [curobj_hashbytes],
							[refuuid],
							COMPRESS(CONVERT(nvarchar(max),[curobj])) as [curobj]  
						FROM @tblEntityList 

					) AS xx0 
					GROUP BY [curobj_checksum]
					--,[curobj_hashbytes]
					,[refuuid]

					) AS src ([curobj_checksum]
					--,[curobj_hashbytes]
					,[refuuid],[curobj])
					ON dest.[curobj_checksum] = src.[curobj_checksum] and dest.[refuuid]=src.[refuuid]
					WHEN NOT MATCHED BY TARGET THEN 
						INSERT ([curobj_checksum]
						--,[curobj_hashbytes]
						,[refuuid],[curobj])
						VALUES ( src.[curobj_checksum]
						--,src.[curobj_hashbytes]
						,src.[refuuid],src.[curobj])
				;


				END CONVERSATION @conversation_handle;

            END

			-- If end dialog message, end the dialog
			ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
			BEGIN
			   END CONVERSATION @conversation_handle;
			END;
 
			-- If error message, log and end conversation
			ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
			BEGIN
			   END CONVERSATION @conversation_handle;
			END;

		END;

        commit;

   end try
   begin catch

			if (XACT_STATE()) = -1 begin
				rollback transaction;
            end;
	
			if (XACT_STATE()) = 1 begin
				DECLARE @ErrorNumber INT = ERROR_NUMBER();
				DECLARE @ErrorLine INT = ERROR_LINE();
				DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
				DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
				DECLARE @ErrorState INT = ERROR_STATE();

				INSERT INTO [DWHSchema].[ErrorsLog]
						   ([ErrorNumber]
						   ,[ErrorLine]
						   ,[ErrorMessage]
						   ,[ErrorSeverity]
						   ,[ErrorState]
						   ,[Data]
						   )
					 VALUES
						   (@ErrorNumber
						   ,@ErrorLine
						   ,@ErrorMessage
						   ,@ErrorSeverity
						   ,@ErrorState
						   ,@message_body
						   )

                end conversation @conversation_handle with error = @ErrorNumber description = @ErrorMessage;
                commit;
            end

   end catch;
end
GO