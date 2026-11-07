CREATE TABLE [dbo].[DocFascicolo_File_Cauzioni](
    [IDFascicolo] [bigint] NOT NULL,
    [IdUtente] [int] NULL,
    [DataInserimento] [datetime2](7) NOT NULL,
    [DataModifica] [datetime2](7) NOT NULL,
    [SourceFileName] [nvarchar](255) NULL,
    [ContentType] [varchar](64) NULL,
    [DataSize] [bigint] NULL,
    [Documento_BLOB] [varbinary](max) NULL,
    [IDFile] [bigint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
 CONSTRAINT [PK_DocFascicolo_File_Cauzioni] PRIMARY KEY CLUSTERED 
(
    [IDFascicolo] ASC,
    [IDFile] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[DocFascicolo_File_Cauzioni] ADD CONSTRAINT [DF_DocFascicolo_File_Cauzioni_DataInserimento] DEFAULT (sysdatetime()) FOR [DataInserimento]
GO

ALTER TABLE [dbo].[DocFascicolo_File] ADD CONSTRAINT [DF_DocFascicolo_File_Cauzioni_DataModifica] DEFAULT (sysdatetime()) FOR [DataModifica]
GO