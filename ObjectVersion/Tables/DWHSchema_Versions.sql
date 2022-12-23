CREATE TABLE [DWHSchema].[Versions](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[ref] [xml] NOT NULL,
	[dbname] [varchar](50) NULL,
	[username] [nvarchar](50) NULL,
	[curdate] [datetime2](7) NULL,
	[curobj] [xml] NULL,
	[refuuid] [varchar](36) NULL,
	[hostname] [nvarchar](50) NULL,
	[docdate] [datetime] NULL,
	[status] [smallint] NULL,
	[typeObj] [nvarchar](100) NULL,
 CONSTRAINT [PK_versions] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)
) ON [ObjectVersion_IntermediateDataStorage] TEXTIMAGE_ON [ObjectVersion_IntermediateDataStorage]