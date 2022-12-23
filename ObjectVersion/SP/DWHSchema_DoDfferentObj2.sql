CREATE PROCEDURE [DWHSchema].[DoDfferentObj2]
	@RefUUID varchar(36),
	@Status0 int = 0,
	@Status1 int = -1
AS
BEGIN

	--SET ANSI_WARNINGS OFF; 
	SET NOCOUNT ON;

	DECLARE
		@CurObj xml, 
		@PrevObj xml,
		@CurID bigint,
		@PrevID bigint,
		@CurChecKSum bigint,
		@PrevChecKSum bigint,
		@iteration int = 0;

	DECLARE @XmlName varchar(100),@XmlValue xml,@Value varchar(max),@XmlTable xml;

	IF OBJECT_ID('tempdb..#MAPVERSIONS') IS NULL BEGIN
		CREATE TABLE #MAPVERSIONS (ra bigint, id bigint, [curobj] xml, [objdiff] xml, [status] smallint,[refuuid] varchar(36),[typeObj] nvarchar(100));
	END

	TRUNCATE TABLE #MAPVERSIONS;

	INSERT INTO #MAPVERSIONS ([ra], [id],[curobj],[status],[refuuid],[typeObj] )  
	SELECT [ra],[id],[curobj],[status],[refuuid],[typeObj] FROM (

		SELECT 0 ra,vc.[id], 
			(SELECT TOP(1) CONVERT(xml,DECOMPRESS(vos.[curobj])) 
				FROM [DWHSchema].[VersionsObjectStorage] vos 
				WHERE  vc.[refuuid] = vos.[refuuid] AND vc.[curobj_checksum] = vos.[curobj_checksum]) as [curobj],
			vc.[status],vc.[refuuid],vc.[typeObj] 
			FROM [DWHSchema].[VersionsCompress] vc
			WHERE vc.[id] = (select max(id) from [DWHSchema].[VersionsCompress] WHERE [refuuid] = @RefUUID AND [status] = -1 )
		UNION ALL
		SELECT ROW_NUMBER() OVER (ORDER BY ID) [ra],[id],[curobj],[status],[refuuid],[typeObj]
			FROM [DWHSchema].[Versions] 
			WHERE ([refuuid] = @RefUUID) AND ([status] = @Status0 )

	) as P
		WHERE  1=1
			AND (DATALENGTH(p.curobj) < 3000000) -- мега большие документы не обрабатываем 
			AND (LEFT(p.typeObj,36) not in (select LEFT(val,36) from [DWHSchema].[BlackObjectList] where [dont_calc_diff] = 1))
	;


	IF EXISTS ( 
		SELECT s0.curobj as CurObj,	s1.curobj as PrevObj, s0.id as CurID, s1.id as PrevID
		FROM (
			SELECT p.[ra],p.[id],p.[curobj],p.[objdiff],p.[status] FROM #MAPVERSIONS p) as s0
			LEFT JOIN (
			SELECT p.[ra]+1 ra,p.[id],p.[curobj],p.[objdiff],p.[status] FROM #MAPVERSIONS p) as s1
		ON s0.ra = s1.ra
		WHERE  s1.curobj is not null
		) 

	BEGIN

		DECLARE cur CURSOR FOR
		SELECT s0.curobj as CurObj,	s1.curobj as PrevObj, s0.id as CurID, s1.id as PrevID,s0.chs CurChecKSum,s1.chs PrevChecKSum
		FROM (
			SELECT p.[ra],     p.[id],p.[curobj],CHECKSUM(CAST(COALESCE(p.[curobj],'') as nvarchar(max))) as chs,p.[objdiff],p.[status]  FROM #MAPVERSIONS p) as s0
			LEFT JOIN (
			SELECT p.[ra]+1 ra,p.[id],p.[curobj],CHECKSUM(CAST(COALESCE(p.[curobj],'') as nvarchar(max))) as chs,p.[objdiff],p.[status]  FROM #MAPVERSIONS p) as s1
		ON s0.ra = s1.ra
		WHERE  s1.curobj is not null ;

		IF OBJECT_ID('tempdb..#MAPVALUES') IS NULL BEGIN
			CREATE TABLE #MAPVALUES ([source] varchar(100),[key] varchar(100), [value] varchar(max));
		END
		IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_#MAPVALUES_Key') DROP INDEX IX_#MAPVALUES_Key ON #MAPVALUES;   
		CREATE NONCLUSTERED INDEX IX_#MAPVALUES_Key ON #MAPVALUES ([key]);   
		
		OPEN cur;
		FETCH NEXT FROM cur INTO @CurObj,@PrevObj,@CurID,@PrevID, @CurChecKSum,@PrevChecKSum;

		WHILE @@FETCH_STATUS = 0 BEGIN

			TRUNCATE TABLE #MAPVALUES;
			
			IF @CurChecKSum <> @PrevChecKSum BEGIN 

				DECLARE c0 CURSOR FOR select    
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
					
						INSERT INTO #MAPVALUES ([source],[key],[value])
						--SELECT [source],[XmlName]+'['+CONVERT(varchar(100),[XmlKey])+']',[XmlValue] FROM (
						SELECT [source],[XmlName],[XmlValue] FROM (
						SELECT 
							'SRC' [source],
							@XmlName [XmlName],
							ROW_NUMBER() OVER (ORDER BY GETDATE()) [XmlKey], 
							@Value [XmlValue]
						) as D
					END
					ELSE BEGIN
						--INSERT INTO #MAPVALUES ([source],[key],[value])

						DECLARE cc0 CURSOR FOR 
						SELECT 
							[XmlName]+'['+CONVERT(varchar(100),[XmlKey])+']' as [XmlKey], [XmlValue] FROM (

						SELECT @XmlName [XmlName], 	ROW_NUMBER() OVER (ORDER BY GETDATE()) [XmlKey], T.c.query('.') [XmlValue]
						FROM @XmlTable.nodes('/*:Row') T(c)) as D;
						OPEN cc0;
						FETCH NEXT FROM cc0 INTO @XmlName, @XmlValue;
						WHILE @@FETCH_STATUS = 0 BEGIN

							INSERT INTO #MAPVALUES ([source],[key],[value])
							SELECT 'SRC' [source], @XmlName+'.'+T.c.query('fn:local-name(.)').value('.','varchar(max)') [XmlKey], 
								T.c.query('.').value('.','nvarchar(max)') [Value]
							FROM @XmlValue.nodes('/*:Row/*') T(c);

							FETCH NEXT FROM cc0 INTO @XmlName, @XmlValue;
						END;
						CLOSE cc0;
						DEALLOCATE cc0;

					END;
					FETCH NEXT FROM c0 INTO @XmlName,@XmlValue,@Value,@XmlTable;
				END;

				CLOSE c0;
				DEALLOCATE c0;

				DECLARE c1 CURSOR FOR select    
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
					
						INSERT INTO #MAPVALUES ([source],[key],[value])
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

							INSERT INTO #MAPVALUES ([source],[key],[value])
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

			END -- IF CurChecKSum <> PrevChecKSum BEGIN  

			DELETE FROM [DWHSchema].[Differents] WHERE [version_id] = @CurID;
			INSERT INTO [DWHSchema].[Differents] ([version_id],version_perv,[key],[newVal],[oldVal])
				SELECT @CurID,@PrevID,[key] as [Key], MAX(v0) as [newVal], MAX(v1) as [oldVal] FROM (
				SELECT [source],[key],null as v0,[value] as v1 FROM #MAPVALUES WHERE [source] = 'DEST'
				UNION ALL
				SELECT [source],[key],[value],null FROM #MAPVALUES WHERE [source] = 'SRC') AS S
				GROUP BY [key] 
				HAVING MAX(v0)<>MAX(v1);

			FETCH NEXT FROM cur INTO @CurObj,@PrevObj,@CurID,@PrevID,@CurChecKSum,@PrevChecKSum;

		END;
		CLOSE cur;
		DEALLOCATE cur;

	END;

	RETURN @iteration;
END
GO


