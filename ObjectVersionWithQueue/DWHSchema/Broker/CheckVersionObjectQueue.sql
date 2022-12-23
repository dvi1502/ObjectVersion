
CREATE QUEUE [DWHSchema].[CheckVersionObjectQueue]
	
	WITH ACTIVATION
	( 
		STATUS = ON,
		PROCEDURE_NAME = [DWHSchema].[ProcessingQueueActivation],
		MAX_QUEUE_READERS = 9,
		EXECUTE AS OWNER
	)