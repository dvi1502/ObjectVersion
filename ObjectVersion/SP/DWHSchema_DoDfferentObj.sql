CREATE PROCEDURE [DWHSchema].[DoDfferentObj]
		@CurObj xml, 
		@PrevObj xml,
		@CurID bigint,
		@PrevID bigint
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE
			@iteration int = 0,
			@CurChecKSum bigint,
			@PrevChecKSum bigint;

	SET @CurChecKSum =  CHECKSUM(CAST(COALESCE(@CurObj, '') as nvarchar(max)));
	SET @PrevChecKSum = CHECKSUM(CAST(COALESCE(@PrevObj,'') as nvarchar(max)));


	DECLARE @XmlName varchar(100),@XmlValue xml,@Value varchar(max),@XmlTable xml;

	IF OBJECT_ID('tempdb..#MAPVALUES') IS NULL BEGIN
			CREATE TABLE #MAPVALUES ([source] varchar(100),[key] varchar(100), [value] varchar(max));
	END;

	IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_#MAPVALUES_Key') 
		DROP INDEX IX_#MAPVALUES_Key ON #MAPVALUES;   

	CREATE NONCLUSTERED INDEX IX_#MAPVALUES_Key ON #MAPVALUES ([key]);   


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
					
				INSERT INTO #MAPVALUES ([source],[key],[value])
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

					INSERT INTO #MAPVALUES ([source],[key],[value])
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

	END;

	DELETE FROM [DWHSchema].[Differents] WHERE [version_id] = @CurID;
	INSERT INTO [DWHSchema].[Differents] ([version_id],version_perv,[key],[newVal],[oldVal])
		SELECT @CurID,@PrevID,[key] as 'Key', MAX(v0) as 'newVal', MAX(v1) as 'valOld' FROM (
		SELECT [source],[key],null as v0,[value] as v1 FROM #MAPVALUES WHERE [source] = 'DEST'
		UNION ALL
		SELECT [source],[key],[value],null FROM #MAPVALUES WHERE [source] = 'SRC') AS S
		GROUP BY [key] 
		HAVING ISNULL(MAX(v0),'')<>ISNULL(MAX(v1),'');


	RETURN @iteration;

END
GO

GRANT EXECUTE ON  [DWHSchema].[DoDfferentObj]
    TO [ObjVerUser]; 
GO