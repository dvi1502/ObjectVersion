CREATE TABLE [DWHSchema].[VersionsCompress](
	[id] [bigint] NOT NULL,
	[ref] [xml] NOT NULL,
	[dbid] SMALLINT NULL, 
	[username] [nvarchar](50) NULL,
	[curdate] [datetime2](7) NULL,
	[refuuid] [varchar](36) NULL,
	[hostname] [nvarchar](50) NULL,
	[docdate] [datetime] NULL,
	[status] [smallint] NULL,
	[typeObj] [nvarchar](100) NULL,
	[curobj_checksum] [bigint] NULL,
	[curobj_hashbytes] [varbinary](50) NULL,
    PRIMARY KEY CLUSTERED 
(
	[id] ASC
)
) ON [ObjectVersion_DataStorage] TEXTIMAGE_ON [ObjectVersion_XmlStorage]