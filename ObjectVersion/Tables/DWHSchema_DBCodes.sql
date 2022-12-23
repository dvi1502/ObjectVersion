CREATE TABLE [DWHSchema].[DBCodes](
	[name] [nvarchar](1500) NOT NULL,
	[uuid] [nvarchar](36) NOT NULL,
	[enable] BIT NOT NULL DEFAULT 0, 
    PRIMARY KEY CLUSTERED 
(
	[uuid] ASC
)
) ON [ObjectVersion_DataStorage]