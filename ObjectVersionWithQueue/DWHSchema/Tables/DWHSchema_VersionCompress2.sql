CREATE TABLE [DWHSchema].[VersionsCompress2](
	[id] [bigint] IDENTITY(-9223372036854768400,1) NOT NULL,
	[ref] [xml] NOT NULL,
	[dbid] [smallint] NULL,
	[username] [nvarchar](50) NULL,
	[curdate] [datetime2](7) NULL,
	[refuuid] [varchar](36) NULL,
	[refid] [varbinary](16) NULL,
	[hostname] [nvarchar](50) NULL,
	[docdate] [datetime] NULL,
	[status] [smallint] NULL,
	[typeObj] [nvarchar](100) NULL,
	[curobj_checksum] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [ObjectVersion_DataStorage]
) ON [ObjectVersion_DataStorage] TEXTIMAGE_ON [ObjectVersion_XmlStorage]
GO