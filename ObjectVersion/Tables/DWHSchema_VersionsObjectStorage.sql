CREATE TABLE [DWHSchema].[VersionsObjectStorage](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[curobj_checksum] [bigint] NULL,
	[curobj_hashbytes] [varbinary](50) NULL,
	[refuuid] [varchar](36) NULL,
	[curobj] [varbinary](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)
) ON [ObjectVersion_DataStorage] TEXTIMAGE_ON [ObjectVersion_XmlStorage]