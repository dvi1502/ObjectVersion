CREATE TABLE [DWHSchema].[Differents](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[version_id] [bigint] NULL,
	[key] [nvarchar](100) NULL,
	[newVal] [nvarchar](max) NULL,
	[oldVal] [nvarchar](max) NULL,
	[version_perv] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)
) ON [ObjectVersion_DataStorage] TEXTIMAGE_ON [ObjectVersion_XmlStorage]