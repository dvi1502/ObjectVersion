CREATE SERVICE [//Kolbasavs.ru/ObjectVersion/ObjectService]
	ON QUEUE [DWHSchema].[CheckVersionObjectQueue]
	(
		[//Kolbasavs.ru/ObjectVersion/ObjectContract]
	)
