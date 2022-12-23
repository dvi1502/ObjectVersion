CREATE TABLE [DWHSchema].[DBCodes](
	[name] [nvarchar](1500) NOT NULL,
	[uuid] [nvarchar](36) NOT NULL,
	[enable] BIT NOT NULL DEFAULT 0, 
    [dbid] SMALLINT NOT NULL IDENTITY(1,1), 
    PRIMARY KEY CLUSTERED 
(
	[uuid] ASC
)
) ON [ObjectVersion_DataStorage]