USE  [DBRegistroCauzioni]
GO

/****** Tabella METADATI del Fascicolo Digitale - leggera, ottimizzata per ricerche ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- TABELLA: RegistroCauzioniFascicoloDigitale
-- SCOPO: Contiene i METADATI essenziali di ogni documento nel fascicolo digitale.
--        Tabella progettata per essere LEGGERA e ottimizzata per le ricerche:
--        non contiene file binari né dati di firma digitale (separati in
--        RegistroCauzioniFascicoloDigitale_File per evitare scansioni full-table
--        con colonne varbinary(max) di grandi dimensioni).
--
-- SEPARAZIONE DALLA TABELLA _File:
--   Questa tabella: ricercabile, indici efficienti, lettura rapida per liste e dashboard.
--   Tabella _File:  caricata SOLO quando serve il contenuto o la firma del documento.
--
-- MODIFICA RISPETTO AL VECCHIO 08_RegistroCauzioniFascicoloDigitale.sql (rev. 11/11/2026):
--   - Rimossi: ContenutoFile, HashFile, DimensioneFile, EstensioneFile,
--     FlagFirmatoDigitalmente, TipoFirma, DataFirma, FirmatarioDocumento
--     → spostati in RegistroCauzioniFascicoloDigitale_File (script 10)
--   - Modificato: IDTipoDocumento ora è FK verso RegistroCauzioneTipoDocumento.ID
--     (non più verso DocTipoDocumento che era la lookup generica dell'AS IS)
--   - Mantenuti: tutti i metadati di classificazione, stato, PEC, ricezione, audit
-- =============================================

CREATE TABLE [dbo].[RegistroCauzioniFascicoloDigitale](
    [ID]                        [int]           IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
    [IDRegistroCauzioni]        [int]           NOT NULL,  -- FK verso RegistroCauzioni.ID

    -- ---- Classificazione del documento ----
    [IDTipoDocumento]           [int]           NOT NULL,  -- FK verso RegistroCauzioneTipoDocumento.ID
    [CodSezioneRiferimento]     [nvarchar](30)  NOT NULL CONSTRAINT [DF_RCFascicolo_CodSezioneRif] DEFAULT (N'GENERALE'),
    -- GENERALE, CONVALIDA, VARIAZIONI, PROROGHE, SVINCOLO, ESCUSSIONE
    [IDRecordSezione]           [int]           NULL,
    -- ID del record nella tabella di sezione (es: RegistroCauzioniConvalida.ID). NULL per GENERALE.

    -- ---- Dati di identificazione del documento ----
    [NomeFile]                  [nvarchar](500) NOT NULL,  -- nome file inclusa estensione, assegnato automaticamente
    [Descrizione]               [nvarchar](500) NULL,
    [NumVersione]               [smallint]      NOT NULL CONSTRAINT [DF_RCFascicolo_NumVersione] DEFAULT (1),
    [IDDocumentoPrecedente]     [int]           NULL,      -- auto-riferimento: versione che sostituisce (versionamento)

    -- ---- Stato del ciclo di vita ----
    [Status]                    [smallint]      NOT NULL CONSTRAINT [DF_RCFascicolo_Status] DEFAULT (0),
    -- Valori da RegistroCauzioniFascicoloDigitaleStatus. NO FK applicata (validazione applicativa).
    -- 0=BOZZA, 1=FIRMATO, 2=INVIATO_PEC, 3=RICEVUTO (finale), 4=ANNULLATO (finale)

    -- ---- Trasmissione PEC ----
    [ProtPECInvio]              [nvarchar](100) NULL,
    [DataPECInvio]              [datetime2](7)  NULL,
    [IndirizzoPECMittente]      [nvarchar](254) NULL,
    [IndirizzoPECDestinatario]  [nvarchar](254) NULL,

    -- ---- Ricezione / Archiviazione ----
    [ProtRicezione]             [nvarchar](100) NULL,
    [DataRicezione]             [datetime2](7)  NULL,
    [DataArchiviazione]         [datetime2](7)  NULL,

    -- ---- Annullamento ----
    [MotivoAnnullamento]        [nvarchar](500) NULL,
    [DataAnnullamento]          [datetime2](7)  NULL,
    [IDOperatoreAnnullamento]   [int]           NULL,

    -- ---- Audit ----
    [DataInserimento]           [datetime2](7)  NOT NULL CONSTRAINT [DF_RCFascicolo_DataInserimento] DEFAULT (SYSDATETIME()),
    [IDCreatore]                [int]           NOT NULL,
    [DataModifica]              [datetime2](7)  NOT NULL CONSTRAINT [DF_RCFascicolo_DataModifica] DEFAULT (SYSDATETIME()),
    [IDOperatore]               [int]           NOT NULL,

 CONSTRAINT [PK_RegistroCauzioniFascicoloDigitale] PRIMARY KEY CLUSTERED
(
    [ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80,
       OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- =============================================
-- CHECK Constraints
-- =============================================
ALTER TABLE [dbo].[RegistroCauzioniFascicoloDigitale] WITH NOCHECK ADD CONSTRAINT [CK_RCFascicolo_CodSezioneRiferimento]
    CHECK ([CodSezioneRiferimento] IN (N'GENERALE', N'CONVALIDA', N'VARIAZIONI', N'PROROGHE', N'SVINCOLO', N'ESCUSSIONE'))
GO
ALTER TABLE [dbo].[RegistroCauzioniFascicoloDigitale] CHECK CONSTRAINT [CK_RCFascicolo_CodSezioneRiferimento]
GO

-- =============================================
-- FK
-- =============================================
ALTER TABLE [dbo].[RegistroCauzioniFascicoloDigitale] WITH CHECK ADD CONSTRAINT [FK_RCFascicolo_RegistroCauzioni]
    FOREIGN KEY([IDRegistroCauzioni]) REFERENCES [dbo].[RegistroCauzioni] ([ID])
    ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[RegistroCauzioniFascicoloDigitale] CHECK CONSTRAINT [FK_RCFascicolo_RegistroCauzioni]
GO

-- FK verso RegistroCauzioneTipoDocumento (lookup specifica Cauzioni - sostituisce DocTipoDocumento)
ALTER TABLE [dbo].[RegistroCauzioniFascicoloDigitale] WITH CHECK ADD CONSTRAINT [FK_RCFascicolo_TipoDocumento]
    FOREIGN KEY([IDTipoDocumento]) REFERENCES [dbo].[RegistroCauzioneTipoDocumento] ([ID])
GO
ALTER TABLE [dbo].[RegistroCauzioniFascicoloDigitale] CHECK CONSTRAINT [FK_RCFascicolo_TipoDocumento]
GO

-- Auto-riferimento versionamento (nullable)
ALTER TABLE [dbo].[RegistroCauzioniFascicoloDigitale] WITH NOCHECK ADD CONSTRAINT [FK_RCFascicolo_VersionePrecedente]
    FOREIGN KEY([IDDocumentoPrecedente]) REFERENCES [dbo].[RegistroCauzioniFascicoloDigitale] ([ID])
GO
ALTER TABLE [dbo].[RegistroCauzioniFascicoloDigitale] CHECK CONSTRAINT [FK_RCFascicolo_VersionePrecedente]
GO

-- NOTA: NON ha FK verso RegistroCauzioniFascicoloDigitaleStatus su [Status].
-- Il ciclo di vita BOZZA→FIRMATO→INVIATO_PEC→RICEVUTO è validato a livello applicativo.

-- =============================================
-- Indici (ottimizzati per ricerche frequenti)
-- =============================================
CREATE NONCLUSTERED INDEX [IX_RCFascicolo_IDRegistroCauzioni_Status]
    ON [dbo].[RegistroCauzioniFascicoloDigitale] ([IDRegistroCauzioni] ASC, [Status] ASC)
    INCLUDE ([IDTipoDocumento],[CodSezioneRiferimento],[IDRecordSezione],[NomeFile],[DataInserimento])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, FILLFACTOR = 80,
          OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_RCFascicolo_CodSezioneRiferimento]
    ON [dbo].[RegistroCauzioniFascicoloDigitale] ([CodSezioneRiferimento] ASC, [IDRecordSezione] ASC)
    INCLUDE ([IDRegistroCauzioni],[Status],[IDTipoDocumento],[NomeFile])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, FILLFACTOR = 80,
          OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

-- =============================================
-- Extended Properties
-- =============================================
EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Metadati del Fascicolo Digitale per la Scheda Cauzione (nuova sezione TO BE 3.4.10). Tabella LEGGERA progettata per ricerche efficienti: non contiene file binari né dati di firma (separati in RegistroCauzioniFascicoloDigitale_File). IDTipoDocumento fa FK a RegistroCauzioneTipoDocumento (lookup specifica Cauzioni). Status=0=BOZZA (default). NON ha FK verso RegistroCauzioniFascicoloDigitaleStatus: validazione applicativa.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniFascicoloDigitale'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'FK verso RegistroCauzioneTipoDocumento.ID. Identifica il tipo di documento (es: lettera di conferma, check-list, polizza originale) e il template Word associato (sezione 3.5.1 TO BE).',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniFascicoloDigitale',
    @level2type=N'COLUMN', @level2name=N'IDTipoDocumento'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Stato del documento nel ciclo di vita. 0=BOZZA, 1=FIRMATO, 2=INVIATO_PEC, 3=RICEVUTO (finale), 4=ANNULLATO (finale). Valori in RegistroCauzioniFascicoloDigitaleStatus. NON ha FK: validazione applicativa.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniFascicoloDigitale',
    @level2type=N'COLUMN', @level2name=N'Status'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'ID del record nella tabella di sezione operativa a cui appartiene il documento (es: RegistroCauzioniConvalida.ID, RegistroCauzioniProroghe.ID). NULL per documenti di sezione GENERALE.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniFascicoloDigitale',
    @level2type=N'COLUMN', @level2name=N'IDRecordSezione'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'ID del documento precedente che questo sostituisce. Traccia la catena di versionamento (NumVersione > 1 implica IDDocumentoPrecedente valorizzato).',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniFascicoloDigitale',
    @level2type=N'COLUMN', @level2name=N'IDDocumentoPrecedente'
GO
