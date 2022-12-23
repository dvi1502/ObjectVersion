CREATE TABLE [DWHSchema].[BlackObjectList](
	[val] [nvarchar](100) NOT NULL,
	[dont_calc_diff] [smallint] NULL,
	[dont_save_version] [smallint] NULL,
PRIMARY KEY CLUSTERED 
(
	[val] ASC
)
) ON [ObjectVersion_IntermediateDataStorage]
GO

ALTER TABLE [DWHSchema].[BlackObjectList] ADD  DEFAULT ((1)) FOR [dont_calc_diff]
GO

ALTER TABLE [DWHSchema].[BlackObjectList] ADD  DEFAULT ((0)) FOR [dont_save_version]
GO