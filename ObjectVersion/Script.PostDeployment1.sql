/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

truncate table [DWHSchema].[BlackObjectList];
insert into [DWHSchema].[BlackObjectList] values (N'CatalogRef.ВС_ВетеринарноСопроводительныеДокументы',1,1);
insert into [DWHSchema].[BlackObjectList] values (N'DocumentRef.ВС_НаборныйЛист',1,1);
insert into [DWHSchema].[BlackObjectList] values (N'DocumentRef.МК_ЛистКачества',1,0);
insert into [DWHSchema].[BlackObjectList] values (N'DocumentRef.НачислениеЗарплатыРаботникамОрганизаций',1,0);
insert into [DWHSchema].[BlackObjectList] values (N'DocumentRef.ОтражениеЗарплатыВРеглУчете',1,0);
insert into [DWHSchema].[BlackObjectList] values (N'DocumentRef.ПремииРаботниковОрганизаций',1,0);
insert into [DWHSchema].[BlackObjectList] values (N'DocumentRef.РасчетСтраховыхВзносов',1,0);
insert into [DWHSchema].[BlackObjectList] values (N'DocumentRef.РегистрацияРазовыхНачисленийРаботниковОрганизаций',1,0);
insert into [DWHSchema].[BlackObjectList] values (N'DocumentRef.ФормированиеЗаписейКнигиПродаж',1,0);
GO



truncate table [DWHSchema].[DBCodes];

insert into [DWHSchema].[DBCodes] ([name],[uuid],[enable]) values (N'Srvr="192.168.5.80";Ref="meatvs_dia";','22D53C31B53EBEDD995F3E226573E31C',0);
insert into [DWHSchema].[DBCodes] ([name],[uuid],[enable]) values (N'Srvr="192.168.0.23";Ref="meat_vs_prod";','41F4DDF4C2B9DE373E5BD81B4E88CFEC',1);
insert into [DWHSchema].[DBCodes] ([name],[uuid],[enable]) values (N'Srvr="192.168.0.23";Ref="Meat_VS_prod";','55AB491ACE9C52CF4C1D172D64ACDE74',1);
insert into [DWHSchema].[DBCodes] ([name],[uuid],[enable]) values (N'Srvr="192.168.5.80";Ref="meatvs_zhav";','7A91CDFE02C819DC2A5C72D36DC4C0E3',0);
insert into [DWHSchema].[DBCodes] ([name],[uuid],[enable]) values (N'Srvr="192.168.5.80";Ref="meatvs_nika";','7F7906B2A64AFE050CC4B38D454F4852',0);
insert into [DWHSchema].[DBCodes] ([name],[uuid],[enable]) values (N'Srvr="192.168.5.80";Ref="meatvs_avo";','946615EF7E6E2052F194F65373A76E9D',0);
insert into [DWHSchema].[DBCodes] ([name],[uuid],[enable]) values (N'Srvr="192.168.5.80";Ref="Meat_Zhel_loss";','94ECC03ACF82B848E03DF989AEA80727',0);
insert into [DWHSchema].[DBCodes] ([name],[uuid],[enable]) values (N'Srvr="SQL1S";Ref="meat_vs_prod";','9724CD49534644F0AF1B2DE02C4F73D1',1);
insert into [DWHSchema].[DBCodes] ([name],[uuid],[enable]) values (N'Srvr="192.168.0.23";Ref="MEAT_VS_PROD";','AE748BAC13FFEEDBB95988BC7E006B9D',1);
insert into [DWHSchema].[DBCodes] ([name],[uuid],[enable]) values (N'Srvr="192.168.0.23";Ref="Meat_VS_Prod";','BA33F6480CD080765867B8EF4048BC31',1);
insert into [DWHSchema].[DBCodes] ([name],[uuid],[enable]) values (N'Srvr="192.168.5.80";Ref="meatvs_mmv";','E412DC4B286EC98B02E1736D57B4D765',0);
insert into [DWHSchema].[DBCodes] ([name],[uuid],[enable]) values (N'Srvr="192.168.0.23";Ref="Meat_vs_prod";','FC72ADCCB56E8E83A775A12A41A9601D',1);
GO



use [ObjectVersion]
go





truncate table [DWHSchema].[VersionsObjectStorage];
truncate table [DWHSchema].[Differents];
truncate table [DWHSchema].[VersionsCompress];
go

SET IDENTITY_INSERT [DWHSchema].[VersionsObjectStorage] ON;  




INSERT INTO [DWHSchema].[VersionsObjectStorage]
           ([id],[curobj_checksum]
           ,[curobj_hashbytes]
           ,[refuuid]
           ,[curobj])

SELECT  [id]
      ,[curobj_checksum]
      ,[curobj_hashbytes]
      ,[refuuid]
      ,[curobj]
  FROM [objver].[dbo].[versions_object_storage];

SET IDENTITY_INSERT [DWHSchema].[VersionsObjectStorage] OFF;  


SET IDENTITY_INSERT [DWHSchema].[Differents] ON;  

INSERT INTO [DWHSchema].[Differents]

           ([id]
		   ,[version_id]
           ,[key]
           ,[newVal]
           ,[oldVal]
           ,[version_perv])

SELECT  [id]
      ,[version_id]
      ,[key]
      ,[newVal]
      ,[oldVal]
      ,[version_perv]
  FROM [objver].[dbo].[different2]


SET IDENTITY_INSERT [DWHSchema].[Differents] OFF;  


INSERT INTO [DWHSchema].[VersionsCompress]
           ([id]
           ,[ref]
           ,[dbname]
           ,[username]
           ,[curdate]
           ,[curobj]
           ,[refuuid]
           ,[hostname]
           ,[docdate]
           ,[status]
           ,[typeObj]
           ,[curobj_checksum]
           ,[curobj_hashbytes])

SELECT  [id]
      ,[ref]
      ,[dbname]
      ,[username]
      ,[curdate]
      ,[curobj]
      ,[refuuid]
      ,[hostname]
      ,[docdate]
      ,[status]
      ,[typeObj]
      ,[curobj_checksum]
      ,[curobj_hashbytes]
  FROM [objver].[dbo].[versions_compress]

GO