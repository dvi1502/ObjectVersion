CREATE TABLE [DWHSchema].[VersionsObjectStorage](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[curobj_checksum] [bigint] NULL,
	[refuuid] [varchar](36) NULL,
	[curobj] [varbinary](max) NULL,
	[CreateDate] datetime2 not null default SYSDATETIME()
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)
) ON [ObjectVersion_DataStorage] TEXTIMAGE_ON [ObjectVersion_XmlStorage]