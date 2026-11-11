USE  [DBRegistroCauzioni]
GO

/****** Tabella FILE BINARI del Fascicolo Digitale - firma digitale e contenuto ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- TABELLA: RegistroCauzioniFascicoloDigitale_File
-- SCOPO: Contiene il file binario effettivo e tutti i dati strettamente
--        relativi al file fisico: firma digitale, hash, dimensione, MIME type.
--        Tabella PESANTE per design: il campo ContenutoFile è varbinary(max) e
--        contiene l'intero documento firmato (PDF, P7M, XML).
--
-- SEPARAZIONE DALLA TABELLA PADRE:
--   La separazione da RegistroCauzioniFascicoloDigitale è deliberata:
--   a) Le query di lista/ricerca operano solo sulla tabella padre (leggera).
--   b) Il join con questa tabella avviene SOLO quando serve il contenuto
--      effettivo del file (download, verifica firma, visualizzazione PDF).
--   c) SQL Server gestisce varbinary(max) in pagine separate (LOB pages):
--      averle in una tabella dedicata evita la degradazione delle performance
--      sulle scansioni della tabella padre.
--   d) La tabella può essere collocata su un filegroup separato (es: FILESTREAM)
--      per la gestione ottimizzata dei LOB.
--
-- RELAZIONE: IDFascicoloDigitale (FK) → RegistroCauzioniFascicoloDigitale.ID
--   Rapporto 1:1 con la tabella padre (ogni documento ha un solo file attivo).
--   In caso di ri-firma o sostituzione, il record viene aggiornato (non inserito nuovo):
--   il versionamento è gestito tramite IDDocumentoPrecedente nella tabella padre.
--
-- TIPO DATO FILE: varbinary(max)
--   Sostituisce il tipo [image] usato in DocFascicolo_File (AS IS), deprecato
--   da SQL Server 2005 e rimosso nelle versioni future.
--   Per volumi molto elevati valutare FILESTREAM (configurazione a livello server).
-- =============================================

CREATE TABLE [dbo].[RegistroCauzioniFascicoloDigitale_File](
    [ID]                        [int]           IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
    [IDFascicoloDigitale]       [int]           NOT NULL,  -- FK verso RegistroCauzioniFascicoloDigitale.ID (1:1)

    -- ---- File binario ----
    [ContenutoFile]             [varbinary](max) NOT NULL,  -- file firmato: PDF, P7M (CAdES), XML (XAdES)
    [NomeFileOriginale]         [nvarchar](500) NOT NULL,  -- nome originale del file inclusa estensione
    [EstensioneFile]            [nvarchar](10)  NOT NULL,  -- es: pdf, p7m, xml
    [MimeType]                  [nvarchar](100) NULL,      -- es: application/pdf, application/pkcs7-mime
    [DimensioneFile]            [bigint]        NOT NULL CONSTRAINT [DF_RCFile_DimensioneFile] DEFAULT (0),
    -- dimensione in byte del ContenutoFile

    -- ---- Integrità del file ----
    [HashFile]                  [nvarchar](64)  NULL,
    -- SHA-256 hex (64 caratteri) calcolato al momento del salvataggio.
    -- Consente di verificare l'integrità del documento senza rileggere il BLOB.

    -- ---- Firma digitale ----
    [FlagFirmatoDigitalmente]   [bit]           NOT NULL CONSTRAINT [DF_RCFile_FlagFirmato] DEFAULT (0),
    [TipoFirma]                 [nvarchar](20)  NULL,
    -- Formato della firma: PAdES (firma in PDF), CAdES (file .p7m), XAdES (XML).
    -- PAdES è il formato raccomandato per le lettere generate dall'applicazione.
    -- CAdES (.p7m) è frequente per documenti ricevuti da fideiussori e enti esterni.
    [DataFirma]                 [datetime2](7)  NULL,
    [FirmatarioDocumento]       [nvarchar](200) NULL,  -- nome leggibile del firmatario
    [SerialeCertificatoFirma]   [nvarchar](100) NULL,  -- numero seriale del certificato di firma
    [EnteEmittenteCertificato]  [nvarchar](300) NULL,  -- CA emittente del certificato di firma
    [ScadenzaCertificatoFirma]  [datetime2](7)  NULL,  -- scadenza del certificato usato per la firma
    [FlagFirmaValida]           [bit]           NULL,
    -- NULL = non ancora verificata, 1 = firma valida al momento della verifica, 0 = firma non valida

    -- ---- Verifica firma ----
    [DataVerificaFirma]         [datetime2](7)  NULL,
    [EsitoVerificaFirma]        [nvarchar](500) NULL,  -- descrizione testuale dell'esito della verifica
    [IDOperatoreVerifica]       [int]           NULL,

    -- ---- Audit ----
    [DataInserimento]           [datetime2](7)  NOT NULL CONSTRAINT [DF_RCFile_DataInserimento] DEFAULT (SYSDATETIME()),
    [IDCreatore]                [int]           NOT NULL,
    [DataModifica]              [datetime2](7)  NOT NULL CONSTRAINT [DF_RCFile_DataModifica] DEFAULT (SYSDATETIME()),
    [IDOperatore]               [int]           NOT NULL,

 CONSTRAINT [PK_RegistroCauzioniFascicoloDigitale_File] PRIMARY KEY CLUSTERED
(
    [ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80,
       OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 -- Garantisce la relazione 1:1 con la tabella padre
 CONSTRAINT [UQ_RCFile_IDFascicoloDigitale] UNIQUE NONCLUSTERED
(
    [IDFascicoloDigitale] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

-- =============================================
-- CHECK Constraints
-- =============================================
ALTER TABLE [dbo].[RegistroCauzioniFascicoloDigitale_File] WITH NOCHECK ADD CONSTRAINT [CK_RCFile_TipoFirma]
    CHECK ([TipoFirma] IS NULL OR [TipoFirma] IN (N'PAdES', N'CAdES', N'XAdES'))
GO
ALTER TABLE [dbo].[RegistroCauzioniFascicoloDigitale_File] CHECK CONSTRAINT [CK_RCFile_TipoFirma]
GO

ALTER TABLE [dbo].[RegistroCauzioniFascicoloDigitale_File] WITH NOCHECK ADD CONSTRAINT [CK_RCFile_DimensionePositiva]
    CHECK ([DimensioneFile] >= 0)
GO
ALTER TABLE [dbo].[RegistroCauzioniFascicoloDigitale_File] CHECK CONSTRAINT [CK_RCFile_DimensionePositiva]
GO

-- =============================================
-- FK verso la tabella padre (1:1)
-- =============================================
ALTER TABLE [dbo].[RegistroCauzioniFascicoloDigitale_File] WITH CHECK ADD CONSTRAINT [FK_RCFile_FascicoloDigitale]
    FOREIGN KEY([IDFascicoloDigitale]) REFERENCES [dbo].[RegistroCauzioniFascicoloDigitale] ([ID])
    ON DELETE CASCADE
    -- CASCADE: eliminando il record metadati si elimina anche il file. La cancellazione
    -- è comunque impedita a livello applicativo per documenti in stato RICEVUTO (finale).
GO
ALTER TABLE [dbo].[RegistroCauzioniFascicoloDigitale_File] CHECK CONSTRAINT [FK_RCFile_FascicoloDigitale]
GO

-- =============================================
-- Indice su HashFile (ricerca duplicati, verifica integrità)
-- =============================================
CREATE NONCLUSTERED INDEX [IX_RCFile_HashFile]
    ON [dbo].[RegistroCauzioniFascicoloDigitale_File] ([HashFile] ASC)
    WHERE [HashFile] IS NOT NULL
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, FILLFACTOR = 90,
          OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

-- =============================================
-- Extended Properties
-- =============================================
EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'File binario e dati di firma digitale del documento nel Fascicolo Digitale. Tabella separata da RegistroCauzioniFascicoloDigitale per design: il BLOB varbinary(max) è caricato SOLO quando serve il contenuto effettivo (download, firma, visualizzazione). Rapporto 1:1 con la tabella padre. Sostituisce DocFascicolo_File AS IS che usava il tipo [image] deprecato.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniFascicoloDigitale_File'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'File binario del documento (PDF, P7M, XML). Tipo varbinary(max) in sostituzione del tipo [image] deprecato usato in DocFascicolo_File. Per volumi elevati valutare FILESTREAM.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniFascicoloDigitale_File',
    @level2type=N'COLUMN', @level2name=N'ContenutoFile'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Formato della firma digitale: PAdES=firma incorporata nel PDF; CAdES=busta .p7m; XAdES=firma XML. PAdES è il formato raccomandato per le lettere generate dall''applicazione.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniFascicoloDigitale_File',
    @level2type=N'COLUMN', @level2name=N'TipoFirma'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Hash SHA-256 (hex, 64 caratteri) calcolato al momento del salvataggio. Permette la verifica di integrità senza rileggere il BLOB.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniFascicoloDigitale_File',
    @level2type=N'COLUMN', @level2name=N'HashFile'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'NULL=firma non ancora verificata; 1=firma valida al momento della verifica; 0=firma non valida o certificato scaduto.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniFascicoloDigitale_File',
    @level2type=N'COLUMN', @level2name=N'FlagFirmaValida'
GO
