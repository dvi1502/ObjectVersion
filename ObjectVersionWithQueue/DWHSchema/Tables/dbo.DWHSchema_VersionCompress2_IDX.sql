CREATE INDEX [VersionCompress2_refuuid]
	ON [DWHSchema].[VersionsCompress2]
	(refuuid,id)
GO


CREATE INDEX [VersionCompress2_refuuid_checksum]
	ON [DWHSchema].[VersionsCompress2]
	(refuuid,curobj_checksum,id)
GO

CREATE INDEX [VersionCompress2_refid01]
	ON [DWHSchema].[VersionsCompress2]
	(refid,id)
GO

CREATE INDEX [VersionCompress2_refid02_typeObj]
	ON [DWHSchema].[VersionsCompress2]
	(typeObj,refid,id)
GO
