
CREATE PROCEDURE [dbo].[ProcedureLog] 
	@ErrorNumber int,
    @ErrorLine int,
    @ErrorMessage nvarchar(max),
    @ErrorSeverity int = null,
    @ErrorState int  = null,
    @CurentDate datetime  = null,
    @Data xml  = null

AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO [DWHSchema].[ErrorsLog]
    (
		[ErrorNumber]
		,[ErrorLine]
		,[ErrorMessage]
		,[ErrorSeverity]
		,[ErrorState]
		,[CurentDate]
		,[Data]
	)
     VALUES
    (
		@ErrorNumber
		,@ErrorLine
		,@ErrorMessage
		,@ErrorSeverity
		,@ErrorState
		,@CurentDate
		,@Data
	)

END
GO

GRANT EXECUTE ON [dbo].[ProcedureLog] TO [ObjectVersionCommonRole]; 
GO