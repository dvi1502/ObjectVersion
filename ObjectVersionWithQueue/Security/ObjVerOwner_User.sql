CREATE USER [ObjVerOwner]
	WITHOUT LOGIN
	WITH DEFAULT_SCHEMA = [DWHSchema]

GO

ALTER ROLE [db_owner] ADD MEMBER [ObjVerOwner]
GO


