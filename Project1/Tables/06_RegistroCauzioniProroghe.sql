USE  [DBRegistroCauzioni]
GO
/****** Tabella multi-ciclo della sezione Proroghe - nuova sezione TO BE ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- TABELLA: RegistroCauzioniProroghe
-- SCOPO: Registra ogni ciclo di proroga/rinnovo di una cauzione. Multi-ciclo perché
--        nel corso del ciclo di vita di una cauzione possono intervenire più rinnovi
--        (es: proroga del progetto che estende la scadenza della polizza, e successivi
--        ulteriori rinnovi se il progetto viene prorogato più volte).
--
-- ORIGINE CAMPI: Parzialmente estratti da [dbo].[GstCauzioni]:
--   ProtComunicazioneProroga, DataComunicazioneProroga → ProtRichiestaFideiussore, DataRichiestaFideiussore
--   ScadenzaUltimoRinnovo → ScadenzaNuova (nome più chiaro e generico)
--   DataProrogaProgetto → DataProrogaProgetto (mantenuto)
--   I campi in GstCauzioni erano singoli (mono-ciclo), qui diventano multi-ciclo.
--
-- CAMPI NUOVI (non in GstCauzioni):
--   IDRegistroCauzioni, Status, NumCiclo, TipoProroga, DataScadenzaAttesa,
--   ScadenzaPrecedente, ProtDecretoConcessione, DataDecretoConcessione,
--   ProtComunicazioneEnte, DataComunicazioneEnte, FlagRinnovoAutomatico,
--   MotivoRifiuto, DataRicezioneRinnovo, ProtRicezioneRinnovo.
-- =============================================

CREATE TABLE [dbo].[RegistroCauzioniProroghe](
    [ID]                            [int]           IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
    [IDRegistroCauzioni]            [int]           NOT NULL,  -- FK verso RegistroCauzioni.ID
    [NumCiclo]                      [smallint]      NOT NULL CONSTRAINT [DF_RCProroghe_NumCiclo] DEFAULT (1),
    [Status]                        [smallint]      NOT NULL CONSTRAINT [DF_RCProroghe_Status] DEFAULT (0),
    -- Valori da RegistroCauzioniStatus dove CodSezione='PROROGHE'. NO FK applicata.
    -- 0=NON_AVVIATA, 310=IN_ISTRUTTORIA, 320=RICHIESTA_INVIATA, 330=IN_ATTESA_RINNOVO,
    -- 340=IN_RITARDO, 350=RINNOVO_RICEVUTO, 360=CONFERMATA, 370=RIFIUTATA, 380=ANNULLATA

    -- ---- Tipologia e dati della proroga ----
    [TipoProroga]                   [nvarchar](50)  NULL,  -- es: PROGETTO, POLIZZA, ENTRAMBI
    [DataProrogaProgetto]           [datetime2](7)  NULL,  -- nuova scadenza del progetto
    [ScadenzaPrecedente]            [datetime2](7)  NULL,  -- scadenza polizza prima della proroga
    [ScadenzaNuova]                 [datetime2](7)  NULL,  -- nuova scadenza polizza dopo proroga

    -- ---- Gestione temporale del ciclo ----
    [DataAvvio]                     [datetime2](7)  NULL,  -- data di avvio dell'istruttoria
    [DataScadenzaAttesa]            [datetime2](7)  NULL,  -- soglia IN_RITARDO (default: DataRichiestaFideiussore + 15gg)
    [DataCambioStatus]              [datetime2](7)  NULL,

    -- ---- Decreto di concessione proroga (interno) ----
    [ProtDecretoConcessione]        [nvarchar](30)  NULL,  -- protocollo decreto interno che autorizza la proroga
    [DataDecretoConcessione]        [datetime2](7)  NULL,

    -- ---- Comunicazione all'ente ----
    [ProtComunicazioneEnte]         [nvarchar](30)  NULL,  -- comunicazione all'organismo pagatore o ente di controllo
    [DataComunicazioneEnte]         [datetime2](7)  NULL,

    -- ---- Richiesta al fideiussore (da ProtComunicazioneProroga in GstCauzioni) ----
    [ProtRichiestaFideiussore]      [nvarchar](30)  NULL,
    [DataRichiestaFideiussore]      [datetime2](7)  NULL,

    -- ---- Ricezione del rinnovo dal fideiussore ----
    [ProtRicezioneRinnovo]          [nvarchar](30)  NULL,
    [DataRicezioneRinnovo]          [datetime2](7)  NULL,
    [FlagRinnovoAutomatico]         [bit]           NOT NULL CONSTRAINT [DF_RCProroghe_FlagRinnovoAutomatico] DEFAULT (0),
    -- 1 = il fideiussore ha rinnovato automaticamente senza richiesta formale

    -- ---- Esito ----
    [FlagConfermata]                [bit]           NOT NULL CONSTRAINT [DF_RCProroghe_FlagConfermata] DEFAULT (0),
    [MotivoRifiuto]                 [nvarchar](500) NULL,  -- valorizzato se Status=RIFIUTATA

    -- ---- Note e audit ----
    [Note]                          [nvarchar](1000) NULL,
    [DataInserimento]               [datetime2](7)  NOT NULL CONSTRAINT [DF_RCProroghe_DataInserimento] DEFAULT (SYSDATETIME()),
    [DataModifica]                  [datetime2](7)  NOT NULL CONSTRAINT [DF_RCProroghe_DataModifica] DEFAULT (SYSDATETIME()),
    [IDOperatore]                   [int]           NOT NULL,

 CONSTRAINT [PK_RegistroCauzioniProroghe] PRIMARY KEY CLUSTERED
(
    [ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80,
       OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],

 CONSTRAINT [UQ_RCProroghe_IDRegistroCauzioni_NumCiclo] UNIQUE NONCLUSTERED
(
    [IDRegistroCauzioni] ASC,
    [NumCiclo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
       ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- =============================================
-- FK verso RegistroCauzioni
-- =============================================
ALTER TABLE [dbo].[RegistroCauzioniProroghe] WITH CHECK ADD CONSTRAINT [FK_RCProroghe_RegistroCauzioni]
    FOREIGN KEY([IDRegistroCauzioni]) REFERENCES [dbo].[RegistroCauzioni] ([ID])
    ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[RegistroCauzioniProroghe] CHECK CONSTRAINT [FK_RCProroghe_RegistroCauzioni]
GO

-- =============================================
-- Indici
-- =============================================
CREATE NONCLUSTERED INDEX [IX_RCProroghe_Status]
    ON [dbo].[RegistroCauzioniProroghe] ([Status] ASC)
    INCLUDE ([IDRegistroCauzioni],[NumCiclo],[DataScadenzaAttesa],[ScadenzaNuova])
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, FILLFACTOR = 80,
          OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

-- =============================================
-- Extended Properties
-- =============================================
EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Tabella multi-ciclo della sezione Proroghe (nuova sezione TO BE 3.4.x). Ogni record rappresenta un ciclo di proroga/rinnovo per una cauzione. Parzialmente estratta da [dbo].[GstCauzioni] (ProtComunicazioneProroga, DataComunicazioneProroga, ScadenzaUltimoRinnovo, DataProrogaProgetto) e arricchita con nuovi campi. Status=0=NON_AVVIATA (default). NON ha FK verso RegistroCauzioniStatus: validazione applicativa.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniProroghe'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Stato del ciclo di proroga. Valori in RegistroCauzioniStatus con CodSezione=''PROROGHE''. DEFAULT=0=NON_AVVIATA. NON ha FK: validazione applicativa.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniProroghe',
    @level2type=N'COLUMN', @level2name=N'Status'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Data entro cui si attende risposta dal fideiussore. Se superata, il job notturno porta lo stato a IN_RITARDO. Default: DataRichiestaFideiussore + 15 giorni.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniProroghe',
    @level2type=N'COLUMN', @level2name=N'DataScadenzaAttesa'
GO

EXEC sys.sp_addextendedproperty
    @name=N'MS_Description',
    @value=N'Scadenza della polizza prima che questa proroga fosse approvata. Utile per storicizzare le scadenze successive.',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'RegistroCauzioniProroghe',
    @level2type=N'COLUMN', @level2name=N'ScadenzaPrecedente'
GO
