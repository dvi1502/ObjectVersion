

CREATE TABLE [DWHSchema].[ErrorsLog](
	[ErrorNumber] [int] NULL,
	[ErrorLine] [int] NULL,
	[ErrorMessage] [nvarchar](4000) NULL,
	[ErrorSeverity] [int] NULL,
	[ErrorState] [int] NULL,
	[CurentDate] [datetime] NULL,
	[Data] [xml] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [DWHSchema].[ErrorsLog] ADD  DEFAULT (getdate()) FOR [CurentDate]
GO

